"""Ahşap kaplamanın kare dokusunu ve içi boş elmas kakma görselini üretir.

Kare dokusu açık, renksiz (gri tonlu) ahşaptır: oyunda kaplamadaki renkle çarpılarak boyanır,
böylece dama düzenindeki açık ve koyu kareler ile ev yollarının rengi kaplamadan ayarlanır.
Üstte ince bir kenar, altta karenin kalınlığını gösteren koyu bir şerit vardır; oranları
kaplamadaki square_top ve square_depth ile aynı olmalıdır.
Kakma görseli saydam zeminde beyaz, içi boş bir elmastır; boyanmadan karenin yüzüne çizilir.
Çember kare dokusu aynı karedir, köşe yuvarlaklığı kenarın yarısıdır.
Masa görseli tek parça damarlı ahşaptır, yan yana döşenebilir (kenarları birbirini tutar).
Pillow ve numpy gerekir.

Kullanım:
  python tools/make_wood_tiles.py assets/images
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 256
# Büyük çizip küçülterek kenarları yumuşatma katsayısı.
SUPERSAMPLE = 4
SEED = 7

# Kare: köşe yuvarlaklığı, çerçeve kalınlığı, üst kenar ve alt kalınlık (boya oranları).
CORNER = 0.16
# Çember karenin köşe yuvarlaklığı.
ROUND_CORNER = 0.5
BORDER = 0.035
TOP = 0.05
DEPTH = 0.07
# Gri tonlar (0–1): çerçeve, alt kalınlık, yüz ve damar koyuluğu.
BORDER_TONE = 0.42
DEPTH_TONE = 0.66
FACE_TONE = 0.97
GRAIN_DEPTH = 0.09
HIGHLIGHT = 0.03

# Elmas: yüze oranla yarı genişlik ve yarı yükseklik, çizgi kalınlığı ve dış kontur.
DIAMOND_HALF_X = 0.36
DIAMOND_HALF_Y = 0.38
DIAMOND_LINE = 0.075
OUTLINE = 0.02
# Masa: kenar uzunluğu, renk ve damar koyuluğu.
TABLE_SIZE = 512
TABLE_COLOR = np.array([125, 81, 48]) / 255
TABLE_GRAIN = 0.3
# Liflerin sayısını belirleyen en yüksek dalga sayısı.
FIBER_WAVES = 120
INLAY_COLOR = (255, 255, 255, 255)
OUTLINE_COLOR = (122, 86, 52, 255)


def grain(width, height, rng):
    """Yatay ahşap damarı: satır satır dalgalanan, ince ve kalın çizgilerin toplamı."""
    y = np.arange(height)[:, None] / height
    x = np.arange(width)[None, :] / width
    wave = 0.04 * np.sin(2 * np.pi * (x + rng.random())) + 0.02 * np.sin(
        2 * np.pi * (x * 3 + rng.random())
    )
    rings = np.sin(2 * np.pi * (y + wave) * 9) * 0.6 + np.sin(2 * np.pi * (y + wave) * 23) * 0.4
    noise = rng.normal(0, 0.25, (height, 1)) * np.ones((1, width))
    return np.clip((rings + noise) * 0.5 + 0.5, 0, 1)


def tile(rng, corner):
    big = SIZE * SUPERSAMPLE
    radius = round(big * corner)
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, big - 1, big - 1), radius, fill=255)
    border = round(big * BORDER)
    face_box = (border, round(big * TOP), big - 1 - border, big - 1 - round(big * DEPTH))
    face = Image.new("L", (big, big), 0)
    ImageDraw.Draw(face).rounded_rectangle(face_box, radius - border, fill=255)
    lower = Image.new("L", (big, big), 0)
    lower_box = (border, round(big * TOP), big - 1 - border, big - 1 - border)
    ImageDraw.Draw(lower).rounded_rectangle(lower_box, radius - border, fill=255)

    tone = np.full((big, big), BORDER_TONE)
    tone[np.array(lower) > 0] = DEPTH_TONE
    wood = FACE_TONE - GRAIN_DEPTH * grain(big, big, rng)
    top = np.linspace(HIGHLIGHT, -HIGHLIGHT, big)[:, None]
    face_on = np.array(face) > 0
    tone[face_on] = np.clip(wood + top, 0, 1)[face_on]

    gray = Image.fromarray((tone * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(1.5))
    image = Image.merge("RGBA", (gray, gray, gray, mask))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def diamond(scale, inset):
    """Yüzün ortasındaki elmasın köşeleri; inset, kenarların içeri kayma miktarıdır (piksel)."""
    center = SIZE * scale / 2
    half_x, half_y = SIZE * scale * DIAMOND_HALF_X, SIZE * scale * DIAMOND_HALF_Y
    shrink = 1 - inset * np.hypot(half_x, half_y) / (half_x * half_y)
    half_x, half_y = half_x * shrink, half_y * shrink
    return [
        (center, center - half_y),
        (center + half_x, center),
        (center, center + half_y),
        (center - half_x, center),
    ]


def inlay():
    """İç içe dolu elmaslar: kontur, beyaz çizgi, kontur ve saydam iç."""
    big = SIZE * SUPERSAMPLE
    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    draw = ImageDraw.Draw(image)
    line, outline = big * DIAMOND_LINE, big * OUTLINE
    layers = (
        (0, OUTLINE_COLOR),
        (outline, INLAY_COLOR),
        (outline + line, OUTLINE_COLOR),
        (2 * outline + line, (0, 0, 0, 0)),
    )
    for inset, color in layers:
        draw.polygon(diamond(SUPERSAMPLE, inset), fill=color)
    return image.resize((SIZE, SIZE), Image.LANCZOS)


def fibers(size, rng):
    """Uzun ahşap lifleri: satır boyunca düzensiz tonlar, hafifçe kıvrılan; her yönde döşenebilir."""
    y = np.arange(size)[:, None] / size
    x = np.arange(size)[None, :] / size
    bend = sum(
        0.012 / k * np.sin(2 * np.pi * (k * x + rng.random())) for k in range(1, 4)
    ) + 0.004 * np.sin(2 * np.pi * (5 * y + 2 * x + rng.random()))
    tone = np.zeros((size, size))
    for k in range(4, FIBER_WAVES):
        tone += rng.normal() / k**0.7 * np.sin(2 * np.pi * k * (y + bend) + rng.random() * 6.3)
    tone -= tone.min()
    return tone / tone.max()


def table(rng):
    """Ahşap masa: tek parça, birleşim çizgisi olmayan lifli yüzey."""
    tone = 1 - TABLE_GRAIN * fibers(TABLE_SIZE, rng)
    image = np.clip(tone[:, :, None] * TABLE_COLOR, 0, 1)
    return Image.fromarray((image * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(0.6))


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    tile(np.random.default_rng(SEED), CORNER).save(os.path.join(out, "tile_wood.png"))
    tile(np.random.default_rng(SEED), ROUND_CORNER).save(os.path.join(out, "tile_wood_round.png"))
    inlay().save(os.path.join(out, "tile_inlay_diamond.png"))
    table(np.random.default_rng(SEED)).save(os.path.join(out, "table_wood.png"))
