class_name BoardPainter
extends RefCounted
## Tahtadaki kabarık kare ve taş çizimleri; tahta, ana ekran arka planı ve logo ortak kullanır.
## Renkler ve oranlar seçili kaplamadan (Skins.current) okunur.

const LINE_WIDTH := 2.0
const ARC_POINTS := 24
const SHINE_OFFSET := Vector2(-0.3, -0.3)
const SHINE_RATIO := 0.35


## Kareyi kabarık çizer: altta koyu kenar şeridi, üstünde yüzü. Yüzün yerini döner.
static func draw_tile(canvas: CanvasItem, rect: Rect2, color: Color) -> Rect2:
	var skin := Skins.current
	var depth := rect.size.y * skin.square_depth
	var edge := color.darkened(skin.edge_darken)
	edge.a = color.a
	canvas.draw_rect(rect, edge)
	var face := Rect2(rect.position, rect.size - Vector2(0.0, depth))
	canvas.draw_rect(face, color)
	return face


## Taşı kalınlığı (koyu alt kenar), çerçevesi ve parıltısıyla çizer.
static func draw_pawn(canvas: CanvasItem, center: Vector2, radius: float, color: Color) -> void:
	var skin := Skins.current
	var base := center + Vector2.DOWN * radius * skin.pawn_depth
	canvas.draw_circle(base, radius, color.darkened(skin.edge_darken))
	canvas.draw_arc(base, radius, 0.0, TAU, ARC_POINTS, skin.outline_color, LINE_WIDTH)
	canvas.draw_circle(center, radius, color)
	canvas.draw_arc(center, radius, 0.0, TAU, ARC_POINTS, skin.outline_color, LINE_WIDTH)
	canvas.draw_circle(center + SHINE_OFFSET * radius, radius * SHINE_RATIO, skin.shine_color)
