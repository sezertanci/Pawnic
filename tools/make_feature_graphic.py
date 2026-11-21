"""Play Store'un öne çıkan görselini (1024×500) üretir.

Solda oyun simgesi, altında Titan One yazı tipiyle "Pawnic" adı ve onun altında mağaza diline
göre kısa slogan bulunur. Sağda tahtanın tamamı ve önünde yelpaze gibi açılmış beş kart durur.
Zemin, simgenin koyu lacivert tonlarında dikey bir degradedir. Her mağaza dili için ayrı görsel
üretilir: <çıktı klasörü>/feature-1024x500-<dil>.png.

Girdiler:
- Kart görselleri: tools/render_cards.gd ile üretilen card_0.png … card_4.png
- Tahta: 10 inç tablet ekran görüntüsünden kırpılmış tahta (store/pawnic/feature-board.png)
- Simge: assets/icon/icon.png, yazı tipi: assets/fonts/titan_one.ttf
Pillow gerekir.

Kullanım (proje kökünden):
  godot --path . -s tools/render_cards.gd -- build/feature_cards
  python tools/make_feature_graphic.py build/feature_cards store/pawnic
"""
import argparse
import os

from PIL import Image, ImageDraw, ImageFilter, ImageFont

WIDTH, HEIGHT = 1024, 500
GRADIENT_TOP = (42, 47, 66)
GRADIENT_BOTTOM = (25, 28, 40)
SHADOW_OPACITY = 0.6

BOARD_IMAGE = os.path.join('store', 'pawnic', 'feature-board.png')
BOARD_SIZE = 400
BOARD_POS = (575, 22)
BOARD_RADIUS = 22

CARD_COUNT = 5
CARD_FILE = 'card_{}.png'
CARD_WIDTH = 104
CARD_SPACING = 90  # Yelpazede kart merkezleri arasındaki yatay uzaklık.
CARD_TILT = 7  # Ortadan her adımda eklenen eğim (derece).
CARD_TOP = 296
CARD_DROP = 6  # Kenardaki kartların yay çizecek kadar aşağı inmesi için katsayı.

ICON_PATH = os.path.join('assets', 'icon', 'icon.png')
ICON_SIZE = 210
ICON_RADIUS = 46
ICON_POS = (140, 48)

FONT_PATH = os.path.join('assets', 'fonts', 'titan_one.ttf')
TITLE = 'Pawnic'
TITLE_SIZE = 80
TITLE_TOP = 285
TITLE_COLOR = (255, 196, 40, 255)
TITLE_STROKE = 5
TITLE_STROKE_COLOR = (22, 30, 60, 255)
TITLE_SHADOW_OFFSET = (4, 6)
TITLE_SHADOW_COLOR = (10, 12, 20, 255)

OUTPUT_FILE = 'feature-1024x500-{}.png'
# Mağaza diline göre slogan (kısa açıklamanın ilk cümlesi).
SLOGANS = {'tr-TR': 'Zar yok, kart var!', 'en-US': 'No dice, just cards!'}
SLOGAN_SIZE = 36
SLOGAN_TOP = 395
SLOGAN_COLOR = (255, 255, 255, 255)
SLOGAN_STROKE = 3


def gradient_background():
    image = Image.new('RGB', (WIDTH, HEIGHT))
    draw = ImageDraw.Draw(image)
    for y in range(HEIGHT):
        t = y / (HEIGHT - 1)
        color = tuple(int(a + (b - a) * t) for a, b in zip(GRADIENT_TOP, GRADIENT_BOTTOM))
        draw.line([(0, y), (WIDTH, y)], fill=color)
    return image.convert('RGBA')


def round_corners(image, radius):
    mask = Image.new('L', image.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, image.width - 1, image.height - 1], radius, fill=255)
    image.putalpha(mask)
    return image


def paste_with_shadow(base, image, pos, blur=14, offset=8):
    """Görseli, altına aşağı kaymış ve bulanıklaştırılmış bir gölge koyarak yapıştırır."""
    shadow = Image.new('RGBA', base.size, (0, 0, 0, 0))
    alpha = image.split()[3].point(lambda v: v * SHADOW_OPACITY)
    shadow.paste((0, 0, 0, 255), (pos[0], pos[1] + offset), alpha)
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    base.paste(shadow, (0, 0), shadow)
    base.paste(image, pos, image)


def draw_board(base):
    board = Image.open(BOARD_IMAGE).convert('RGB')
    board = board.resize((BOARD_SIZE, BOARD_SIZE), Image.LANCZOS).convert('RGBA')
    paste_with_shadow(base, round_corners(board, BOARD_RADIUS), BOARD_POS)


def draw_cards(base, cards_dir):
    center_x = BOARD_POS[0] + BOARD_SIZE // 2
    middle = CARD_COUNT // 2
    for i in range(CARD_COUNT):
        card = Image.open(os.path.join(cards_dir, CARD_FILE.format(i))).convert('RGBA')
        card = card.resize((CARD_WIDTH, card.height * CARD_WIDTH // card.width), Image.LANCZOS)
        step = i - middle
        card = card.rotate(-step * CARD_TILT, resample=Image.BICUBIC, expand=True)
        x = int(center_x + step * CARD_SPACING - card.width / 2)
        y = CARD_TOP + step * step * CARD_DROP
        paste_with_shadow(base, card, (x, y), blur=8, offset=5)


def draw_centered_text(base, text, top, size, fill, stroke):
    """Yazıyı simgenin altına ortalar; altına gölge, çevresine koyu kontur çizer."""
    font = ImageFont.truetype(FONT_PATH, size)
    draw = ImageDraw.Draw(base)
    x = ICON_POS[0] + ICON_SIZE / 2 - draw.textlength(text, font=font) / 2
    shadow_pos = (x + TITLE_SHADOW_OFFSET[0], top + TITLE_SHADOW_OFFSET[1])
    draw.text(shadow_pos, text, font=font, fill=TITLE_SHADOW_COLOR)
    draw.text((x, top), text, font=font, fill=fill, stroke_width=stroke, stroke_fill=TITLE_STROKE_COLOR)


def draw_icon_and_title(base, slogan):
    icon = Image.open(ICON_PATH).convert('RGBA').resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)
    paste_with_shadow(base, round_corners(icon, ICON_RADIUS), ICON_POS)
    draw_centered_text(base, TITLE, TITLE_TOP, TITLE_SIZE, TITLE_COLOR, TITLE_STROKE)
    draw_centered_text(base, slogan, SLOGAN_TOP, SLOGAN_SIZE, SLOGAN_COLOR, SLOGAN_STROKE)


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('cards_dir', help='render_cards.gd çıktılarının bulunduğu klasör')
    parser.add_argument('output_dir', help='görsellerin yazılacağı klasör')
    args = parser.parse_args()
    for locale, slogan in SLOGANS.items():
        image = gradient_background()
        draw_board(image)
        draw_cards(image, args.cards_dir)
        draw_icon_and_title(image, slogan)
        image.convert('RGB').save(os.path.join(args.output_dir, OUTPUT_FILE.format(locale)), optimize=True)


if __name__ == '__main__':
    main()
