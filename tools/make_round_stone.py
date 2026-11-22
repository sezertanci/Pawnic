"""Klasik kaplamanın çember kare dokusunu, kare taş görselinden (tile_stone.png) üretir.

Çember, dışta lacivert bir kenar, altta karenin kalınlığını gösteren koyu bir şerit ve üstte
taş görselinin çatlaklı yüzünden kesilmiş bir yüzden oluşur. Üst kenar ve alt kalınlık oranları
klasik kaplamadaki square_top ve square_depth ile aynı olmalıdır.
Pillow ve numpy gerekir.

Kullanım:
  python tools/make_round_stone.py assets/images
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw

SIZE = 256
# Büyük çizip küçülterek kenarları yumuşatma katsayısı.
SUPERSAMPLE = 4

# Kenar kalınlığı, üst kenar ve alt kalınlık (kenar uzunluğuna oran).
BORDER = 0.045
TOP = 0.068
DEPTH = 0.064
# Kare görselde kenarın ve çatlaklı yüzün yeri (piksel, 256'lık görselde).
BORDER_PIXEL = (8, 128)
FACE_BOX = (20, 20, 236, 228)
# Alt kalınlık, yüz renginin bu oranda karartılmışıdır.
DEPTH_SHADE = 0.55


def ellipse_mask(big, box):
    mask = Image.new("L", (big, big), 0)
    ImageDraw.Draw(mask).ellipse(box, fill=255)
    return mask


def round_stone(stone):
    big = SIZE * SUPERSAMPLE
    border, top, depth = (round(big * ratio) for ratio in (BORDER, TOP, DEPTH))
    face_box = (border, top, big - 1 - border, big - 1 - depth)
    lower_box = (border, top, big - 1 - border, big - 1 - border)

    face = stone.crop(FACE_BOX).resize(
        (face_box[2] - face_box[0] + 1, face_box[3] - face_box[1] + 1), Image.LANCZOS
    )
    rim = Image.new("RGBA", (big, big), stone.getpixel(BORDER_PIXEL))
    shade = np.array(face.resize((big, big)), dtype=float)
    shade[:, :, :3] *= DEPTH_SHADE
    lower = Image.fromarray(shade.astype(np.uint8))
    face_layer = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    face_layer.paste(face, face_box[:2])

    image = Image.new("RGBA", (big, big), (0, 0, 0, 0))
    image.paste(rim, (0, 0), ellipse_mask(big, (0, 0, big - 1, big - 1)))
    image.paste(lower, (0, 0), ellipse_mask(big, lower_box))
    image.paste(face_layer, (0, 0), ellipse_mask(big, face_box))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    folder = sys.argv[1]
    stone = Image.open(os.path.join(folder, "tile_stone.png")).convert("RGBA")
    round_stone(stone).save(os.path.join(folder, "tile_stone_round.png"))
