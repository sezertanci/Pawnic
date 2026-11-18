class_name BasePainter
extends RefCounted
## Oyuncunun başlangıç alanını cam panel olarak çizer: yuvarlak köşeli, yukarıdan aşağıya
## açılan yarı saydam zemin, ince açık renkli kenar ve alt kenarın
## kavislerinden yansıyan yumuşak ışık.
## Uzunluklar kare boyuna oranlanır, renkler oyuncu renginden türetilir.

## Panelin köşe yuvarlaklığı.
const CORNER_RATIO := 0.25
## Üst tonun koyulaşma, alt tonun açılma oranı ve saydamlıkları.
const DARKEN := 0.25
const LIGHTEN := 0.25
const TOP_ALPHA := 0.25
const BOTTOM_ALPHA := 0.5
## Kenar çizgisinin saydamlığı ve kalınlığı.
const EDGE_ALPHA := 0.6
const LINE_RATIO := 0.03
## Işığın kenardan uzaklığı, içe doğru solan bandın genişliği ve dışa doğru yumuşak kenarı.
const SHINE_INSET := 0.08
const SHINE_BAND := 0.16
const SHINE_FEATHER := 0.03
## Işığın en parlak yerdeki (alt kenarın ortası) saydamlığı; uçlara doğru sıfıra iner.
const SHINE_ALPHA := 1.0
## Işığın dışındaki koyu çerçeve: zeminin açıklığı HALO_FROM'u geçince başlar, HALO_RANGE
## kadar fazlasında HALO_ALPHA saydamlığıyla tam güce ulaşır. Işığın bittiği yerde en koyudur,
## dışa doğru HALO_OUTSET genişliğinde solar.
const HALO_FROM := 0.62
const HALO_RANGE := 0.15
const HALO_ALPHA := 0.55
const HALO_OUTSET := 0.05


static func draw_base(canvas: CanvasItem, rect: Rect2, color: Color, cell: float) -> void:
	var radius := cell * CORNER_RATIO
	var line := cell * LINE_RATIO
	var outline := SmoothDraw.rounded_rect(rect, radius)
	var top := Color(color.darkened(DARKEN), TOP_ALPHA)
	var bottom := Color(color.lightened(LIGHTEN), BOTTOM_ALPHA)
	var colors := PackedColorArray()
	for point: Vector2 in outline:
		colors.append(top.lerp(bottom, (point.y - rect.position.y) / rect.size.y))
	canvas.draw_polygon(outline, colors)
	var edge := outline.duplicate()
	edge.append(outline[0])
	canvas.draw_polyline(edge, Color(color.lightened(LIGHTEN), EDGE_ALPHA), line, true)
	_draw_shine(canvas, rect, radius, cell, bottom)


## Alt kenarı, iki alt köşenin kavisleriyle birlikte biraz içeriden izleyen ışık şeridi
## (sağ kavis -> alt kenar -> sol kavis). Ortada en parlaktır, kavislerin üst uçlarına doğru
## söner; enine de yoldan içeriye doğru geniş, dışarıya doğru dar bir geçişle solar.
## Açık renkli zeminde beyaz ışık seçilsin diye ışığın dış kenarına, zeminin açıklığıyla
## güçlenen ince koyu bir çerçeve çizilir; beyazın solan kısmının altına girmez.
static func _draw_shine(
	canvas: CanvasItem, rect: Rect2, radius: float, cell: float, ground: Color
) -> void:
	var inset := cell * SHINE_INSET
	var inner := rect.grow(-inset)
	var arc := radius - inset
	var right := inner.end - Vector2(arc, arc)
	var left := Vector2(inner.position.x + arc, inner.end.y - arc)
	var path := SmoothDraw.arc_points(right, arc, 0.0, PI / 2.0)
	path.append_array(SmoothDraw.arc_points(left, arc, PI / 2.0, PI))
	var inward := PackedVector2Array()
	for index: int in range(path.size()):
		var center := right if index <= SmoothDraw.ARC_POINTS else left
		inward.append((center - path[index]).normalized())
	var halo := clampf((ground.get_luminance() - HALO_FROM) / HALO_RANGE, 0.0, 1.0)
	var feather := cell * SHINE_FEATHER
	if halo > 0.0:
		var rim := PackedVector2Array()
		for index: int in range(path.size()):
			rim.append(path[index] - inward[index] * feather)
		var dark := Color(Color.BLACK, HALO_ALPHA * halo)
		_draw_glow(canvas, rim, inward, dark, cell * HALO_OUTSET, feather)
	var white := Color(Color.WHITE, SHINE_ALPHA)
	_draw_glow(canvas, path, inward, white, feather, cell * SHINE_BAND)


## Yol boyunca uzanan, ortasında color tonunda olup uçlara doğru sönen yumuşak şerit. Yoldan
## dışarıya outset, içeriye band genişliğinde saydamlaşarak solar.
static func _draw_glow(
	canvas: CanvasItem,
	path: PackedVector2Array,
	inward: PackedVector2Array,
	color: Color,
	outset: float,
	band: float
) -> void:
	var progress := SmoothDraw.path_progress(path)
	var outer := PackedVector2Array()
	var inner := PackedVector2Array()
	var lit := PackedColorArray()
	var clear := PackedColorArray()
	for index: int in range(path.size()):
		outer.append(path[index] - inward[index] * outset)
		inner.append(path[index] + inward[index] * band)
		lit.append(Color(color, color.a * sin(PI * progress[index])))
		clear.append(Color(color, 0.0))
	SmoothDraw.ribbon(canvas, outer, path, clear, lit)
	SmoothDraw.ribbon(canvas, path, inner, lit, clear)
