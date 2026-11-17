class_name PulseWave
extends RefCounted
## Seçilebilir şeyleri gösteren dalga: dipte sabit bir halka (ya da çerçeve) durur, ondan
## dışarı doğru büyüyüp solan ikinci bir halka yayılır. Halkanın dışındaki koyu çizgi onu
## açık renkli zeminde de görünür kılar. Dalganın evresi saatten okunur; çizen düğüm,
## dalga görünürken her karede yeniden çizilmelidir.

## Bir dalganın doğup kaybolma süresi (saniye).
const PERIOD := 1.0
## Dalganın en uzak yeri: halkada yarıçapa, çerçevede kısa kenara oranla.
const SPREAD := 0.6
const MSEC_PER_SEC := 1000.0


## Dalganın 0 (doğuş) ile 1 (kayboluş) arasındaki evresi.
static func phase() -> float:
	return fmod(Time.get_ticks_msec() / MSEC_PER_SEC, PERIOD) / PERIOD


static func draw_ring(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	color: Color,
	edge_color: Color,
	width: float
) -> void:
	var fade := 1.0 - phase()
	var wave_radius := radius * (1.0 + SPREAD * (1.0 - fade))
	_draw_arc(canvas, center, radius, color, edge_color, width, 1.0)
	_draw_arc(canvas, center, wave_radius, color, edge_color, width, fade)


static func draw_frame(
	canvas: CanvasItem, rect: Rect2, color: Color, edge_color: Color, width: float
) -> void:
	var fade := 1.0 - phase()
	var grow := minf(rect.size.x, rect.size.y) * SPREAD / 2.0 * (1.0 - fade)
	_draw_rect(canvas, rect, color, edge_color, width, 1.0)
	_draw_rect(canvas, rect.grow(grow), color, edge_color, width, fade)


static func _draw_arc(
	canvas: CanvasItem,
	center: Vector2,
	radius: float,
	color: Color,
	edge_color: Color,
	width: float,
	alpha: float
) -> void:
	var points := BoardPainter.ARC_POINTS
	var edge := width + BoardPainter.LINE_WIDTH * 2.0
	canvas.draw_arc(center, radius, 0.0, TAU, points, _faded(edge_color, alpha), edge)
	canvas.draw_arc(center, radius, 0.0, TAU, points, _faded(color, alpha), width)


static func _draw_rect(
	canvas: CanvasItem, rect: Rect2, color: Color, edge_color: Color, width: float, alpha: float
) -> void:
	var edge := width + BoardPainter.LINE_WIDTH * 2.0
	canvas.draw_rect(rect, _faded(edge_color, alpha), false, edge)
	canvas.draw_rect(rect, _faded(color, alpha), false, width)


static func _faded(color: Color, alpha: float) -> Color:
	return Color(color, color.a * alpha)
