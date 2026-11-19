class_name BoardPainter
extends RefCounted
## Tahtadaki kare ve taş dokularını çizer; tahta ve ana ekrandaki logo halkası ortak kullanır.
## Dokular ve oranlar seçili kaplamadan (Skins.current) okunur.

const LINE_WIDTH := 2.0
const ARC_POINTS := 24
## Taş görselinin genişliği, taş yarıçapına oranla.
const PAWN_WIDTH_RATIO := 2.4
## Taşın yere bastığı noktanın görselin üstünden uzaklığı (görsel boyuna oranla).
const PAWN_FOOT := 0.72
## Taş görselinin altındaki taban elipsinin merkezi (görsel boyuna oranla), yarı genişliği
## (görsel genişliğine oranla) ve basıklığı (yüksekliğin genişliğe oranı); görselden ölçülmüştür.
const PAWN_BASE_CENTER := 0.77
const PAWN_BASE_HALF := 0.49
const PAWN_BASE_FLATTEN := 0.6


## Kare dokusunu verilen renge boyayarak çizer ve yüzünün yerini döner.
static func draw_tile(canvas: CanvasItem, rect: Rect2, texture: Texture2D, tint: Color) -> Rect2:
	canvas.draw_texture_rect(texture, rect, false, tint)
	return face_rect(rect)


## Karenin üst kenarı ve alt kalınlığı hariç, işaretlerin ve taşların durduğu yüz.
static func face_rect(rect: Rect2) -> Rect2:
	var top := rect.size.y * Skins.current.square_top
	var depth := rect.size.y * Skins.current.square_depth
	return Rect2(rect.position + Vector2(0.0, top), rect.size - Vector2(0.0, top + depth))


## Verilen renkteki (kaplamadaki renk sırası) taş görselini, ayağı verilen merkeze basacak
## biçimde çizer.
static func draw_pawn(canvas: CanvasItem, center: Vector2, radius: float, color: int) -> void:
	var texture := Skins.current.pawn_textures[color]
	var width := radius * PAWN_WIDTH_RATIO
	var size := Vector2(width, width * aspect(texture))
	var origin := center - Vector2(size.x / 2.0, size.y * PAWN_FOOT)
	canvas.draw_texture_rect(texture, Rect2(origin, size), false)


## Taşı, ayağındaki yere yatık halkanın arka yarısı taşın arkasında, ön yarısı önünde
## kalacak biçimde çizer. draw_ring halkanın açı aralığını (PulseWave.BACK_ARC ya da
## FRONT_ARC) alıp o parçayı çizer.
static func draw_pawn_in_ring(
	canvas: CanvasItem, center: Vector2, radius: float, color: int, draw_ring: Callable
) -> void:
	draw_ring.call(PulseWave.BACK_ARC)
	draw_pawn(canvas, center, radius, color)
	draw_ring.call(PulseWave.FRONT_ARC)


## Görselin yüksekliğinin genişliğine oranı.
## Taşın tabanıyla aynı eğimde yatık elips: ayağı center'a basan taşın tabanı ortasına oturur,
## scale tabanın kaç katı genişlikte olacağıdır (başlangıç tepsisindeki altlıklar için).
static func base_ellipse(center: Vector2, radius: float, scale: float) -> PackedVector2Array:
	var width := radius * PAWN_WIDTH_RATIO
	var height := width * aspect(Skins.current.pawn_textures[0])
	var middle := center + Vector2.DOWN * height * (PAWN_BASE_CENTER - PAWN_FOOT)
	var half := width * PAWN_BASE_HALF * scale
	var points := SmoothDraw.arc_points(Vector2.ZERO, half, 0.0, TAU, ARC_POINTS * 2)
	points.remove_at(points.size() - 1)
	for index: int in range(points.size()):
		points[index] = middle + points[index] * Vector2(1.0, PAWN_BASE_FLATTEN)
	return points


static func aspect(texture: Texture2D) -> float:
	return float(texture.get_height()) / texture.get_width()
