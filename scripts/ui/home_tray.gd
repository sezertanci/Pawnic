class_name HomeTray
extends RefCounted
## Tahtanın ortasındaki bitiş alanı. Her oyuncunun bitişi, ortadaki küçük kareyi çevreleyen ve
## kendi ev yolunun geldiği kenara oturan bir yamuktur; dört yamuk birlikte alanı doldurur,
## ortadaki karede uygulama simgesindeki P harfi durur. Evdeki taşlar yamukta iki sırada
## dizilir: ilk NEAR_COUNT taş P'ye yakın sırada, kalanlar geniş dış kenardaki sırada; her sıra
## kendi içinde ortalanır.
## Uzunluklar kare boyuna, yerler alanın yarı boyuna oranlanır.

## Ortadaki karenin yarı boyu (alanın yarı boyuna oranla).
const INNER_RATIO := 0.36
## Sıraların iç kenardan uzaklığı (yamuğun derinliğine oranla).
const NEAR_ROW := 0.3
const FAR_ROW := 0.72
## P'ye yakın sıradaki en fazla taş sayısı.
const NEAR_COUNT := 2
## Aynı sıradaki iki taşın merkezleri arası (kare boyuna oranla).
const SPACING := 0.55
## Yamuk dolgusunda oyuncu renginin zemine karışma oranı ve kenar çizgisi kalınlığı.
const FILL_ALPHA := 0.3
const LINE_RATIO := 0.05
## Komşu yamuklar arasındaki boşluk (kare boyuna oranla); her bölge ayrı seçilsin diye.
const GAP_RATIO := 0.06
## Harf görselinin ortadaki kareyi kaplama oranı.
const LETTER_RATIO := 0.9


## Dört yamuğu ve ortadaki P harfini çizer. sides her oyuncunun yamuğunun dışa bakan birim
## yönü, colors aynı sırayla renkleridir.
static func draw(
	canvas: Control,
	area: Rect2,
	sides: Array[Vector2],
	colors: Array[Color],
	skin: BoardSkin,
	cell: float
) -> void:
	for index: int in range(sides.size()):
		var shape := _trapezoid(area, sides[index])
		var points: PackedVector2Array = (
			Geometry2D.offset_polygon(shape, -cell * GAP_RATIO / 2.0)[0]
		)
		var fill := skin.background_color.lerp(colors[index], FILL_ALPHA)
		SmoothDraw.outlined(canvas, points, fill, colors[index], cell * LINE_RATIO)
	if skin.home_letter_texture != null:
		_draw_letter(canvas, area, skin.home_letter_texture)


## Harf görselini, oranını bozmadan ortadaki karenin ortasına sığdırır.
static func _draw_letter(canvas: Control, area: Rect2, texture: Texture2D) -> void:
	var room := area.size.x * INNER_RATIO * LETTER_RATIO
	var size := texture.get_size()
	size *= room / maxf(size.x, size.y)
	canvas.draw_texture_rect(texture, Rect2(area.get_center() - size / 2.0, size), false)


## count taşlık evde index'inci taşın piksel merkezi; side yamuğun dışa bakan birim yönüdür.
static func place(area: Rect2, side: Vector2, index: int, count: int, cell: float) -> Vector2:
	var slot := slot(index, count)
	var half := area.size.x / 2.0
	var inner := half * INNER_RATIO
	var depth := inner + (half - inner) * slot.y
	return area.get_center() + side * depth + side.orthogonal() * slot.x * cell


## count taşlık evde index'inci taşın yeri: x sıra boyunca ortadan uzaklık (kare boyu
## cinsinden), y sıranın iç kenardan uzaklığı (yamuk derinliğine oranla).
static func slot(index: int, count: int) -> Vector2:
	var near := mini(count, NEAR_COUNT)
	if index < near:
		return Vector2(_offset(index, near), NEAR_ROW)
	return Vector2(_offset(index - near, count - near), FAR_ROW)


## size taşlık ortalanmış sırada position'ıncı taşın ortadan uzaklığı (kare boyu cinsinden).
static func _offset(position: int, size: int) -> float:
	return (position - (size - 1) / 2.0) * SPACING


## Alanın side kenarına oturan yamuğun köşeleri: dış kenarın iki ucu, iç karenin iki köşesi.
static func _trapezoid(area: Rect2, side: Vector2) -> PackedVector2Array:
	var center := area.get_center()
	var half := area.size.x / 2.0
	var inner := half * INNER_RATIO
	var across := side.orthogonal()
	return PackedVector2Array(
		[
			center + (side + across) * half,
			center + (side - across) * half,
			center + (side - across) * inner,
			center + (side + across) * inner,
		]
	)
