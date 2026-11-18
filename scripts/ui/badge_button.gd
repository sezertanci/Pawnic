class_name BadgeButton
extends WideButton
## Ana ekran düğmesi: dokusunun solundaki yuvarlağın içine seçilen simgeyi çizer.
## Simgenin yeri ve boyu düğme yüksekliğine oranla verilir.

enum Symbol { PLAY, PLUS, QUESTION, HOME }

## Yuvarlağın merkezi ve simgenin yarı boyu (düğme yüksekliğine oranla).
const BADGE_CENTER := Vector2(0.43, 0.41)
const SYMBOL_RATIO := 0.15
const SYMBOL_COLOR := Color.WHITE
const OUTLINE_WIDTH := 4.0
## Oynat üçgeninin köşeleri (yarı boya oranla, merkez sıfırda).
const PLAY_POINTS: Array[Vector2] = [Vector2(-0.6, -0.9), Vector2(0.9, 0.0), Vector2(-0.6, 0.9)]
## Artı kollarının kalınlığı (yarı boya oranla).
const PLUS_THICKNESS := 0.55
## Soru işaretinin yazı boyu (yarı boya oranla).
const QUESTION_SIZE := 2.6
const QUESTION_TEXT := "?"

@export var symbol := Symbol.PLAY


func _draw() -> void:
	var center := BADGE_CENTER * size.y
	var half := size.y * SYMBOL_RATIO
	match symbol:
		Symbol.PLAY:
			_draw_play(center, half)
		Symbol.PLUS:
			_draw_plus(center, half)
		Symbol.QUESTION:
			_draw_question(center, half)
		Symbol.HOME:
			_draw_home(center, half)


func _draw_play(center: Vector2, half: float) -> void:
	var points := PackedVector2Array()
	for point: Vector2 in PLAY_POINTS:
		points.append(center + point * half)
	draw_colored_polygon(points, SYMBOL_COLOR)
	points.append(points[0])
	draw_polyline(points, Skins.current.outline_color, OUTLINE_WIDTH)


## Artı: önce koyu kenarlı kollar, sonra üstüne beyaz kollar.
func _draw_plus(center: Vector2, half: float) -> void:
	var arm := half * PLUS_THICKNESS
	var bars: Array[Rect2] = [
		Rect2(center - Vector2(half, arm / 2.0), Vector2(half * 2.0, arm)),
		Rect2(center - Vector2(arm / 2.0, half), Vector2(arm, half * 2.0)),
	]
	for bar: Rect2 in bars:
		draw_rect(bar.grow(OUTLINE_WIDTH / 2.0), Skins.current.outline_color)
	for bar: Rect2 in bars:
		draw_rect(bar, SYMBOL_COLOR)


func _draw_home(center: Vector2, half: float) -> void:
	var bounds := Rect2(center - Vector2(half, half), Vector2(half, half) * 2.0)
	CardSymbol.draw_house(self, bounds, SYMBOL_COLOR, Skins.current.outline_color, OUTLINE_WIDTH)


func _draw_question(center: Vector2, half: float) -> void:
	var font := get_theme_font(ThemeKeys.FONT)
	var font_size := roundi(half * QUESTION_SIZE)
	var text_size := font.get_string_size(QUESTION_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var baseline := (
		center + Vector2(-text_size.x / 2.0, font.get_ascent(font_size) - text_size.y / 2.0)
	)
	var outline := roundi(OUTLINE_WIDTH * 2.0)
	draw_string_outline(
		font,
		baseline,
		QUESTION_TEXT,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		outline,
		Skins.current.outline_color
	)
	draw_string(
		font, baseline, QUESTION_TEXT, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, SYMBOL_COLOR
	)
