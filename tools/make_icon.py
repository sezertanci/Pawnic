"""Oyunun ikonlarını logo, taş ve kare görsellerinden üretir.

Üç tasarım vardır, zemin ikisinde de oyun ekranının arka plan rengidir:
- board (varsayılan): 5×5 kare halkadan bir tahta. Kenar ortalarındaki kareler koltuk
  renklerine boyanır ve her taş kendi renk karesinde durur; ortada logodaki "P" harfi bulunur.
- text: ortada dikeyde biraz uzatılmış "Pawnic" yazısı, üstünde kırmızı ve mavi, altında
  sarı ve yeşil taş.
- frame: 9 sütunluk yatay kare çerçeve, içinde "Pawnic" yazısı; köşe kareleri koltuk
  renklerinde ve her taş kendi köşesinde. Oyunun açılış ekranında kullanılır.

Üretilen dosyalar:
- icon.png (varsayılan 512×512, --size ile değişir): proje ikonu, Play Store ikonu ve açılış
  ekranı görseli
- icon_192.png: Android'in eski tip başlatıcı ikonu
- icon_foreground.png ve icon_background.png (432×432): Android'in uyarlanabilir ikon katmanları.
  Ön planda içerik, telefonun her zaman gösterdiği ortadaki 2/3'lük alana sığdırılır.
Pillow gerekir.

Kullanım:
  python tools/make_icon.py assets/images assets/icon
  python tools/make_icon.py assets/images assets/icon/text --design text
  python tools/make_icon.py assets/images assets/icon/frame --design frame --size 1024
"""
import argparse
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ICON_SIZE = 512
LEGACY_SIZE = 192
ADAPTIVE_SIZE = 432
# Uyarlanabilir ikonda her zaman görünen alan (108 dp içinde 72 dp).
ADAPTIVE_VISIBLE = 2 / 3
BACKGROUND = (31, 33, 43, 255)  # Oyun ekranının zemini: Color(0.12, 0.13, 0.17).
SEAT_COLORS = ['red', 'blue', 'green', 'yellow']

# --- text tasarımı ---
LOGO_WIDTH = 0.9  # Yazı genişliği, ikon genişliğine oranla.
LOGO_STRETCH = 1.35  # Yazının dikeyde uzatılma oranı.
PAWN_HEIGHT = 0.95  # Taş boyu, uzatılmamış yazı boyuna oranla.
PAWN_GAP = 0.12  # Taşla yazı arasındaki boşluk, uzatılmamış yazı boyuna oranla.
PAWN_OFFSET = 0.2  # Taşların ortadan yana uzaklığı, yazı genişliğine oranla.
# (renk, yukarıda mı, solda mı)
TEXT_PAWNS = [('red', True, True), ('blue', True, False), ('yellow', False, True),
              ('green', False, False)]

# --- board tasarımı ---
BOARD_CELLS = 5  # Tahtanın bir kenarındaki kare sayısı.
BOARD_WIDTH = 0.9  # Tahta genişliği, ikon genişliğine oranla.
TILE_GAP = 0.03  # Kareler arası boşluk, kare boyuna oranla.
PAWN_HEIGHT_IN_CELL = 0.95  # Tahtadaki taş boyu, kare boyuna oranla.
LETTER_HEIGHT = 2.7  # "P" harfinin boyu, kare boyuna oranla.

# --- frame tasarımı ---
FRAME_COLUMNS = 9  # Yatay çerçevenin sütun sayısı; satır sayısı yazının boyuna göre bulunur.
FRAME_WIDTH = 0.94  # Çerçeve genişliği, alan genişliğine oranla.
# Oyundaki classic görünümün değerleri (themes/skins/classic.tres).
TRACK_COLOR = (0.95, 0.94, 0.9)
SEAT_TINTS = {'red': (0.88, 0.29, 0.29), 'blue': (0.25, 0.5, 0.88),
              'green': (0.25, 0.68, 0.35), 'yellow': (0.91, 0.76, 0.23)}
START_TINT = 0.55
SQUARE_TOP = 0.1
SQUARE_DEPTH = 0.12
PAWN_FOOT = 0.72  # Taş görselinde ayağın, yukarıdan boya oranla yeri.
# Kenar ortası kareleri (sütun, satır), saat yönünde: üst, sağ, alt, sol.
SEAT_SQUARES = {'red': (2, 0), 'blue': (4, 2), 'green': (2, 4), 'yellow': (0, 2)}
# Logoda "P" harfinin sarı dolgusunu ayırmak için eşikler ve tohum noktası.
LETTER_SEED_ROW = 110
LETTER_OUTLINE = 31  # Dolgunun çevresinde alınan lacivert kenarlığın genişliği (piksel).
NEIGHBOR_MARGIN = 9  # Komşu harften uzak durulacak mesafe (piksel).


def load(folder, name):
    return Image.open(os.path.join(folder, name + '.png')).convert('RGBA')


def resized(image, width, height):
    return image.resize((round(width), round(height)), Image.LANCZOS)


def is_yellow(pixel):
    red, green, blue, alpha = pixel
    return alpha > 128 and red > 170 and green > 90 and blue < 110


def cut_letter(logo):
    """Logodaki ilk harfi ("P") kenarlığıyla birlikte keser."""
    yellow = Image.new('L', logo.size, 0)
    pixels, marks = logo.load(), yellow.load()
    for y in range(logo.height):
        for x in range(logo.width):
            if is_yellow(pixels[x, y]):
                marks[x, y] = 255
    seed = next((x, LETTER_SEED_ROW) for x in range(logo.width) if marks[x, LETTER_SEED_ROW])
    ImageDraw.floodfill(yellow, seed, 128)
    letter = yellow.point(lambda v: 255 if v == 128 else 0)
    others = yellow.point(lambda v: 255 if v == 255 else 0)
    grown = letter.filter(ImageFilter.MaxFilter(LETTER_OUTLINE))
    blocked = ImageChops.invert(others.filter(ImageFilter.MaxFilter(NEIGHBOR_MARGIN)))
    mask = ImageChops.multiply(ImageChops.multiply(grown, blocked), logo.getchannel('A'))
    result = logo.copy()
    result.putalpha(mask)
    return result.crop(result.getbbox())


def tinted_tile(stone, tint, side):
    tile = resized(stone, side, side)
    color = tuple(round(c * 255) for c in tint) + (255,)
    return ImageChops.multiply(tile, Image.new('RGBA', tile.size, color))


def lerp(start, end, weight):
    return tuple(a + (b - a) * weight for a, b in zip(start, end))


def draw_centered(canvas, image, height):
    """Görseli oranını koruyarak height boyunda, tuvalin ortasına çizer."""
    width = height * image.width / image.height
    center = canvas.width / 2
    canvas.alpha_composite(resized(image, width, height),
                           (round(center - width / 2), round(center - height / 2)))


def draw_ring(canvas, images, cell, columns, rows, seat_squares):
    """columns×rows kare halkayı ve taşları tuvalin ortasına çizer.

    seat_squares her rengin (sütun, satır) karesidir; o kare koltuk rengine boyanır ve
    taş üstüne konur.
    """
    left = (canvas.width - cell * columns) / 2
    top = (canvas.height - cell * rows) / 2
    gap = cell * TILE_GAP
    tints = {square: lerp(TRACK_COLOR, SEAT_TINTS[color], START_TINT)
             for color, square in seat_squares.items()}
    for column in range(columns):
        for row in range(rows):
            if column in (0, columns - 1) or row in (0, rows - 1):
                tint = tints.get((column, row), TRACK_COLOR)
                tile = tinted_tile(images['tile_stone'], tint, cell - gap)
                canvas.alpha_composite(tile, (round(left + column * cell + gap / 2),
                                              round(top + row * cell + gap / 2)))
    # Aşağıdaki taş yukarıdakinin üstüne binsin diye taşlar yukarıdan aşağı çizilir.
    face = 1 - SQUARE_TOP - SQUARE_DEPTH
    for color in sorted(seat_squares, key=lambda c: seat_squares[c][1]):
        column, row = seat_squares[color]
        pawn = images[color]
        height = cell * PAWN_HEIGHT_IN_CELL
        width = height * pawn.width / pawn.height
        foot_y = top + row * cell + cell * (SQUARE_TOP + face / 2)
        canvas.alpha_composite(resized(pawn, width, height),
                               (round(left + (column + 0.5) * cell - width / 2),
                                round(foot_y - height * PAWN_FOOT)))


def draw_board(canvas, images, side):
    """Kare tahtayı, taşları ve "P" harfini side boyundaki kare alanın ortasına çizer."""
    cell = side * BOARD_WIDTH / BOARD_CELLS
    draw_ring(canvas, images, cell, BOARD_CELLS, BOARD_CELLS, SEAT_SQUARES)
    draw_centered(canvas, images['letter'], cell * LETTER_HEIGHT)


def draw_frame(canvas, images, side):
    """Yatay çerçeveyi, köşelerdeki taşları ve ortadaki yazıyı side boyundaki alana çizer."""
    cell = side * FRAME_WIDTH / FRAME_COLUMNS
    logo = images['logo']
    logo_width = cell * (FRAME_COLUMNS - 2)
    rows = math.ceil(logo_width * logo.height / logo.width / cell) + 2
    last_column, last_row = FRAME_COLUMNS - 1, rows - 1
    corners = {'red': (0, 0), 'blue': (last_column, 0), 'green': (last_column, last_row),
               'yellow': (0, last_row)}
    draw_ring(canvas, images, cell, FRAME_COLUMNS, rows, corners)
    draw_centered(canvas, logo, logo_width * logo.height / logo.width)


def draw_text(canvas, images, side):
    """Yazıyı ve taşları side boyundaki kare alanın ortasına çizer."""
    logo = images['logo']
    width = side * LOGO_WIDTH
    plain_height = width * logo.height / logo.width
    height = plain_height * LOGO_STRETCH
    center = canvas.width / 2
    canvas.alpha_composite(resized(logo, width, height),
                           (round(center - width / 2), round(center - height / 2)))
    pawn_height = plain_height * PAWN_HEIGHT
    gap = plain_height * PAWN_GAP
    for color, upper, left in TEXT_PAWNS:
        pawn = images[color]
        pawn_width = pawn_height * pawn.width / pawn.height
        x = center + (-1 if left else 1) * width * PAWN_OFFSET - pawn_width / 2
        if upper:
            y = center - height / 2 - gap - pawn_height
        else:
            y = center + height / 2 + gap
        canvas.alpha_composite(resized(pawn, pawn_width, pawn_height), (round(x), round(y)))


DESIGNS = {'board': draw_board, 'frame': draw_frame, 'text': draw_text}


def load_images(source):
    images = {color: load(source, 'pawn_' + color) for color in SEAT_COLORS}
    images['logo'] = load(source, 'logo')
    images['tile_stone'] = load(source, 'tile_stone')
    images['letter'] = cut_letter(images['logo'])
    return images


def main(source, target, design, size):
    draw = DESIGNS[design]
    images = load_images(source)
    os.makedirs(target, exist_ok=True)

    icon = Image.new('RGBA', (size, size), BACKGROUND)
    draw(icon, images, size)
    icon.save(os.path.join(target, 'icon.png'))
    resized(icon, LEGACY_SIZE, LEGACY_SIZE).save(os.path.join(target, 'icon_192.png'))

    foreground = Image.new('RGBA', (ADAPTIVE_SIZE, ADAPTIVE_SIZE), (0, 0, 0, 0))
    draw(foreground, images, ADAPTIVE_SIZE * ADAPTIVE_VISIBLE)
    foreground.save(os.path.join(target, 'icon_foreground.png'))
    background = Image.new('RGBA', (ADAPTIVE_SIZE, ADAPTIVE_SIZE), BACKGROUND)
    background.save(os.path.join(target, 'icon_background.png'))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Oyunun ikonlarını üretir.')
    parser.add_argument('source', help='Logo, taş ve kare görsellerinin klasörü')
    parser.add_argument('target', help='İkonların yazılacağı klasör')
    parser.add_argument('--design', choices=sorted(DESIGNS), default='board')
    parser.add_argument('--size', type=int, default=ICON_SIZE, help='icon.png boyutu (piksel)')
    arguments = parser.parse_args()
    main(arguments.source, arguments.target, arguments.design, arguments.size)
