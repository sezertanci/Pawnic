class_name SeatColors
extends RefCounted
## Koltuk ile renk arasındaki eşleme. Koltuk tahtadaki yerdir (0 üst, 1 sağ, 2 alt, 3 sol),
## renk kaplamadaki renk sırasıdır (0 kırmızı, 1 mavi, 2 yeşil, 3 sarı). Eşleme koltuk
## sırasıyla renkleri tutan bir dizidir; birebir eşlemede her koltuk kendi sırasındaki rengi alır.


## Her koltuğun kendi sırasındaki rengi aldığı eşleme.
static func identity(count: int) -> Array[int]:
	var colors: Array[int] = []
	colors.assign(range(count))
	return colors


## İnsan oyuncu seçtiği rengi alır; öteki koltuklar kalan renkleri renk sırasıyla alır.
## seats oyundaki koltuklardır (sıra düzeninde); önce bunlar, sonra oyunda olmayan koltuklar
## renk alır, böylece eşleme her rengi bir kez içerir.
static func with_choice(count: int, seats: Array[int], human_seat: int, color: int) -> Array[int]:
	var chosen: Dictionary[int, int] = {human_seat: color}
	return with_choices(count, seats, chosen)


## Birden çok oyuncunun seçtiği renkler (koltuk → renk, renkler farklı); öteki koltuklar kalan
## renkleri with_choice'taki sırayla alır.
static func with_choices(count: int, seats: Array[int], chosen: Dictionary[int, int]) -> Array[int]:
	var colors := identity(count)
	var free := identity(count)
	for seat: int in chosen:
		colors[seat] = chosen[seat]
		free.erase(chosen[seat])
	for seat: int in _others(count, seats, chosen.keys()):
		colors[seat] = free.pop_front()
	return colors


## Eşleme count koltuk için her rengi bir kez içeriyorsa true.
static func is_valid(colors: Array[int], count: int) -> bool:
	if colors.size() != count:
		return false
	var sorted := colors.duplicate()
	sorted.sort()
	return sorted == identity(count)


## Renk seçmemiş koltuklar: önce oyundakiler sıra düzeninde, sonra oyunda olmayanlar.
static func _others(count: int, seats: Array[int], chosen: Array[int]) -> Array[int]:
	var others: Array[int] = []
	for seat: int in seats + identity(count):
		if not chosen.has(seat) and not others.has(seat):
			others.append(seat)
	return others
