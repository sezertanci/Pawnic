"""Oyunun ses efektlerini WAV dosyası olarak üretir (RobiCodes projesindeki make_sounds.py yöntemiyle).

Sesler kayıt değil, notalardan hesaplanır: kısa yükseliş ve üstel sönme zarfı. Tuş ve adım sesleri
RobiCodes'taki notalarla aynıdır. Işınlanma sesi tonu yükselen, titreşimli bir süpürmedir.
Kart çekme sesi, yavaşça kabarıp sönen boğuk bir fışırtıdır (süzülmüş gürültü).
Karıştırma sesi, kartların art arda birbirine çarptığı hızlı bir tıkırtı dizisidir ("brrrt").
Yalnızca Python'un standart kütüphanesi gerekir.

Kullanım: python tools/make_sounds.py assets/sounds
"""
import math
import random
import os
import struct
import sys
import wave

SAMPLE_RATE = 44100
VOLUME = 0.18
ATTACK_SECONDS = 0.02
SILENT_GAIN = 0.0001        # Üstel azalma sıfıra inemez; duyulmayacak kadar küçük bir değer.
MAX_SAMPLE = 32767

# Her nota: (frekans Hz, başlangıç sn, süre sn).
MELODIES = {
    'tap': [(1047, 0, 0.06)],
    'step': [(392, 0, 0.08)],
    'tick': [(1760, 0, 0.05)],
}

# Işınlanma: frekans başlangıçtan bitişe üstel olarak yükselir, üstüne hızlı bir titreşim biner.
TELEPORT_START_HZ = 300
TELEPORT_END_HZ = 1500
TELEPORT_SECONDS = 1.8        # tuning.json içindeki slide_sec ile aynı: kayma boyunca çalar.
TELEPORT_WOBBLE_HZ = 30
TELEPORT_WOBBLE_DEPTH = 0.08

# Kart çekme: iki kez süzülen gürültü. Ses ani başlamasın diye zarf sin² biçiminde kabarıp söner
# (çıt sesi olmaz); süzgeç ortada biraz açılıp yine kapanır ("fışşırt").
DRAW_SECONDS = 0.28
DRAW_SMOOTH_EDGE = 0.04     # Tek kutuplu süzgeç katsayısı: küçük değer daha boğuk ses.
DRAW_SMOOTH_PEAK = 0.12
DRAW_VOLUME = 0.6           # Süzülen gürültünün tepe genliği (tam ölçeğe oranla).
DRAW_SEED = 7               # Her üretimde aynı ses çıksın.

# Karıştırma: kısa gürültü vuruşları eşit aralıklarla dizilir; her vuruş hızla söner. Dizinin sonuna
# doğru vuruşlar hafifler (kartlar desteye oturur). Süre tuning.json'daki karıştırma animasyonuna
# yakındır.
SHUFFLE_TAPS = 14
SHUFFLE_SPACING = 0.045      # Vuruşlar arası saniye.
SHUFFLE_TAP_SECONDS = 0.035
SHUFFLE_SMOOTH = 0.35        # Çekme sesinden daha açık süzgeç: daha parlak tıkırtı.
SHUFFLE_TAIL_GAIN = 0.4      # Son vuruşun ilk vuruşa oranla genliği.
SHUFFLE_VOLUME = 0.7
SHUFFLE_SEED = 11


def sine(phase):
    return math.sin(2 * math.pi * phase)


def gain_at(t, duration):
    """İki üstel rampa: 0'dan VOLUME'a yükseliş, sonra SILENT_GAIN'e sönme."""
    if t < ATTACK_SECONDS:
        return SILENT_GAIN * (VOLUME / SILENT_GAIN) ** (t / ATTACK_SECONDS)
    fade = (t - ATTACK_SECONDS) / (duration - ATTACK_SECONDS)
    return VOLUME * (SILENT_GAIN / VOLUME) ** fade


def render(notes):
    length = max(start + duration for _, start, duration in notes)
    samples = [0.0] * math.ceil(length * SAMPLE_RATE)
    for frequency, start, duration in notes:
        first = round(start * SAMPLE_RATE)
        for i in range(round(duration * SAMPLE_RATE)):
            t = i / SAMPLE_RATE
            samples[first + i] += sine(frequency * t) * gain_at(t, duration)
    return samples


def render_teleport():
    samples = []
    phase = 0.0
    ratio = TELEPORT_END_HZ / TELEPORT_START_HZ
    for i in range(round(TELEPORT_SECONDS * SAMPLE_RATE)):
        t = i / SAMPLE_RATE
        wobble = 1 + TELEPORT_WOBBLE_DEPTH * sine(TELEPORT_WOBBLE_HZ * t)
        frequency = TELEPORT_START_HZ * ratio ** (t / TELEPORT_SECONDS) * wobble
        phase += frequency / SAMPLE_RATE
        samples.append(sine(phase) * gain_at(t, TELEPORT_SECONDS))
    return samples


def render_draw():
    rng = random.Random(DRAW_SEED)
    samples = []
    first = second = 0.0
    for i in range(round(DRAW_SECONDS * SAMPLE_RATE)):
        swell = math.sin(math.pi * i / (DRAW_SECONDS * SAMPLE_RATE)) ** 2
        smooth = DRAW_SMOOTH_EDGE + (DRAW_SMOOTH_PEAK - DRAW_SMOOTH_EDGE) * swell
        first += smooth * (rng.uniform(-1, 1) - first)
        second += smooth * (first - second)
        samples.append(second * swell)
    peak = max(abs(s) for s in samples)
    return [s / peak * DRAW_VOLUME * VOLUME for s in samples]


def render_shuffle():
    rng = random.Random(SHUFFLE_SEED)
    tap_length = round(SHUFFLE_TAP_SECONDS * SAMPLE_RATE)
    samples = [0.0] * (round(SHUFFLE_SPACING * SAMPLE_RATE * (SHUFFLE_TAPS - 1)) + tap_length)
    for tap in range(SHUFFLE_TAPS):
        first = round(tap * SHUFFLE_SPACING * SAMPLE_RATE)
        loudness = 1 + (SHUFFLE_TAIL_GAIN - 1) * tap / (SHUFFLE_TAPS - 1)
        smooth = 0.0
        for i in range(tap_length):
            smooth += SHUFFLE_SMOOTH * (rng.uniform(-1, 1) - smooth)
            decay = SILENT_GAIN ** (i / tap_length)
            samples[first + i] += smooth * decay * loudness
    peak = max(abs(s) for s in samples)
    return [s / peak * SHUFFLE_VOLUME * VOLUME for s in samples]


def write_wav(path, samples):
    with wave.open(path, 'wb') as file:
        file.setnchannels(1)
        file.setsampwidth(2)
        file.setframerate(SAMPLE_RATE)
        file.writeframes(b''.join(struct.pack('<h', round(max(-1, min(1, s)) * MAX_SAMPLE)) for s in samples))


def main(output_dir):
    os.makedirs(output_dir, exist_ok=True)
    sounds = {name: render(notes) for name, notes in MELODIES.items()}
    sounds['teleport'] = render_teleport()
    sounds['draw'] = render_draw()
    sounds['shuffle'] = render_shuffle()
    for name, samples in sounds.items():
        write_wav(os.path.join(output_dir, f'{name}.wav'), samples)
        print(f'{name}.wav')


if __name__ == '__main__':
    main(sys.argv[1])
