"""Düğme görselinin renk tonunu kaydırarak başka renkte bir kopya üretir.

Parlaklık ve doygunluk korunur, yalnızca ton döner; böylece gölge, parıltı ve çerçeve aynı kalır.
Kırmızı düğme (ör. geri dönülmez işi onaylayan Çık) turuncu düğmeden üretilir. Pillow gerekir.

Kullanım:
  python tools/shift_button_hue.py assets/images/button_orange_plain.png assets/images/button_red_plain.png -28
"""

import sys

from PIL import Image

# Tam tur (derece) ve Pillow'un HSV kipindeki ton aralığı.
FULL_TURN = 360
HUE_STEPS = 256


def shift_hue(source, degrees):
    image = source.convert("RGBA")
    alpha = image.getchannel("A")
    hue, saturation, value = image.convert("RGB").convert("HSV").split()
    offset = round(degrees / FULL_TURN * HUE_STEPS)
    hue = hue.point(lambda h: (h + offset) % HUE_STEPS)
    result = Image.merge("HSV", (hue, saturation, value)).convert("RGBA")
    result.putalpha(alpha)
    return result


def main(source, target, degrees):
    shift_hue(Image.open(source), float(degrees)).save(target)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
