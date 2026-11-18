class_name ButtonFace
extends RefCounted
## Düğme üstüne çizilen simgeler için düğmenin o anki yüzü: kabarık alt kenar şeridi çıkarılmış
## alan ve o anki stil. Basılıyken şerit incelir ve yüz aşağı uzar, simge de yüzle birlikte iner.

const NORMAL_STYLE := &"normal"
const PRESSED_STYLE := &"pressed"


## Düğmenin o anki (normal ya da basılı) stili; düz renkli bir stil değilse null.
static func style(button: Button) -> StyleBoxFlat:
	var mode := button.get_draw_mode()
	var pressed := mode == BaseButton.DRAW_PRESSED or mode == BaseButton.DRAW_HOVER_PRESSED
	return button.get_theme_stylebox(PRESSED_STYLE if pressed else NORMAL_STYLE) as StyleBoxFlat


static func rect(button: Button) -> Rect2:
	var face := Rect2(Vector2.ZERO, button.size)
	var current := style(button)
	if current != null:
		face.size.y -= current.border_width_bottom
	return face
