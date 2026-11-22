class_name RewardedUnlock
extends RefCounted
## Kilitli bir seçeneği (tema, tahta) ödüllü reklamla açma akışı. Reklam hazırsa onay katmanında
## izleme onayı sorulur; onaylanırsa reklam gösterilir ve ödül verilirse istekteki işlev çağrılır.
## Reklam hazır değilse yalnızca bilgi verilir. Reklamın sonucu beklenirken yeni istek yok sayılır.

const AD_NOT_READY_KEY := "AD_NOT_READY"
const WATCH_KEY := "WATCH_AD"
const CANCEL_KEY := "CANCEL"
const OK_KEY := "OK"

var _confirm: ConfirmOverlay
var _placement: String
var _ask_key: String
## Onay bekleyen isteğin ödülde çağrılacak işlevi; bilgi iletisinde boştur.
var _on_granted := Callable()
var _watching := false


func _init(confirm: ConfirmOverlay, placement: String, ask_key: String) -> void:
	_confirm = confirm
	_placement = placement
	_ask_key = ask_key
	_confirm.confirmed.connect(_watch)


## Açma isteği; ödül verilirse on_granted çağrılır.
func request(on_granted: Callable) -> void:
	if _watching:
		return
	if not Ads.is_rewarded_ready():
		_on_granted = Callable()
		_confirm.ask(AD_NOT_READY_KEY, OK_KEY)
		return
	_on_granted = on_granted
	_confirm.ask(_ask_key, WATCH_KEY, CANCEL_KEY, false)


func _watch() -> void:
	var on_granted := _on_granted
	_on_granted = Callable()
	if not on_granted.is_valid() or _watching:
		return
	_watching = true
	Ads.show_rewarded(_placement)
	var result: Array = await Ads.rewarded_completed
	while result[0] != _placement:
		result = await Ads.rewarded_completed
	_watching = false
	var granted: bool = result[1]
	if granted:
		on_granted.call()
