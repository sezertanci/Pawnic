class_name SkinScreen
extends Control
## Görünüm ekranı: her tahta teması için tahta görselli büyük bir kart, alt alta ve kaydırılarak.
## Karta dokununca tema hemen uygulanır ve kaydedilir; ekranda kalınır, geri okla dönülür.
## Kilitli temanın kartına dokununca ödüllü reklam izleme onayı sorulur; reklam ödülü verirse
## kilit kalıcı olarak kalkar ve tema seçilir. Reklam hazır değilse yalnızca bilgi verilir.

signal back_requested

const UNLOCK_PLACEMENT := "unlock_theme"
const NO_THEME := ""

var _group := ButtonGroup.new()
var _cards: Dictionary[String, SkinCard] = {}
## Onay bekleyen kilitli temanın kimliği; bilgi iletisinde boştur.
var _pending_id := NO_THEME
## Kilit açma reklamının sonucu beklenirken yeni kilit açma isteği yok sayılır.
var _watching := false

@onready var _list: VBoxContainer = %Cards
@onready var _confirm: ConfirmOverlay = %ConfirmOverlay


func _ready() -> void:
	(%BackButton as Button).pressed.connect(back_requested.emit)
	_confirm.confirmed.connect(_watch_unlock_ad)
	Skins.changed.connect(_refresh)
	for id: String in Skins.ids():
		_add_card(id)
	_refresh()


func _add_card(id: String) -> void:
	var card := SkinCard.new()
	card.preview = Skins.find(id).preview_texture
	card.button_group = _group
	card.pressed.connect(_on_card_pressed.bind(id))
	_cards[id] = card
	_list.add_child(card)


## Kilitsiz tema hemen seçilir. Kilitli temada seçim eski karta döner ve onay sorulur.
func _on_card_pressed(id: String) -> void:
	if not Skins.is_locked(id):
		Skins.select(id)
		return
	_refresh()
	if _watching:
		return
	if not Ads.is_rewarded_ready():
		_pending_id = NO_THEME
		_confirm.ask("THEME_AD_NOT_READY", "OK")
		return
	_pending_id = id
	_confirm.ask("THEME_UNLOCK_ASK", "WATCH_AD", "CANCEL", false)


## Reklam ödülü verirse tema açılıp seçilir; vermezse hiçbir şey değişmez.
func _watch_unlock_ad() -> void:
	var id := _pending_id
	_pending_id = NO_THEME
	if id == NO_THEME or _watching:
		return
	_watching = true
	Ads.show_rewarded(UNLOCK_PLACEMENT)
	var result: Array = await Ads.rewarded_completed
	while result[0] != UNLOCK_PLACEMENT:
		result = await Ads.rewarded_completed
	_watching = false
	var granted: bool = result[1]
	if granted:
		Skins.unlock(id)
		Skins.select(id)
	_refresh()


## Kartların kilidini ve seçili kartı kayıttaki duruma göre günceller.
func _refresh() -> void:
	for id: String in _cards:
		_cards[id].locked = Skins.is_locked(id)
		_cards[id].set_pressed_no_signal(id == Skins.current_id)
		_cards[id].queue_redraw()
