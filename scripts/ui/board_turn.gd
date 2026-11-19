class_name BoardTurn
extends RefCounted
## Tahtanın ekranda çeyrek turlarla döndürülmesi: bir koltuğun başlangıç alanı alta gelsin diye
## hücre koordinatları tahtanın ortası çevresinde saat yönünde döndürülür. Dönüş tahtanın
## geometrisinden hesaplanır (koltuğun yeri varsayılmaz). Yalnızca konumlar döner; taşlar, sayılar
## ve tepsiler dik kalır. Kural motoru dönüşü bilmez.

const QUARTER_TURNS := 4
## Hücrenin merkezi (hücre boyuna oranla).
const CELL_CENTER := Vector2(0.5, 0.5)


## Koltuğun başlangıç alanını en alta getiren saat yönündeki çeyrek tur sayısı (0-3).
static func turns_to_bottom(layout: BoardLayout, seat: int) -> int:
	var away := layout.bases[seat] - Vector2(layout.grid_size) / 2.0
	var best := 0
	for turns: int in range(1, QUARTER_TURNS):
		if _rotate(away, turns).y > _rotate(away, best).y:
			best = turns
	return best


## Döndürülmüş tahtanın hücre cinsinden boyu; tek sayıda çeyrek turda en ve boy yer değiştirir.
static func grid(size: Vector2, turns: int) -> Vector2:
	return Vector2(size.y, size.x) if turns % 2 == 1 else size


## Hücre cinsinden bir noktanın döndürülmüş tahtadaki yeri.
static func point(cell: Vector2, size: Vector2, turns: int) -> Vector2:
	return grid(size, turns) / 2.0 + _rotate(cell - size / 2.0, turns)


## Koltuğun başlangıç tepsisinin döndürülmüş tahtadaki merkezi (hücre cinsinden). Tepsiler
## dönmez, hep yatay çizilir; dosyada her köşenin tepsisi kendi kenarına göre ayarlandığından
## tepsi, koltuğun çıkış karesinin döndükten sonra denk geldiği koltuğun dosyadaki tepsi yerine
## konur. Böylece döndürülmüş tahta döndürülmemiş tahtayla aynı görünür. Denk gelen çıkış karesi
## yoksa (tahta bu dönüşte kendisiyle örtüşmüyorsa) tepsinin kendi yeri döndürülür.
static func base_center(layout: BoardLayout, seat: int, turns: int) -> Vector2:
	var size := Vector2(layout.grid_size)
	var start := point(_start_center(layout, seat), size, turns)
	for other: int in range(layout.seat_count()):
		if grid(size, turns) == size and start.is_equal_approx(_start_center(layout, other)):
			return layout.bases[other]
	return point(layout.bases[seat], size, turns)


## Hücre cinsinden bir alanın döndürülmüş tahtadaki karşılığı.
static func rect(area: Rect2, size: Vector2, turns: int) -> Rect2:
	var corner := point(area.position, size, turns)
	return Rect2(corner, Vector2.ZERO).expand(point(area.end, size, turns))


static func _start_center(layout: BoardLayout, seat: int) -> Vector2:
	return Vector2(layout.cells[layout.starts[seat]]) + CELL_CENTER


## Ekranda (y aşağı) saat yönünde çeyrek turlar: yukarı sağa, sağ aşağıya döner.
static func _rotate(vector: Vector2, turns: int) -> Vector2:
	var rotated := vector
	for _turn: int in range(posmod(turns, QUARTER_TURNS)):
		rotated = Vector2(-rotated.y, rotated.x)
	return rotated
