extends SceneTree
## Dört yaprak tahtasının dosyasını (data/boards/four_leaf.json) üretir. Halka, dört yaprak gibi
## dışa çıkan bir eğri üzerinde eşit aralıklı çember karelerdir; ev yolları yaprak uçlarından
## düz olarak yuvarlak merkeze iner, tepsiler yapraklar arasındaki girintilerde durur. Özel
## kareler klasik tahtadaki sırayla dizilir. Tahta değişince bu dosyadaki sabitler
## değiştirilip araç yeniden çalıştırılır.
## Çalıştırma: godot --headless --path . -s tools/make_four_leaf.gd

const OUTPUT := "res://data/boards/four_leaf.json"
const SEATS := 4
const RING_SQUARES := 56
const LANE_SQUARES := 6
## Halka eğrisi: r = 1 + LEAF_DEPTH·cos(LEAVES·t). t üstten başlayıp ekranda saat yönünde
## ilerler.
const LEAF_DEPTH := 0.3
const LEAVES := 4
const CURVE_SAMPLES := 4000
## İki halka karesinin merkezleri arasındaki uzaklık (hücre); kare bir hücre boyundadır. Ev
## yolundaki kareler de aynı aralıkla dizilir.
const RING_STEP := 1.08
## Yuvarlak merkez alanı, ev yolunun ona değen karesine (sondan bir önceki kare) yapboz
## parçası gibi içe doğru bir yuva açar: dış çember o karenin merkezinden geçer, yuva kareden
## SOCKET_GAP (hücre) kadar geniştir. Çember yayları ve yuvalar ARC_POINTS noktayla çizilir.
const SOCKET_GAP := 0.1
const ARC_POINTS := 16
## Dönen ok, merkez alanıyla ona en yakın halka karesinin iç kenarı arasındaki boşluğun ortasından
## geçer.
const SPINNER_GAP_SHARE := 0.5
## Tepsiler koltuk sırasındaki çapraz yönlerde (saat yönünde, üst sağdan başlayarak), yapraklar
## arasındaki girintide halkaya BASE_GAP (hücre) kadar yaklaşan yer BASE_SEARCH adımıyla aranır;
## tepsi bu yerle tahtanın köşesi arasında BASE_CORNER_SHARE oranındaki yerde durur.
const BASE_GAP := 0.3
const BASE_CORNER_SHARE := 0.5
const BASE_SEARCH := 0.01
const BASE_DIRECTIONS: Array[Vector2] = [
	Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1), Vector2(-1, -1)
]
## Tepsinin yarı boyu (hücre); tahta boyu tepsileri de kapsar.
const BASE_HALF := Vector2(1.43, 0.95)
## Kısayol karesine göre özel karelerin uzaklığı ve klasik tahtadaki hız sırası.
const START_OFFSET := 1
const SAFE_OFFSETS: Array[int] = [1, 8]
const SPEED_OFFSETS: Array[int] = [4, 11]
const SPEEDS: Array[int] = [6, -3, 3, -1, -4, 5, -2, 4]
## Dosyaya yazılan sayıların ondalık basamağı.
const DECIMALS := 2


func _initialize() -> void:
	var ring := _ring_points()
	var step := ring[1].distance_to(ring[0])
	var scale := RING_STEP / step
	for index: int in range(ring.size()):
		ring[index] *= scale
	var lanes: Array[PackedVector2Array] = []
	for seat: int in range(SEATS):
		lanes.append(_lane(ring[seat * _quarter()]))
	var low := _low_corner(ring)
	var high := _high_corner(ring)
	var bases: Array[Vector2] = []
	for seat: int in range(SEATS):
		bases.append(_base(ring, BASE_DIRECTIONS[seat], low, high))
	var sockets := _socket_centers(lanes)
	var radius := sockets[0].length()
	var drawing := {"center": _center(sockets), "spinner_ratio": _spinner_ratio(ring, radius)}
	var text := _board_text(ring, lanes, bases, drawing, low, high - low)
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	file.store_string(text)
	file.close()
	print("Yazıldı: %s" % OUTPUT)
	quit()


func _quarter() -> int:
	return RING_SQUARES / SEATS


## Eğri üzerinde yay uzunluğuna göre eşit aralıklı halka kare merkezleri (eğri birimiyle).
func _ring_points() -> PackedVector2Array:
	var samples := PackedVector2Array()
	for index: int in range(CURVE_SAMPLES + 1):
		var angle := -PI / 2.0 + TAU * index / CURVE_SAMPLES
		var radius := 1.0 + LEAF_DEPTH * cos(LEAVES * angle)
		samples.append(Vector2.from_angle(angle) * radius)
	var lengths: Array[float] = [0.0]
	for index: int in range(1, samples.size()):
		lengths.append(lengths[index - 1] + samples[index].distance_to(samples[index - 1]))
	var total: float = lengths.back()
	var result := PackedVector2Array()
	var cursor := 0
	for square: int in range(RING_SQUARES):
		var wanted := square * total / RING_SQUARES
		while lengths[cursor + 1] < wanted:
			cursor += 1
		result.append(samples[cursor])
	return result


## Yaprak ucundan merkeze doğru düz inen ev yolunun kare merkezleri (hücre).
func _lane(entry: Vector2) -> PackedVector2Array:
	var direction := -entry.normalized()
	var result := PackedVector2Array()
	for square: int in range(1, LANE_SQUARES + 1):
		result.append(entry + direction * RING_STEP * square)
	return result


## Tepsinin merkezi (hücre): girintideki yerle tahtanın direction köşesine sığan yer arasında.
func _base(ring: PackedVector2Array, direction: Vector2, low: Vector2, high: Vector2) -> Vector2:
	var valley := _base_in_valley(ring, direction.normalized())
	var corner_x := high.x - BASE_HALF.x if direction.x > 0.0 else low.x + BASE_HALF.x
	var corner_y := high.y - BASE_HALF.y if direction.y > 0.0 else low.y + BASE_HALF.y
	return valley.lerp(Vector2(corner_x, corner_y), BASE_CORNER_SHARE)


## Başlangıç karesinin halka eğrisine dik, dışa bakan birim yönü; patika kareye bu yönden varır.
func _approach(ring: PackedVector2Array, seat: int) -> Vector2:
	var index := seat * _quarter() + START_OFFSET
	var along := ring[(index + 1) % RING_SQUARES] - ring[index - 1]
	var normal := along.orthogonal().normalized()
	return -normal if normal.dot(ring[index]) < 0.0 else normal


## direction yönünde dışarıdan ortaya doğru ilerlerken tepsinin halka karelerinden BASE_GAP
## kadar uzak kaldığı son yer (hücre).
func _base_in_valley(ring: PackedVector2Array, direction: Vector2) -> Vector2:
	var distance := _high_corner(ring).length() + BASE_HALF.length()
	while _base_clear(ring, direction * (distance - BASE_SEARCH)):
		distance -= BASE_SEARCH
	return direction * distance


## Tepsi center'dayken her halka karesinin (yarım hücre) tepsiye uzaklığı BASE_GAP'ten büyük mü.
func _base_clear(ring: PackedVector2Array, center: Vector2) -> bool:
	var area := Rect2(center - BASE_HALF, BASE_HALF * 2.0)
	for point: Vector2 in ring:
		var nearest := point.clamp(area.position, area.end)
		if nearest.distance_to(point) < 0.5 + BASE_GAP:
			return false
	return true


## Merkez alanına değen ev yolu karelerinin merkezleri (hücre); yuvalar bunların çevresine açılır.
func _socket_centers(lanes: Array[PackedVector2Array]) -> Array[Vector2]:
	var result: Array[Vector2] = []
	for lane: PackedVector2Array in lanes:
		result.append(lane[LANE_SQUARES - 2])
	return result


## Yuvanın yarıçapı (hücre): kare yarım hücredir, çevresinde SOCKET_GAP kadar boşluk kalır.
func _socket_radius() -> float:
	return 0.5 + SOCKET_GAP


## Yuvalı merkez alanının çizgisi (hücre): her yuvadan sonrakine çember yayı, yuvada içe dönen
## yay. Yuvalar saat yönünde sıralıdır.
func _center(sockets: Array[Vector2]) -> PackedVector2Array:
	var radius := sockets[0].length()
	var opening := 2.0 * asin(_socket_radius() / (2.0 * radius))
	var result := PackedVector2Array()
	for index: int in range(sockets.size()):
		var here := sockets[index].angle()
		var turn := fposmod(sockets[(index + 1) % sockets.size()].angle() - here, TAU)
		result.append_array(
			SmoothDraw.arc_points(Vector2.ZERO, radius, here + opening, here + turn - opening)
		)
		result.append_array(_socket_arc(sockets[(index + 1) % sockets.size()], opening))
	return result


## Yuva yayı: çemberin yuva kenarındaki iki noktası arasında, yuva merkezinin çevresinden içe
## doğru dolanan noktalar (hücre).
func _socket_arc(socket: Vector2, opening: float) -> PackedVector2Array:
	var axis := socket.angle()
	var radius := socket.length()
	var first := (Vector2.from_angle(axis - opening) * radius - socket).angle()
	var sweep := fposmod(
		(Vector2.from_angle(axis + opening) * radius - socket).angle() - first, TAU
	)
	if cos(first + sweep / 2.0 - (axis + PI)) < 0.0:
		sweep -= TAU
	var arc := SmoothDraw.arc_points(socket, _socket_radius(), first, first + sweep)
	return arc.slice(1, arc.size() - 1)


## Dönen okun yarıçapının, ortadan yuva dibine uzaklığa oranı; ok, çember ile ona en yakın halka
## karesinin iç kenarı arasındaki boşluktan geçer.
func _spinner_ratio(ring: PackedVector2Array, radius: float) -> float:
	var nearest := INF
	for point: Vector2 in ring:
		nearest = minf(nearest, point.length() - 0.5)
	return (radius + (nearest - radius) * SPINNER_GAP_SHARE) / (radius - _socket_radius())


## Halka karelerini (merkezden yarım hücre) kapsayan alanın sol üst köşesi; tepsiler bu alanın
## içinde durur.
func _low_corner(ring: PackedVector2Array) -> Vector2:
	var low := Vector2.INF
	for point: Vector2 in ring:
		low = low.min(point - Vector2.ONE / 2.0)
	return low


func _high_corner(ring: PackedVector2Array) -> Vector2:
	var high := -Vector2.INF
	for point: Vector2 in ring:
		high = high.max(point + Vector2.ONE / 2.0)
	return high


func _board_text(
	ring: PackedVector2Array,
	lanes: Array[PackedVector2Array],
	bases: Array[Vector2],
	drawing: Dictionary,
	low: Vector2,
	size: Vector2
) -> String:
	var shift := -low
	var lines: Array[String] = ["{", '\t"square_shape": "circle",']
	lines.append('\t"size": %s,' % _point(size))
	lines.append('\t"center": %s,' % _points(drawing["center"], shift))
	lines.append('\t"spinner_ratio": %s,' % String.num(drawing["spinner_ratio"], DECIMALS))
	lines.append('\t"paths": [')
	var paths: Array[String] = [_path("ring", ring, shift, '"loop": true')]
	for seat: int in range(SEATS):
		paths.append(_path("lane%d" % seat, lanes[seat], shift, '"owner": %d' % seat))
	lines.append(",\n".join(paths))
	lines.append("\t],")
	lines.append('\t"links": [')
	var links: Array[String] = []
	for seat: int in range(SEATS):
		var link := '\t\t{ "from": "%s", "to": "lane%d:0", "seats": [%d], "mode": "forced" }'
		links.append(link % [_ring_name(seat, 0), seat, seat])
	lines.append(",\n".join(links))
	lines.append("\t],")
	lines.append('\t"safe": [%s],' % ", ".join(_special_names(SAFE_OFFSETS)))
	lines.append('\t"speed": { %s },' % ", ".join(_speed_entries()))
	lines.append('\t"seats": [')
	lines.append(",\n".join(_seat_lines(ring, bases, shift)))
	lines.append("\t]")
	lines.append("}")
	return "\n".join(lines) + "\n"


func _path(id: String, points: PackedVector2Array, shift: Vector2, extra: String) -> String:
	return '\t\t{ "id": "%s", "squares": %s, %s }' % [id, _points(points, shift, true), extra]


## Kare merkezleri sol üst köşeye çevrilir (corner true) ya da çizgi noktası olarak kalır.
func _points(points: PackedVector2Array, shift: Vector2, corner := false) -> String:
	var parts: Array[String] = []
	var offset := shift - (Vector2.ONE / 2.0 if corner else Vector2.ZERO)
	for point: Vector2 in points:
		parts.append(_point(point + offset))
	return "[%s]" % ", ".join(parts)


func _point(point: Vector2) -> String:
	return "[%s, %s]" % [String.num(point.x, DECIMALS), String.num(point.y, DECIMALS)]


func _ring_name(seat: int, offset: int) -> String:
	return "ring:%d" % posmod(seat * _quarter() + offset, RING_SQUARES)


func _special_names(offsets: Array[int]) -> Array[String]:
	var names: Array[String] = []
	for seat: int in range(SEATS):
		for offset: int in offsets:
			names.append('"%s"' % _ring_name(seat, offset))
	return names


func _speed_entries() -> Array[String]:
	var entries: Array[String] = []
	var names := _special_names(SPEED_OFFSETS)
	for index: int in range(names.size()):
		entries.append("%s: %d" % [names[index], SPEEDS[index]])
	return entries


## Koltuk satırları; approach bir yön olduğu için kaydırılmaz.
func _seat_lines(ring: PackedVector2Array, bases: Array[Vector2], shift: Vector2) -> Array[String]:
	var result: Array[String] = []
	for seat: int in range(SEATS):
		var line := '\t\t{ "start": "%s", "home": "lane%d:%d", "shortcut": "%s", "base": %s, '
		line += '"approach": %s }'
		var start := _ring_name(seat, START_OFFSET)
		var home := LANE_SQUARES - 1
		var base := _point(bases[seat] + shift)
		var approach := _point(_approach(ring, seat))
		result.append(line % [start, seat, home, _ring_name(seat, 0), base, approach])
	return result
