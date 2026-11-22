"""Oyunun ses efektlerini WAV dosyası olarak üretir (RobiCodes projesindeki make_sounds.py yöntemiyle).

Sesler kayıt değil, notalardan hesaplanır: kısa yükseliş ve üstel sönme zarfı. Tuş ve adım sesleri
RobiCodes'taki notalarla aynıdır. Işınlanma sesi tonu yükselen, titreşimli bir süpürmedir.
Kart çekme sesi, yavaşça kabarıp sönen boğuk bir fışırtıdır (süzülmüş gürültü).
Karıştırma sesi, kartların art arda birbirine çarptığı hızlı bir tıkırtı dizisidir ("brrrt").
Kura tıkırtısı, çarkın dilinin çiviye çarpması gibi kısa ve parlak bir vuruştur; kura sonucu
iki notalı, yükselen bir çandır. Taş eve girince "sihirli parıltı" çalar: arp telleri gibi
hızla yükselen bir majör dizi ve üstüne serpilen, tiz ve kısa ışıltılar.
Taş kırılınca "ops" sesi çalar: boğuk, tını açısından zengin iki notalı inen bir "vah-vah";
ikinci nota titreyerek aşağı kayar.
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
    'starter': [(784, 0, 0.18), (1175, 0.12, 0.45)],
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

# Kura tıkırtısı: tek, çok kısa bir gürültü vuruşu (çiviye çarpan dil) ve altında hızla sönen tahta
# tınısı. Kura adımları en kısa 0,08 sn olduğundan ses ondan kısadır; üst üste binmez.
SPIN_SECONDS = 0.03
SPIN_SMOOTH = 0.6            # Karıştırmadan da açık süzgeç: kuru, parlak tık.
SPIN_BODY_HZ = 1400          # Vuruşa gövde veren tını.
SPIN_BODY_MIX = 0.5          # Tınının gürültüye oranla payı.
SPIN_VOLUME = 0.8
SPIN_SEED = 13

# Kırılma ("ops") sesi render_voiced ile çalınır. Kırılmada her nota başlangıç frekansından bitişe kayar. Tını, tek harmoniklerin
# azalan oranlarla eklenmesiyle (yumuşak kare dalga) boğuk bir üflemeli sesine benzer.
# Notalar: (başlangıç Hz, bitiş Hz, başlangıç sn, süre sn, titreşim derinliği).
CAPTURE_NOTES = [
    (392, 370, 0.0, 0.22, 0.0),
    (311, 233, 0.2, 0.55, 0.03),
]
CAPTURE_HARMONICS = [(1, 1.0), (3, 0.33), (5, 0.12)]
VIBRATO_HZ = 6
CAPTURE_VOLUME = 0.9


# Sihirli parıltı: HOME_SCALE notaları HOME_STRUM aralıklarla çekilir (son nota uzun tınlar);
# HOME_SPARKLES tane tiz ışıltı, HOME_SPARKLE_FROM saniyesinden sonra rastgele zamanlarda ve
# frekanslarda serpilir.
HOME_SCALE = [523, 587, 659, 784, 880, 1047, 1175, 1319, 1568, 2093]
HOME_STRUM = 0.035
HOME_NOTE_SECONDS = 0.35
HOME_LAST_SECONDS = 0.9
HOME_SPARKLES = 14
HOME_SPARKLE_FROM = 0.15
HOME_SPARKLE_UNTIL = 1.0
SPARKLE_HZ = (2500, 5000)
SPARKLE_SECONDS = 0.12
SPARKLE_VOLUME = 0.35   # Işıltıların dizinin notalarına oranla genliği.
HOME_VOLUME = 1.0
HOME_SEED = 23


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


def render_spin():
    rng = random.Random(SPIN_SEED)
    length = round(SPIN_SECONDS * SAMPLE_RATE)
    samples = []
    smooth = 0.0
    for i in range(length):
        smooth += SPIN_SMOOTH * (rng.uniform(-1, 1) - smooth)
        body = SPIN_BODY_MIX * sine(SPIN_BODY_HZ * i / SAMPLE_RATE)
        samples.append((smooth + body) * SILENT_GAIN ** (i / length))
    peak = max(abs(s) for s in samples)
    return [s / peak * SPIN_VOLUME * VOLUME for s in samples]


def render_voiced(notes, harmonics, volume):
    """Kayan, titreyebilen ve harmonikli notaları çalar; tepe genliği volume oranına getirir."""
    length = max(start + duration for _, _, start, duration, _ in notes)
    samples = [0.0] * math.ceil(length * SAMPLE_RATE)
    for begin_hz, end_hz, start, duration, vibrato in notes:
        first = round(start * SAMPLE_RATE)
        phase = 0.0
        for i in range(round(duration * SAMPLE_RATE)):
            t = i / SAMPLE_RATE
            wobble = 1 + vibrato * sine(VIBRATO_HZ * t)
            phase += begin_hz * (end_hz / begin_hz) ** (t / duration) * wobble / SAMPLE_RATE
            tone = sum(weight * sine(phase * harmonic) for harmonic, weight in harmonics)
            samples[first + i] += tone * gain_at(t, duration)
    return normalized(samples, volume)


def normalized(samples, volume):
    peak = max(abs(s) for s in samples)
    return [s / peak * volume * VOLUME for s in samples]


def add_sparkles(samples, count, start, end, seed):
    """samples'a start ile end saniyeleri arasında rastgele count tane tiz ışıltı ekler."""
    rng = random.Random(seed)
    sparkles = [
        (rng.uniform(*SPARKLE_HZ), rng.uniform(start, end), SPARKLE_SECONDS)
        for _ in range(count)
    ]
    for i, value in enumerate(render(sparkles)):
        if i >= len(samples):
            samples.append(0.0)
        samples[i] += value * SPARKLE_VOLUME
    return samples


def render_home():
    last = len(HOME_SCALE) - 1
    notes = [
        (hz, i * HOME_STRUM, HOME_LAST_SECONDS if i == last else HOME_NOTE_SECONDS)
        for i, hz in enumerate(HOME_SCALE)
    ]
    samples = add_sparkles(
        render(notes), HOME_SPARKLES, HOME_SPARKLE_FROM, HOME_SPARKLE_UNTIL, HOME_SEED
    )
    return normalized(samples, HOME_VOLUME)


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
    sounds['spin'] = render_spin()
    sounds['home'] = render_home()
    sounds['capture'] = render_voiced(CAPTURE_NOTES, CAPTURE_HARMONICS, CAPTURE_VOLUME)
    for name, samples in sounds.items():
        write_wav(os.path.join(output_dir, f'{name}.wav'), samples)
        print(f'{name}.wav')


if __name__ == '__main__':
    main(sys.argv[1])
