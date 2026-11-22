"""Gece neon kaplamasının kare dokusunu üretir.

Kare dokusu renksizdir (gri tonlu): oyunda kaplamadaki renkle çarpılarak boyanır. Parlak bir
kenar çizgisi, dışında saydam zemine yayılan ışıma, içinde kenardan içeri sönen hafif bir ışık
ve daha koyu bir yüz vardır; böylece kenar aynı rengin en parlak tonu olur.
Çember kare dokusu aynı karedir, köşe yuvarlaklığı kenarın yarısıdır.
Pillow ve numpy gerekir.

Kullanım:
  python tools/make_neon_tiles.py assets/images
"""

import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

SIZE = 256
# Büyük çizip küçülterek kenarları yumuşatma katsayısı.
SUPERSAMPLE = 4

# Kare: dış ışıma payı, köşe yuvarlaklığı ve kenar çizgisi kalınlığı (kenar uzunluğuna oran).
GLOW_MARGIN = 0.03
CORNER = 0.16
# Çember karenin köşe yuvarlaklığı.
ROUND_CORNER = 0.5
EDGE_LINE = 0.04
# Kenara yakın keskin ışık ve dışa yayılan geniş hale: yayılma (kenar uzunluğuna oran) ve güç.
GLOW_BLUR = 0.007
GLOW_STRENGTH = 2.6
HALO_BLUR = 0.012
HALO_STRENGTH = 1.2
# Gri tonlar (0–1): yüz ve kenardan içeri sönen ışık.
FACE_TONE = 0.45
INNER_GLOW = 0.15


def glow(mask, blur, strength):
    """Maskenin bulanık kopyasını güçlendirip maskeyle birleştirir (0–1 dizi döner)."""
    soft = np.array(mask.filter(ImageFilter.GaussianBlur(blur)), dtype=float) / 255
    return np.clip(np.maximum(soft * strength, np.array(mask, dtype=float) / 255), 0, 1)


def tile(corner):
    big = SIZE * SUPERSAMPLE
    margin = round(big * GLOW_MARGIN)
    radius = round(big * corner)
    line = round(big * EDGE_LINE)
    box = (margin, margin, big - 1 - margin, big - 1 - margin)
    edge = Image.new("L", (big, big), 0)
    ImageDraw.Draw(edge).rounded_rectangle(box, radius, outline=255, width=line)
    face = Image.new("L", (big, big), 0)
    ImageDraw.Draw(face).rounded_rectangle(box, radius, fill=255)

    face_on = np.array(face, dtype=float) / 255
    light = glow(edge, big * GLOW_BLUR, GLOW_STRENGTH)
    light = np.maximum(light, glow(edge, big * HALO_BLUR, HALO_STRENGTH) * (1 - face_on))
    tone = np.clip(FACE_TONE + INNER_GLOW * light, 0, 1) * face_on + light * (1 - face_on)
    tone = np.maximum(tone, np.array(edge, dtype=float) / 255)
    alpha = np.maximum(face_on, light)

    gray = Image.fromarray((tone * 255).astype(np.uint8))
    image = Image.merge("RGBA", (gray, gray, gray, Image.fromarray((alpha * 255).astype(np.uint8))))
    return image.resize((SIZE, SIZE), Image.LANCZOS)


if __name__ == "__main__":
    out = sys.argv[1]
    os.makedirs(out, exist_ok=True)
    tile(CORNER).save(os.path.join(out, "tile_neon.png"))
    tile(ROUND_CORNER).save(os.path.join(out, "tile_neon_round.png"))
