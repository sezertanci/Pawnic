class_name BigNumber
extends RefCounted
## İri, koyu konturlu ve gölgeli renkli sayı (+7, −5). Kartlarda ve tahtadaki hız karelerinde
## kullanılır; yazı tipi ve renkler arayüz temasındaki CardSymbol türünden okunur.

## Yazı boyu, kontur kalınlığı, gölge kayması ve iki yandaki boşluk (alan genişliğine oranla).
## Rakamların yüksekliği yazı boyunun DIGIT_HEIGHT katıdır; dikey ortalamada kullanılır.
const NUMBER_SIZE := 0.6
const NUMBER_OUTLINE := 0.08
const NUMBER_SHADOW := Vector2(0.025, 0.035)
const NUMBER_MARGIN := 0.08
const DIGIT_HEIGHT := 0.72


## Sayıyı rect'in ortasına çizer: önce kaymış koyu gölge, sonra koyu kontur ve renkli dolgu.
static func draw(
	canvas: CanvasItem, font: Font, rect: Rect2, text: String, fill: Color, ink: Color
) -> void:
	var width := rect.size.x
	var outline := roundi(width * NUMBER_OUTLINE)
	var font_size := _font_size(font, text, width, outline)
	var baseline := Vector2(rect.position.x, rect.get_center().y + font_size * DIGIT_HEIGHT / 2.0)
	var shadow := baseline + NUMBER_SHADOW * width
	var center := HORIZONTAL_ALIGNMENT_CENTER
	canvas.draw_string_outline(font, shadow, text, center, width, font_size, outline, ink)
	canvas.draw_string(font, shadow, text, center, width, font_size, ink)
	canvas.draw_string_outline(font, baseline, text, center, width, font_size, outline, ink)
	canvas.draw_string(font, baseline, text, center, width, font_size, fill)


## Sayı NUMBER_SIZE boyunda yazılır; kontur dahil alana sığmazsa sığacak kadar küçültülür.
static func _font_size(font: Font, text: String, width: float, outline: int) -> int:
	var font_size := roundi(width * NUMBER_SIZE)
	var text_width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var room := width * (1.0 - NUMBER_MARGIN * 2.0)
	var needed := text_width + outline
	return font_size if needed <= room else floori(font_size * room / needed)
