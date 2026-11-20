class_name PeerWatch
extends RefCounted
## Eşlerin son duyulduğu anı izler ve yoklama (HEARTBEAT) zamanını söyler. Zaman dışarıdan
## verilir (milisaniye), böylece testte sahte saatle sürülür. İki güncelleme arasında sessizlik
## sınırından uzun süre geçtiyse bu cihaz durmuştur (uygulama arka plandaydı); o süre eşlerin
## sessizliğine sayılmaz, yoksa dönen cihaz herkesi uzakta sanır.

## Henüz güncelleme ya da yoklama yokken an yerine kullanılır.
const NEVER := -1

var _interval: int
var _limit: int
## Eşlerin son duyulduğu an: eş numarası → an.
var _heard: Dictionary[int, int] = {}
var _last_update := NEVER
var _last_beat := NEVER


func _init(settings: GameSettings) -> void:
	_interval = settings.heartbeat_interval_ms
	_limit = settings.silence_limit_ms


## Eşten mesaj geldi.
func heard(peer_id: int, now: int) -> void:
	_heard[peer_id] = now


## Eş artık izlenmez (bağlantısı kapandı).
func forget(peer_id: int) -> void:
	_heard.erase(peer_id)


## Zamanı ilerletir; yoklama gönderme zamanı geldiyse true.
func update(now: int) -> bool:
	if _last_update != NEVER and now - _last_update > _limit:
		var paused := now - _last_update
		for peer_id: int in _heard:
			_heard[peer_id] += paused
	_last_update = now
	if _last_beat != NEVER and now - _last_beat < _interval:
		return false
	_last_beat = now
	return true


## İzlenen eşten sessizlik sınırından uzun süredir mesaj gelmediyse true.
func is_silent(peer_id: int, now: int) -> bool:
	return _heard.has(peer_id) and now - _heard[peer_id] > _limit
