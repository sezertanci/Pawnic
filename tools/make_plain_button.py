"""Menü düğmesi görselinden, soldaki simge yuvarlağı olmayan düz bir kopya üretir.

Sol uç, düğmenin sağ ucunun aynadaki görüntüsüyle değiştirilir. Sağ uç gövdeden biraz daha
koyu olduğu için her satırda renk, birleşim yerindeki gövde rengine eşitlenir; eşitleme dış
kenara doğru azalır, böylece koyu çerçeve olduğu gibi kalır.
Simgesi olmayan düğmelerde (ör. Tamam) kullanılır. Pillow gerekir.

Kullanım:
  python tools/make_plain_button.py assets/images/button_green.png assets/images/button_green_plain.png
"""

import sys

from PIL import Image, ImageOps

# Aynalanan sağ ucun genişliği (piksel); soldaki yuvarlağı tamamen örtmelidir.
CAP_WIDTH = 120
# Gövde renginin okunduğu sütunun, birleşim yerinden uzaklığı (piksel).
BODY_OFFSET = 2
CHANNELS = 3


def row_gain(body, edge):
    return [(body[c] + 1) / (edge[c] + 1) for c in range(CHANNELS)]


def make_plain(source):
    image = source.convert("RGBA")
    width, height = image.size
    original = image.load()
    cap = ImageOps.mirror(image.crop((width - CAP_WIDTH, 0, width, height)))
    cap_pixels = cap.load()
    result = image.copy()
    pixels = result.load()
    join = CAP_WIDTH - 1
    for y in range(height):
        gain = row_gain(original[CAP_WIDTH + BODY_OFFSET, y], cap_pixels[join, y])
        for x in range(CAP_WIDTH):
            pixel = cap_pixels[x, y]
            weight = x / join
            rgb = [min(255, int(pixel[c] * (1 + (gain[c] - 1) * weight))) for c in range(CHANNELS)]
            pixels[x, y] = tuple(rgb) + (pixel[3],)
    return result


def main(source, target):
    make_plain(Image.open(source)).save(target)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
