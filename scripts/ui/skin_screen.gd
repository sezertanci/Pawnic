class_name SkinScreen
extends Control
## Görünüm ekranı: her tahta teması için tahta görselli büyük bir kart, alt alta ve kaydırılarak.
## Karta dokununca tema hemen uygulanır ve kaydedilir; ekranda kalınır, geri okla dönülür.
## Kilitli temanın kartına dokununca ödüllü reklam izleme onayı sorulur; reklam ödülü verirse
## kilit kalıcı olarak kalkar ve tema seçilir. Reklam hazır değilse yalnızca bilgi verilir.
## Kartın üstünden başlayan kaydırma basış sayılmaz. Listenin sonunda "Yakında" kartı durur.

signal back_requested

const UNLOCK_PLACEMENT := "unlock_theme"
const UNLOCK_ASK_KEY := "THEME_UNLOCK_ASK"

var _group := ButtonGroup.new()
var _cards: Dictionary[String, SkinCard] = {}
var _unlock: RewardedUnlock
## Parmak karta değdiğindeki kaydırma konumu; bırakınca farklıysa dokunuş kaydırmadır.
var _scroll_at_down := 0

@onready var _list: VBoxContainer = %Cards
@onready var _scroll: ScrollContainer = %Scroll


func _ready() -> void:
	(%BackButton as Button).pressed.connect(back_requested.emit)
	_unlock = RewardedUnlock.new(
		%ConfirmOverlay as ConfirmOverlay, UNLOCK_PLACEMENT, UNLOCK_ASK_KEY
	)
	Skins.changed.connect(_refresh)
	for id: String in Skins.ids():
		_add_card(id)
	_add_coming_soon()
	_refresh()


func _add_card(id: String) -> void:
	var card := SkinCard.new()
	card.preview = Skins.find(id).preview_texture
	card.button_group = _group
	card.button_down.connect(_on_card_down)
	card.pressed.connect(_on_card_pressed.bind(id))
	_cards[id] = card
	_list.add_child(card)


## Yakında kartı, önündeki görünüm kartıyla aynı boydadır.
func _add_coming_soon() -> void:
	var card := ComingSoonCard.new(true)
	var previous: Control = _list.get_child(-1)
	previous.resized.connect(func() -> void: card.custom_minimum_size.y = previous.size.y)
	_list.add_child(card)


func _on_card_down() -> void:
	_scroll_at_down = _scroll.scroll_vertical


## Kilitsiz tema hemen seçilir. Kilitli temada seçim eski karta döner ve onay sorulur.
## Dokunuş liste kaydırmasıysa seçim değişmez.
func _on_card_pressed(id: String) -> void:
	if _scroll.scroll_vertical != _scroll_at_down:
		_refresh()
		return
	if not Skins.is_locked(id):
		Skins.select(id)
		return
	_refresh()
	_unlock.request(_on_unlocked.bind(id))


## Reklam ödülü verdi: tema açılıp seçilir.
func _on_unlocked(id: String) -> void:
	Skins.unlock(id)
	Skins.select(id)


## Kartların kilidini ve seçili kartı kayıttaki duruma göre günceller.
func _refresh() -> void:
	for id: String in _cards:
		_cards[id].locked = Skins.is_locked(id)
		_cards[id].set_pressed_no_signal(id == Skins.current_id)
		_cards[id].queue_redraw()
