"""Play mağazası ekran görüntülerinin üstüne tanıtım başlığını bindirir.

Ham görüntüler tools/store_screenshots.gd ile üretilir. Görüntünün üst kısmına yarı saydam koyu
bir şerit gelir; oyun ekranı tam boy kalır, üst çubuğun bir kısmı şeridin altında kalır. Başlık
Titan One yazı tipiyle, beyaz ve ortalı yazılır; sığmazsa iki satıra bölünür. Başlıklar
store/pawnic/screenshots/captions.json dosyasındadır.
Pillow gerekir.

Kullanım (proje kökünden):
  python tools/make_store_screenshots.py <ham klasör> store/pawnic/screenshots
Ham klasörün düzeni: <ham klasör>/<tr|en>/<phone|tablet-7|tablet-10>/<ad>.png
"""
import argparse
import json
import os

from PIL import Image, ImageDraw, ImageFont

CAPTIONS_PATH = os.path.join('store', 'pawnic', 'screenshots', 'captions.json')
FONT_PATH = os.path.join('assets', 'fonts', 'titan_one.ttf')
# Mağaza dil kodu ile ham görüntülerin üretildiği oyun dili.
LOCALES = {'tr-TR': 'tr', 'en-US': 'en'}
DEVICES = ('phone', 'tablet-7', 'tablet-10')

BAND_HEIGHT = 0.11  # Şeridin yüksekliği, görüntü yüksekliğine oranla.
BAND_COLOR = (14, 16, 28)
BAND_OPACITY = 215
FADE_HEIGHT = 0.025  # Şeridin altındaki yumuşak geçiş, görüntü yüksekliğine oranla.
TEXT_COLOR = (255, 255, 255, 255)
TEXT_WIDTH = 0.88  # Yazının en fazla kaplayacağı genişlik, görüntü genişliğine oranla.
TEXT_SIZE = 0.042  # Yazı boyutu, görüntü yüksekliğine oranla (tek satır için).
MIN_TEXT_SIZE = 0.03
LINE_SPACING = 0.15  # Satır arası, yazı boyutuna oranla.
SHADOW_OFFSET = 0.06  # Gölge kayması, yazı boyutuna oranla.
SHADOW_COLOR = (0, 0, 0, 160)
# Titan One'da İ glifi yok: yerine I yazılır, üstüne i'nin noktası konur.
DOTTED_CAPITAL = 'İ'
PLAIN_CAPITAL = 'I'


def plain(text):
    """Yazı tipinde bulunan harflerle ölçülüp çizilecek metin."""
    return text.replace(DOTTED_CAPITAL, PLAIN_CAPITAL)


def dot_mask(font):
    """i harfinin noktası ve noktayla gövde arasındaki boşluk (alt kenar gövdenin tepesi)."""
    left, top, right, bottom = font.getbbox('i')
    stem_top = font.getbbox('ı')[1]
    mask = Image.new('L', (right, bottom), 0)
    ImageDraw.Draw(mask).text((0, 0), 'i', font=font, fill=255)
    return mask.crop((left, top, right, stem_top))


def draw_line(draw, position, line, font, fill):
    left, top = position
    draw.text((left, top), plain(line), font=font, fill=fill)
    mask = dot_mask(font)
    capital = font.getbbox(PLAIN_CAPITAL)
    for index, char in enumerate(line):
        if char != DOTTED_CAPITAL:
            continue
        x = left + font.getlength(plain(line[:index])) + (capital[0] + capital[2] - mask.width) / 2
        draw.bitmap((x, top + capital[1] - mask.height), mask, fill=fill)


def draw_band(image):
    width, height = image.size
    band = int(height * BAND_HEIGHT)
    fade = int(height * FADE_HEIGHT)
    overlay = Image.new('RGBA', image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    draw.rectangle((0, 0, width, band), fill=BAND_COLOR + (BAND_OPACITY,))
    for step in range(fade):
        alpha = int(BAND_OPACITY * (1 - (step + 1) / (fade + 1)))
        draw.line((0, band + step, width, band + step), fill=BAND_COLOR + (alpha,))
    return Image.alpha_composite(image, overlay), band


def split_lines(text, font, max_width):
    """Yazı sığıyorsa tek satır, sığmıyorsa satır genişlikleri en dengeli iki satır."""
    if font.getlength(plain(text)) <= max_width:
        return [text]
    words = text.split()
    best = None
    for index in range(1, len(words)):
        lines = [' '.join(words[:index]), ' '.join(words[index:])]
        widest = max(font.getlength(plain(line)) for line in lines)
        if best is None or widest < best[0]:
            best = (widest, lines)
    return best[1] if best and best[0] <= max_width else None


def fit_text(text, width, height):
    """Yazıyı sığdıran en büyük boyut ve satırlar; tek satır sığmazsa iki satır denenir."""
    size = int(height * TEXT_SIZE)
    smallest = int(height * MIN_TEXT_SIZE)
    max_width = width * TEXT_WIDTH
    while size >= smallest:
        font = ImageFont.truetype(FONT_PATH, size)
        lines = split_lines(text, font, max_width)
        if lines is not None:
            return font, lines
        size -= 1
    raise ValueError('Başlık sığmıyor: ' + text)


def draw_caption(image, text, band):
    width, height = image.size
    font, lines = fit_text(text, width, height)
    draw = ImageDraw.Draw(image)
    ascent, descent = font.getmetrics()
    line_height = ascent + descent
    gap = int(font.size * LINE_SPACING)
    total = line_height * len(lines) + gap * (len(lines) - 1)
    top = (band - total) // 2
    shadow = int(font.size * SHADOW_OFFSET)
    for line in lines:
        left = (width - font.getlength(plain(line))) / 2
        draw_line(draw, (left + shadow, top + shadow), line, font, SHADOW_COLOR)
        draw_line(draw, (left, top), line, font, TEXT_COLOR)
        top += line_height + gap


def make_screenshot(source, target, text):
    image = Image.open(source).convert('RGBA')
    image, band = draw_band(image)
    draw_caption(image, text, band)
    image.convert('RGB').save(target)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('raw_dir')
    parser.add_argument('out_dir')
    args = parser.parse_args()
    with open(CAPTIONS_PATH, encoding='utf-8') as file:
        captions = json.load(file)
    for store_locale, game_locale in LOCALES.items():
        for device in DEVICES:
            target_dir = os.path.join(args.out_dir, store_locale, device)
            os.makedirs(target_dir, exist_ok=True)
            for name, text in captions[store_locale].items():
                source = os.path.join(args.raw_dir, game_locale, device, name + '.png')
                make_screenshot(source, os.path.join(target_dir, name + '.png'), text)
                print('yazıldı:', os.path.join(target_dir, name + '.png'))


if __name__ == '__main__':
    main()
