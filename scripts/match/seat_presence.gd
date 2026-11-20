class_name SeatPresence
extends RefCounted
## Ağ oyununda bağlantısı kopan oyuncuların koltukları. Kopan koltuk bir süre beklenir; süre
## dolunca koltuğu, oyuncu dönene kadar bot oynar. Kalan süre her cihazda kendi saatiyle sayılır;
## an dışarıdan verilir (milisaniye).

## Oyuncu bağlıyken kalan süre yerine verilir.
const PRESENT := -1.0

## Kopan koltuklar: koltuk → botun koltuğu alacağı an.
var _deadlines: Dictionary[int, int] = {}


## Koltuk kopmuş sayılır; seconds saniye sonra koltuğu bot alır.
func mark_away(seat: int, seconds: float, now: int) -> void:
	_deadlines[seat] = now + int(seconds * ClientSource.MSEC_PER_SECOND)


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
	return maxf(0.0, (_deadlines[seat] - now) / ClientSource.MSEC_PER_SECOND)
