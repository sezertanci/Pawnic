class_name SeatPresence
extends RefCounted
## Ağ oyununda bağlantısı kopan oyuncuların koltukları. Kopan koltuk bir süre beklenir; süre
## dolunca koltuğu, oyuncu dönene kadar bot oynar. Kalan süre her cihazda kendi saatiyle sayılır;
## an dışarıdan verilir (milisaniye). Molada süreler donar: molada kopan koltuğun süresi devamda
## baştan başlar, moladan önce kopanın süresi kaldığı yerden sürer.

## Oyuncu bağlıyken kalan süre yerine verilir.
const PRESENT := -1.0
## Süreler donmamışken donma anı yerine kullanılır.
const NOT_FROZEN := -1

## Kopan koltuklar: koltuk → botun koltuğu alacağı an.
var _deadlines: Dictionary[int, int] = {}
## Sürelerin donduğu an; donmamışsa NOT_FROZEN.
var _frozen_at := NOT_FROZEN


## Koltuk kopmuş sayılır; seconds saniye sonra koltuğu bot alır.
func mark_away(seat: int, seconds: float, now: int) -> void:
	_deadlines[seat] = _now(now) + int(seconds * ClientSource.MSEC_PER_SECOND)


## Koltuğun oyuncusu bağlı sayılır; koltuk kopmuş sayılıyorduysa true.
func mark_present(seat: int) -> bool:
	return _deadlines.erase(seat)


func is_away(seat: int) -> bool:
	return _deadlines.has(seat)


## Kopmuş sayılan koltuklar.
func away_seats() -> Array[int]:
	return _deadlines.keys()


## Koltuğu bot alana kadar kalan saniye; süre dolduysa 0, oyuncu bağlıysa PRESENT.
func wait_left(seat: int, now: int) -> float:
	if not _deadlines.has(seat):
		return PRESENT
	return maxf(0.0, (_deadlines[seat] - _now(now)) / ClientSource.MSEC_PER_SECOND)


## Bütün süreler durur; zaten donmuşsa bir şey değişmez.
func freeze(now: int) -> void:
	if _frozen_at == NOT_FROZEN:
		_frozen_at = now


## Süreler, donuk kaldıkları süre kadar ileri kayarak kaldıkları yerden sürer.
func thaw(now: int) -> void:
	if _frozen_at == NOT_FROZEN:
		return
	var shift := now - _frozen_at
	for seat: int in _deadlines:
		_deadlines[seat] += shift
	_frozen_at = NOT_FROZEN


## Sürelerin sayıldığı an: donmuşsa donma anı.
func _now(now: int) -> int:
	return now if _frozen_at == NOT_FROZEN else _frozen_at
