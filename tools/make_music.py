"""Oyunun arka plan müziklerini WAV dosyası olarak üretir.

Müzik kayıt değil, notalardan hesaplanır. Üretilen iki parça:
- menu.wav: kalimba ezgili, yaklaşık 23 sn'lik sakin menü döngüsü.
- game.wav: yaklaşık 6 dk'lık oyun müziği. İki tarzdan oluşur: "oyunbaz" (pizzicato akorlar,
  marimba/klarnet/piyano ezgileri; Fa, Si bemol, Do) ve "ada" (ukulele, kalimba/marimba/flüt
  ezgileri; Sol, Do, Re). Her tarzın üç bölümü vardır ve her bölüm ayrı tondadır. Her bölümde iki
  ezgi ve alttan yavaş ikinci bir ses çalar, her 8 ölçüde yumuşak bir tom geçişi gelir. Ritim
  yoğunluğu baştan sona aynıdır. Her bölümün son ölçüsü sıradaki bölümün tonuna götüren bir geçiş
  akorudur. İki tarzın birleştiği yerlerde yumuşak bir yaygı (pad) akoru geçişi bağlar.

Parçalar kusursuz döngüdür: nota ve yankı kuyrukları sondan başa sarar. Tizler alçak geçiren
süzgeçle kesilir; dosyalar küçük olsun diye tek kanal ve 16 kHz yazılır. Godot dosyaları QOA ile
sıkıştırır ve döngü olarak içe aktarır.

Gereksinim: numpy.
Kullanım: python tools/make_music.py assets/music
"""
import math
import os
import sys
import wave

import numpy as np

SAMPLE_RATE = 44100
OUTPUT_RATE = 16000
PEAK = 0.89
LOWPASS_HZ = 2600.0
MAX_SAMPLE = 32767
MAJOR = [0, 2, 4, 5, 7, 9, 11]
ROMAN = {'I': 0, 'ii': 1, 'iii': 2, 'IV': 3, 'V': 4, 'vi': 5}
BEATS_PER_BAR = 4
STRUM_GAP_SEC = 0.012
rng = np.random.default_rng(3)


# --- Temel hesaplar ---

def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def degree(step, tonic):
    """Majör dizideki derecenin MIDI notası (0 = tonun kendisi)."""
    return tonic + 12 * (step // 7) + MAJOR[step % 7]


def chord(name, tonic):
    root = ROMAN[name]
    return [degree(root + step, tonic) for step in (0, 2, 4)]


def voiced(notes, low):
    """Akoru kökü low ile low+11 arasında olacak biçimde oktav kaydırır."""
    shift = 12 * math.floor((low - notes[0]) / 12)
    if notes[0] + shift < low:
        shift += 12
    return [n + shift for n in notes]


def times(dur):
    return np.arange(int(dur * SAMPLE_RATE)) / SAMPLE_RATE


def decay_env(dur, attack, tau):
    t = times(dur)
    return np.minimum(t / attack, 1.0) * np.exp(-t / tau)


def hold_env(dur, attack, release):
    t = times(dur)
    return np.minimum(t / attack, 1.0) * np.clip((dur - t) / release, 0.0, 1.0)


def sine(f, t):
    return np.sin(2 * math.pi * f * t)


def noise(dur):
    return rng.uniform(-1, 1, int(dur * SAMPLE_RATE))


def sweep(t, low, high, tau):
    """Frekansı high'tan low'a üstel inen sinüs (davul gövdesi)."""
    freq = low + (high - low) * np.exp(-t / tau)
    return np.sin(2 * math.pi * np.cumsum(freq) / SAMPLE_RATE)


# --- Çalgılar: (frekans, süre) alır, tek kanallı dizi döner ---

def kalimba(f, dur):
    dur = max(dur, 1.2)
    t = times(dur)
    tone = sine(f, t) + 0.3 * sine(f * 5.95, t) * np.exp(-t / 0.04) + 0.12 * sine(f * 2, t)
    return tone * decay_env(dur, 0.003, 0.5)


def soft_kalimba(f, dur):
    dur = max(dur, 1.6)
    t = times(dur)
    tone = sine(f, t) + 0.08 * sine(f * 2, t) + 0.1 * sine(f * 5.95, t) * np.exp(-t / 0.02)
    return tone * decay_env(dur, 0.006, 0.7)


def marimba(f, dur):
    dur = max(dur, 1.0)
    t = times(dur)
    tone = sine(f, t) + 0.35 * sine(f * 4, t) * np.exp(-t / 0.07)
    tone += 0.1 * sine(f * 9.9, t) * np.exp(-t / 0.015)
    return tone * decay_env(dur, 0.002, 0.35)


def felt_piano(f, dur):
    dur = max(dur, 1.6)
    t = times(dur)
    tone = sum(sine(f * n, t) * np.exp(-t * n / 1.2) / (n * n) for n in range(1, 6))
    return tone * decay_env(dur, 0.01, 0.9)


def pluck(f, dur):
    """Karplus-Strong telli çalgı sesi."""
    n = int(dur * SAMPLE_RATE)
    period = max(2, int(round(SAMPLE_RATE / f)))
    buf = rng.uniform(-1, 1, period)
    out = np.empty(n)
    filled = 0
    while filled < n:
        take = min(period, n - filled)
        out[filled:filled + take] = buf[:take]
        buf = 0.996 * 0.5 * (buf + np.roll(buf, -1))
        filled += take
    return out * decay_env(dur, 0.002, 0.6)


def pizz(f, _dur):
    return pluck(f, 0.9) * np.exp(-times(0.9) / 0.16)


def ukulele(f, _dur):
    return pluck(f, 0.9) * np.exp(-times(0.9) / 0.35)


def wind(f, dur, vibrato_depth, vibrato_rise, harmonics, attack):
    t = times(dur + 0.1)
    vibrato = 1 + vibrato_depth * sine(5.0, t) * np.minimum(t / vibrato_rise, 1.0)
    phase = 2 * math.pi * f * np.cumsum(vibrato) / SAMPLE_RATE
    tone = sum(amp * np.sin(n * phase) for n, amp in harmonics)
    return tone * hold_env(dur + 0.1, attack, 0.18)


def flute(f, dur):
    return wind(f, dur, 0.004, 0.4, ((1, 1.0), (2, 0.15), (3, 0.05)), 0.08)


def clarinet(f, dur):
    return wind(f, dur, 0.003, 0.5, ((1, 1.0), (2, 0.05), (3, 0.3), (5, 0.1)), 0.04)


def pad(f, dur):
    t = times(dur + 0.8)
    tone = np.zeros_like(t)
    for detune in (-0.004, 0.0, 0.004):
        for n, amp in ((1, 1.0), (2, 0.35), (3, 0.15), (4, 0.06)):
            tone += amp * sine(f * n * (1 + detune), t)
    return tone / 4 * hold_env(dur + 0.8, 0.6, 1.0)


def warm_pad(f, dur):
    t = times(dur + 2.0)
    tone = np.zeros_like(t)
    for detune in (-0.003, 0.0, 0.003):
        tone += sine(f * (1 + detune), t) + 0.2 * sine(f * 2 * (1 + detune), t)
    return tone / 3 * hold_env(dur + 2.0, 1.2, 2.0)


def bass(f, dur):
    t = times(dur)
    tone = sine(f, t) + 0.25 * sine(f * 2, t)
    return tone * hold_env(dur, 0.01, min(0.08, dur * 0.4)) * np.exp(-t / 1.2)


def bouncy_bass(f, dur):
    t = times(dur)
    tone = sine(f, t) + 0.3 * sine(f * 2, t) + 0.12 * sine(f * 3, t)
    return tone * hold_env(dur, 0.01, min(0.06, dur * 0.4)) * np.exp(-t / 0.35)


# --- Vurmalılar: argümansız çağrılır ---

def kick():
    t = times(0.35)
    return sweep(t, 45, 155, 0.04) * np.exp(-t / 0.12)


def tom():
    t = times(0.35)
    return sweep(t, 95, 150, 0.05) * np.exp(-t / 0.16)


def soft_snare():
    t = times(0.3)
    return noise(0.3) * 0.35 * np.exp(-t / 0.08) + 0.6 * sine(170, t) * np.exp(-t / 0.05)


def rim():
    t = times(0.06)
    return (0.6 * sine(820, t) + 0.3 * noise(0.06)) * np.exp(-t / 0.009)


def clap():
    t = times(0.2)
    env = np.exp(-t / 0.05)
    for k in (0.0, 0.011, 0.022):
        env = env + 0.6 * np.exp(-np.abs(t - k) / 0.003)
    return noise(0.2) * env * 0.25


def shaker():
    t = times(0.09)
    return np.diff(noise(0.09), prepend=0) * 0.25 * np.minimum(t / 0.015, 1) * np.exp(-t / 0.03)


# --- Karıştırma ---

class Mix:
    """Dairesel stereo tampon: parçanın sonunu aşan sesler başa sarar, döngü kusursuz olur."""

    def __init__(self, seconds):
        self.n = int(seconds * SAMPLE_RATE)
        self.buf = np.zeros((2, self.n))

    def add(self, sig, start, gain, pan):
        theta = (pan + 1) * math.pi / 4
        idx = (int(start * SAMPLE_RATE) + np.arange(len(sig))) % self.n
        np.add.at(self.buf[0], idx, sig * gain * math.cos(theta))
        np.add.at(self.buf[1], idx, sig * gain * math.sin(theta))

    def reverb(self, amount):
        soft = np.array([np.convolve(ch, np.ones(12) / 12, mode='same') for ch in self.buf])
        taps = ((0.09, 0.32), (0.17, 0.25), (0.29, 0.18), (0.43, 0.12), (0.61, 0.08), (0.83, 0.05))
        for i, (delay, gain) in enumerate(taps):
            side = soft[::-1] if i % 2 else soft
            self.buf += amount * gain * np.roll(side, int(delay * SAMPLE_RATE), axis=1)

    def write(self, path):
        """Tek kanala indirir, tizleri keser, OUTPUT_RATE'e örnekler ve WAV yazar. Süzgeç ve
        örnekleme FFT ile dairesel yapılır; döngünün ek yeri bozulmaz."""
        spec = np.fft.rfft(self.buf.mean(axis=0))
        freqs = np.fft.rfftfreq(self.n, 1 / SAMPLE_RATE)
        spec *= 1 / np.sqrt(1 + (freqs / LOWPASS_HZ) ** 4)
        frames = int(round(self.n * OUTPUT_RATE / SAMPLE_RATE))
        out = np.fft.irfft(spec[:frames // 2 + 1], n=frames) * frames / self.n
        out = out / np.max(np.abs(out)) * PEAK
        with wave.open(path, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(OUTPUT_RATE)
            w.writeframes((out * MAX_SAMPLE).astype('<i2').tobytes())


class Track:
    """Ölçü ve vuruş cinsinden zamanlama. swing, ara sekizlikleri geciktirir (vuruş cinsinden)."""

    def __init__(self, bpm, bars):
        self.beat = 60.0 / bpm
        self.swing = 0.0
        self.mix = Mix(bars * BEATS_PER_BAR * self.beat)

    def at(self, bar, beat):
        if beat % 1 == 0.5:
            beat += self.swing
        return (bar * BEATS_PER_BAR + beat) * self.beat

    def note(self, inst, midi, bar, beat, beats, gain, pan=0.0, delay=0.0):
        sig = inst(hz(midi), beats * self.beat)
        self.mix.add(sig, self.at(bar, beat) + delay, gain, pan)

    def hit(self, inst, bar, beat, gain, pan=0.0):
        self.mix.add(inst(), self.at(bar, beat), gain, pan)

    def strum(self, inst, notes, bar, beat, gain, up=False):
        order = list(reversed(notes)) if up else notes
        for i, m in enumerate(order):
            pan = (notes.index(m) / (len(notes) - 1) - 0.5) * 0.6
            self.note(inst, m, bar, beat, 0.5, gain, pan, i * STRUM_GAP_SEC)

    def chord_pad(self, inst, notes, bar, gain):
        for j, m in enumerate(notes):
            self.note(inst, m, bar, 0, BEATS_PER_BAR, gain, (j - 1) * 0.4)


# --- Menü döngüsü (Do majör, 84 BPM, 8 ölçü) ---

MENU_BPM = 84
MENU_TONIC = 60
MENU_CHORDS = ['I', 'V', 'vi', 'IV', 'I', 'V', 'IV', 'V']
MENU_ARP = [0, 1, 2, 3, 2, 1, 2, 1]
MENU_MELODY = [
    [(0, 4, 1.5), (1.5, 2, 0.5), (2, 4, 2)],
    [(0, 4, 1), (1, 3, 1), (2, 1, 2)],
    [(0, 2, 1.5), (1.5, 0, 0.5), (2, 2, 2)],
    [(0, 3, 1), (1, 2, 1), (2, 0, 2)],
    [(0, 4, 1.5), (1.5, 5, 0.5), (2, 4, 2)],
    [(0, 6, 1), (1, 4, 1), (2, 1, 2)],
    [(0, 5, 1), (1, 3, 1), (2, 2, 1), (3, 0, 1)],
    [(0, 1, 3)],
]


def menu(path):
    s = Track(MENU_BPM, len(MENU_CHORDS))
    for bar, name in enumerate(MENU_CHORDS):
        tones = chord(name, MENU_TONIC)
        s.chord_pad(pad, [m - 12 for m in tones], bar, 0.18)
        arp = tones + [tones[0] + 12]
        for k, index in enumerate(MENU_ARP):
            s.note(kalimba, arp[index], bar, k * 0.5, 0.5, 0.22, -0.3)
        s.note(bass, tones[0] - 24, bar, 0, BEATS_PER_BAR, 0.35)
        for beat, step, beats in MENU_MELODY[bar]:
            s.note(kalimba, degree(step, MENU_TONIC) + 12, bar, beat, beats, 0.4, 0.25)
    s.mix.reverb(0.6)
    s.mix.write(path)


# --- Oyun müziği: bölümler ---

GAME_BPM = 116
SECTION_BARS = 28
CHORD_CYCLE = 4
INTRO_BARS = 4
PHRASE_BARS = 8
BRIDGE_BAR = SECTION_BARS - 1
COUNTER_GAIN = 0.13
JOIN_PAD_GAIN = 0.1
JOIN_PAD_LOW = 48


class Section:
    """Bir bölüm (28 ölçü): 0-3 giriş, 4-11 birinci ezgi, 12-19 ikinci ezgi, 20-27 birinci ezgi
    başka çalgıda ve armoniyle. Son ölçü sıradaki tona götüren geçiş akorudur."""

    def __init__(self, track, index, spec):
        self.s = track
        self.first = index * SECTION_BARS
        self.spec = spec
        self.tonic = spec['tonic']
        cycle = [chord(name, self.tonic) for name in spec['chords']]
        self.chords = [cycle[i % CHORD_CYCLE] for i in range(BRIDGE_BAR)] + [spec['bridge']]

    def bar(self, local):
        return self.first + local

    def root(self, local):
        return voiced(self.chords[local], 36)[0]

    def phrase(self, inst, lines, start, gain, octave, harmony=False, ending=None):
        for i, notes in enumerate(lines):
            if ending is not None and i == len(lines) - 1:
                notes = [(0, ending, BEATS_PER_BAR)]
            for beat, step, beats in notes:
                midi = degree(step, self.tonic) + 12 * octave
                self.s.note(inst, midi, self.bar(start + i), beat, beats, gain, 0.2)
                if harmony:
                    low = degree(step - 2, self.tonic) + 12 * octave
                    self.s.note(inst, low, self.bar(start + i), beat, beats, gain * 0.35, -0.2)

    def counter(self, inst, bars, low):
        """Akor seslerinden bir öncekine en yakın olanı yarım notalarla çalan alttan ikinci ses."""
        prev = low + 6
        for local in bars:
            tones = voiced(self.chords[local], low)
            candidates = tones[1:] + [tones[0] + 12]
            for beat in (0, 2):
                prev = min(candidates, key=lambda m, p=prev: abs(m - p))
                self.s.note(inst, prev, self.bar(local), beat, 2, COUNTER_GAIN, -0.35)

    def fills(self, gain):
        for local in range(PHRASE_BARS - 1, SECTION_BARS, PHRASE_BARS):
            for k, beat in enumerate((3, 3 + 1 / 3, 3 + 2 / 3)):
                self.s.hit(tom, self.bar(local), beat, gain * (0.7 + 0.1 * k), 0.2 - 0.2 * k)
        for k, beat in enumerate((2, 2.5, 3, 3.5)):
            self.s.hit(tom, self.bar(BRIDGE_BAR), beat, gain * (0.6 + 0.1 * k), 0.3 - 0.2 * k)

    def melodies(self, voices, gain, counter_inst, counter_low):
        main, alt, octave = voices
        first, second = self.spec['phrases']
        start_b = INTRO_BARS + PHRASE_BARS
        start_c = start_b + PHRASE_BARS
        self.phrase(main, first, INTRO_BARS, gain, octave)
        self.phrase(main, second, start_b, gain, octave)
        self.phrase(alt, first, start_c, gain, octave, harmony=True, ending=self.spec['ending'])
        self.counter(counter_inst, list(range(INTRO_BARS)) + list(range(start_b, SECTION_BARS)),
                     counter_low)


def bars(*rows):
    return [list(r) for r in rows]


# --- Oyunbaz: Fa -> Si bemol -> Do -> (Sol'e geçiş) ---
# Ezgi notaları: (vuruş, derece, süre).

PLAY_SPECS = [
    {
        'tonic': 53, 'chords': ['I', 'vi', 'ii', 'V'], 'bridge': [53, 57, 60, 63], 'ending': 0,
        'phrases': (bars(
            [(0, 4, 0.5), (1, 4, 0.5), (1.5, 5, 0.5), (2, 4, 0.5), (3, 2, 0.5)],
            [(0, 3, 0.5), (0.5, 2, 0.5), (1, 1, 1), (2, 5, 0.5), (3, 4, 0.5)],
            [(0, 1, 0.5), (1, 1, 0.5), (1.5, 2, 0.5), (2, 3, 0.5), (3, 5, 0.5)],
            [(0, 4, 0.5), (0.5, 3, 0.5), (1, 2, 0.5), (1.5, 1, 0.5), (2, 0, 1)],
            [(0, 7, 0.5), (1, 7, 0.5), (1.5, 6, 0.5), (2, 5, 0.5), (3, 4, 0.5)],
            [(0, 5, 0.5), (0.5, 4, 0.5), (1, 2, 1), (2, 0, 0.5), (3, 2, 0.5)],
            [(0, 1, 0.5), (0.5, 3, 0.5), (1, 5, 0.5), (2, 4, 0.5), (2.5, 3, 0.5), (3, 1, 0.5)],
            [(0, 4, 1), (2, 1, 0.5), (3, 6, 0.5)],
        ), bars(
            [(0, 0, 0.5), (0.5, 2, 0.5), (1, 4, 0.5), (2, 7, 1), (3, 4, 0.5)],
            [(0, 5, 0.5), (1, 5, 0.5), (1.5, 4, 0.5), (2, 2, 1), (3, 0, 0.5)],
            [(0, 1, 0.5), (0.5, 3, 0.5), (1, 5, 1), (2, 3, 0.5), (2.5, 1, 0.5), (3, 3, 0.5)],
            [(0, 4, 1), (1, 6, 0.5), (2, 4, 0.5), (3, 1, 0.5)],
            [(0, 7, 0.5), (0.5, 6, 0.5), (1, 4, 0.5), (2, 2, 0.5), (2.5, 4, 0.5), (3, 0, 1)],
            [(0, 2, 1), (1, 5, 0.5), (2, 4, 0.5), (3, 2, 0.5)],
            [(0, 3, 0.5), (1, 1, 0.5), (1.5, 3, 0.5), (2, 5, 0.5), (3, 4, 0.5)],
            [(0, 6, 1), (2, 4, 1)],
        )),
    },
    {
        'tonic': 58, 'chords': ['I', 'vi', 'ii', 'V'], 'bridge': [55, 59, 62, 65], 'ending': 2,
        'phrases': (bars(
            [(0, 4, 1.5), (1.5, 2, 0.5), (2, 0, 2)],
            [(0, 5, 1), (1, 4, 1), (2, 2, 2)],
            [(0, 3, 1), (1, 5, 1), (2, 6, 1), (3, 5, 1)],
            [(0, 4, 3), (3, 6, 0.5), (3.5, 7, 0.5)],
            [(0, 9, 1.5), (1.5, 7, 0.5), (2, 4, 2)],
            [(0, 7, 1), (1, 5, 1), (2, 4, 1), (3, 2, 1)],
            [(0, 1, 1), (1, 3, 1), (2, 5, 1), (3, 3, 1)],
            [(0, 4, 2), (2, 1, 2)],
        ), bars(
            [(0, 2, 0.5), (0.5, 4, 0.5), (1, 7, 0.5), (2, 4, 0.5), (3, 2, 0.5)],
            [(0, 0, 0.5), (0.5, 2, 0.5), (1, 5, 1), (2, 4, 0.5), (3, 2, 0.5)],
            [(0, 1, 0.5), (0.5, 3, 0.5), (1, 5, 0.5), (2, 8, 1), (3, 5, 0.5)],
            [(0, 4, 1), (1, 1, 0.5), (1.5, 4, 0.5), (2, 6, 1)],
            [(0, 7, 0.5), (1, 7, 0.5), (1.5, 9, 0.5), (2, 7, 0.5), (3, 4, 0.5)],
            [(0, 5, 0.5), (0.5, 4, 0.5), (1, 2, 1), (2, 0, 1)],
            [(0, 3, 0.5), (0.5, 1, 0.5), (1, 3, 0.5), (1.5, 5, 0.5), (2, 4, 1)],
            [(0, 1, 1), (2, 4, 1)],
        )),
    },
    {
        'tonic': 60, 'chords': ['I', 'vi', 'ii', 'V'], 'bridge': [50, 54, 57, 60], 'ending': 0,
        'phrases': (bars(
            [(0, 4, 0.5), (0.5, 5, 0.5), (1, 4, 0.5), (1.5, 2, 0.5), (2, 0, 1), (3, 2, 0.5)],
            [(0, 5, 1), (1, 7, 0.5), (1.5, 5, 0.5), (2, 4, 1)],
            [(0, 3, 0.5), (0.5, 5, 0.5), (1, 8, 1), (2, 5, 0.5), (3, 3, 0.5)],
            [(0, 4, 1.5), (1.5, 6, 0.5), (2, 8, 1), (3, 6, 0.5)],
            [(0, 7, 1), (1, 4, 1), (2, 2, 0.5), (2.5, 4, 0.5), (3, 7, 0.5)],
            [(0, 9, 1), (1, 7, 0.5), (1.5, 5, 0.5), (2, 2, 1)],
            [(0, 1, 0.5), (0.5, 3, 0.5), (1, 5, 0.5), (2, 3, 0.5), (2.5, 1, 0.5), (3, -1, 0.5)],
            [(0, 1, 2), (2, 4, 1)],
        ), bars(
            [(0, 7, 0.5), (1, 7, 0.5), (1.5, 4, 0.5), (2, 2, 0.5), (3, 4, 0.5)],
            [(0, 2, 0.5), (0.5, 0, 0.5), (1, 2, 1), (2, 5, 1)],
            [(0, 3, 1), (1, 1, 0.5), (1.5, 3, 0.5), (2, 5, 0.5), (3, 8, 0.5)],
            [(0, 6, 1), (1, 4, 1), (2, 1, 1)],
            [(0, 0, 0.5), (0.5, 2, 0.5), (1, 4, 0.5), (1.5, 7, 0.5), (2, 9, 1), (3, 7, 0.5)],
            [(0, 5, 1), (1, 4, 0.5), (2, 2, 0.5), (3, 0, 0.5)],
            [(0, 1, 0.5), (0.5, 3, 0.5), (1, 5, 1), (2, 4, 0.5), (2.5, 3, 0.5), (3, 1, 0.5)],
            [(0, 4, 2)],
        )),
    },
]
# Her bölümün (ana çalgı, son tekrardaki çalgı, oktav) üçlüsü.
PLAY_VOICES = [(marimba, felt_piano, 1), (clarinet, marimba, 0), (felt_piano, clarinet, 0)]


def playful_groove(sec, index):
    s = sec.s
    for local in range(SECTION_BARS):
        b = sec.bar(local)
        for beat, offset in ((0, 0), (2, 7)):
            s.note(bouncy_bass, sec.root(local) + offset, b, beat, 0.9, 0.55)
        for beat in (1, 3):
            s.strum(pizz, voiced(sec.chords[local], 48), b, beat, 0.17)
        for beat in (0, 2):
            s.hit(kick, b, beat, 0.3)
        for beat in (1, 3):
            s.hit(soft_snare, b, beat, 0.1, -0.1)
        if index == 1:
            for k in range(8):
                s.hit(shaker, b, k * 0.5, 0.08 if k % 2 else 0.04, 0.4)
        else:
            s.hit(rim, b, 3.5, 0.08, 0.3)


def playful(track, first_index):
    track.swing = 0.0
    for index, spec in enumerate(PLAY_SPECS):
        sec = Section(track, first_index + index, spec)
        playful_groove(sec, index)
        sec.melodies(PLAY_VOICES[index], 0.36, clarinet, 50)
        sec.fills(0.22)


# --- Ada: Sol -> Do -> Re -> (Fa'ya geçiş) ---

ISLAND_SWING = 0.05
ISLAND_SPECS = [
    {
        'tonic': 55, 'chords': ['I', 'V', 'vi', 'IV'], 'bridge': [55, 59, 62, 65], 'ending': 0,
        'phrases': (bars(
            [(0, 4, 1), (1, 4, 0.5), (1.5, 2, 0.5), (2, 4, 1), (3, 7, 1)],
            [(0, 6, 1.5), (1.5, 5, 0.5), (2, 4, 2)],
            [(0, 5, 0.5), (0.5, 4, 0.5), (1, 2, 1), (2, 4, 1), (3, 5, 1)],
            [(0, 3, 2), (2, 2, 1), (3, 0, 1)],
            [(0, 2, 0.5), (0.5, 4, 0.5), (1, 7, 1), (2, 7, 0.5), (2.5, 6, 0.5), (3, 7, 1)],
            [(0, 8, 1), (1, 6, 1), (2, 4, 2)],
            [(0, 5, 1), (1, 4, 0.5), (1.5, 2, 0.5), (2, 4, 1), (3, 2, 1)],
            [(0, 1, 2), (2, 3, 2)],
        ), bars(
            [(0, 7, 0.5), (0.5, 6, 0.5), (1, 4, 1), (2, 2, 0.5), (2.5, 4, 0.5), (3, 0, 1)],
            [(0, 1, 1), (1, 4, 0.5), (1.5, 6, 0.5), (2, 8, 1), (3, 6, 1)],
            [(0, 5, 1.5), (1.5, 4, 0.5), (2, 2, 1), (3, 4, 1)],
            [(0, 3, 1), (1, 5, 0.5), (1.5, 7, 0.5), (2, 7, 1), (3, 5, 1)],
            [(0, 4, 0.5), (0.5, 2, 0.5), (1, 4, 1), (2, 7, 1), (3, 4, 1)],
            [(0, 6, 0.5), (0.5, 5, 0.5), (1, 4, 1), (2, 1, 2)],
            [(0, 2, 1), (1, 4, 1), (2, 5, 0.5), (2.5, 4, 0.5), (3, 2, 1)],
            [(0, 3, 2), (2, 1, 2)],
        )),
    },
    {
        'tonic': 60, 'chords': ['I', 'V', 'vi', 'IV'], 'bridge': [57, 61, 64, 67], 'ending': 2,
        'phrases': (bars(
            [(0, 2, 1), (1, 4, 0.5), (1.5, 2, 0.5), (2, 0, 1), (3, 2, 1)],
            [(0, 1, 1.5), (1.5, 4, 0.5), (2, 6, 2)],
            [(0, 5, 1), (1, 4, 0.5), (1.5, 2, 0.5), (2, 0, 1), (3, 2, 1)],
            [(0, 3, 3), (3, 4, 1)],
            [(0, 7, 1), (1, 6, 0.5), (1.5, 4, 0.5), (2, 4, 1), (3, 2, 1)],
            [(0, 4, 1.5), (1.5, 6, 0.5), (2, 8, 1), (3, 6, 1)],
            [(0, 7, 1), (1, 5, 1), (2, 4, 1), (3, 2, 1)],
            [(0, 3, 2), (2, 5, 2)],
        ), bars(
            [(0, 4, 0.5), (0.5, 4, 0.5), (1, 7, 1), (2, 4, 0.5), (2.5, 2, 0.5), (3, 0, 1)],
            [(0, 4, 0.5), (0.5, 1, 0.5), (1, 4, 1), (2, 6, 1), (3, 4, 1)],
            [(0, 5, 0.5), (0.5, 7, 0.5), (1, 9, 1), (2, 7, 1), (3, 5, 1)],
            [(0, 7, 1.5), (1.5, 5, 0.5), (2, 3, 2)],
            [(0, 2, 0.5), (0.5, 4, 0.5), (1, 7, 0.5), (1.5, 4, 0.5), (2, 2, 1), (3, 4, 1)],
            [(0, 6, 1), (1, 4, 1), (2, 1, 1), (3, 4, 1)],
            [(0, 2, 1), (1, 0, 1), (2, 2, 0.5), (2.5, 4, 0.5), (3, 5, 1)],
            [(0, 3, 2), (2, 0, 2)],
        )),
    },
    {
        'tonic': 62, 'chords': ['I', 'V', 'vi', 'IV'], 'bridge': [48, 52, 55, 58], 'ending': 3,
        'phrases': (bars(
            [(0, 0, 1), (1, 2, 1), (2, 4, 1.5), (3.5, 2, 0.5)],
            [(0, 1, 1), (1, 4, 1), (2, 6, 2)],
            [(0, 5, 1.5), (1.5, 4, 0.5), (2, 2, 1), (3, 4, 1)],
            [(0, 3, 3), (3, 2, 1)],
            [(0, 4, 1), (1, 7, 1), (2, 6, 1), (3, 4, 1)],
            [(0, 6, 1.5), (1.5, 4, 0.5), (2, 1, 2)],
            [(0, 2, 1), (1, 4, 1), (2, 5, 1), (3, 4, 1)],
            [(0, 3, 2), (2, 1, 2)],
        ), bars(
            [(0, 7, 0.5), (0.5, 6, 0.5), (1, 4, 1), (2, 2, 1), (3, 4, 1)],
            [(0, 4, 1), (1, 1, 0.5), (1.5, 4, 0.5), (2, 6, 1), (3, 8, 1)],
            [(0, 7, 1.5), (1.5, 5, 0.5), (2, 4, 1), (3, 2, 1)],
            [(0, 3, 1), (1, 5, 1), (2, 7, 2)],
            [(0, 9, 1), (1, 7, 1), (2, 4, 1), (3, 7, 1)],
            [(0, 8, 1), (1, 6, 1), (2, 4, 1), (3, 1, 1)],
            [(0, 2, 0.5), (0.5, 4, 0.5), (1, 5, 1), (2, 4, 1), (3, 2, 1)],
            [(0, 0, 2), (2, 1, 2)],
        )),
    },
]
ISLAND_VOICES = [(soft_kalimba, marimba, 1), (marimba, soft_kalimba, 0), (flute, soft_kalimba, 0)]
# Ukulele vuruşları: (vuruş, yukarı mı, şiddet).
ISLAND_STRUM = ((0, False, 1.0), (1, False, 0.7), (1.5, True, 0.5), (2.5, True, 0.5),
                (3, False, 0.7), (3.5, True, 0.5))
# Do bölümünde ara vuruşlara düşen kesik çalış.
ISLAND_CHOP = ((0.5, True, 0.6), (1.5, True, 0.6), (2.5, True, 0.6), (3.5, True, 0.6),
               (0, False, 0.9), (2, False, 0.7))


def island_groove(sec, index):
    s = sec.s
    strums = ISLAND_CHOP if index == 1 else ISLAND_STRUM
    for local in range(SECTION_BARS):
        b = sec.bar(local)
        notes = voiced(sec.chords[local], 55)
        for beat, up, level in strums:
            s.strum(ukulele, notes + [notes[0] + 12], b, beat, 0.1 * level, up)
        for beat, beats, offset in ((0, 1, 0), (1.5, 0.5, 0), (2, 1, 7), (3, 1, 12)):
            s.note(bouncy_bass, sec.root(local) + offset, b, beat, beats, 0.5)
        for beat in (0, 2.5):
            s.hit(kick, b, beat, 0.35)
        for beat in (1, 3):
            if index == 2:
                s.hit(clap, b, beat, 0.2, -0.2)
            else:
                s.hit(rim, b, beat, 0.1, -0.2)
        for k in range(8):
            s.hit(shaker, b, k * 0.5, 0.1 if k % 2 else 0.05, 0.4)


def island(track, first_index):
    track.swing = ISLAND_SWING
    for index, spec in enumerate(ISLAND_SPECS):
        sec = Section(track, first_index + index, spec)
        island_groove(sec, index)
        sec.melodies(ISLAND_VOICES[index], 0.4, felt_piano, 52)
        sec.fills(0.2)


def join(track, bridge_bar, bridge, next_tonic):
    """İki tarzın birleştiği yerde geçiş akorundan yeni tona uzanan yumuşak yaygı."""
    track.chord_pad(warm_pad, voiced(bridge, JOIN_PAD_LOW), bridge_bar, JOIN_PAD_GAIN)
    tonic_chord = voiced(chord('I', next_tonic), JOIN_PAD_LOW)
    for k in (1, 2):
        track.chord_pad(warm_pad, tonic_chord, bridge_bar + k, JOIN_PAD_GAIN * (1.5 - 0.5 * k))


def game(path):
    specs = PLAY_SPECS + ISLAND_SPECS
    track = Track(GAME_BPM, SECTION_BARS * len(specs))
    playful(track, 0)
    island(track, len(PLAY_SPECS))
    for last in (len(PLAY_SPECS) - 1, len(specs) - 1):
        following = specs[(last + 1) % len(specs)]
        join(track, (last + 1) * SECTION_BARS - 1, specs[last]['bridge'], following['tonic'])
    track.mix.reverb(0.4)
    track.mix.write(path)


def main():
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    menu(os.path.join(out, 'menu.wav'))
    game(os.path.join(out, 'game.wav'))


if __name__ == '__main__':
    main()
