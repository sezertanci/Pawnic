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


## Kare dokusunu verilen renge boyayarak çizer. Dokunun alt kalınlığı hariç yüzün yerini döner.
static func draw_tile(canvas: CanvasItem, rect: Rect2, texture: Texture2D, tint: Color) -> Rect2:
	canvas.draw_texture_rect(texture, rect, false, tint)
	var depth := rect.size.y * Skins.current.square_depth
	return Rect2(rect.position, rect.size - Vector2(0.0, depth))


## Koltuğun taş görselini, ayağı verilen merkeze basacak biçimde çizer.
static func draw_pawn(canvas: CanvasItem, center: Vector2, radius: float, seat: int) -> void:
	var texture := Skins.current.pawn_textures[seat]
	var width := radius * PAWN_WIDTH_RATIO
	var size := Vector2(width, width * texture.get_height() / texture.get_width())
	var origin := center - Vector2(size.x / 2.0, size.y * PAWN_FOOT)
	canvas.draw_texture_rect(texture, Rect2(origin, size), false)
