class_name PauseOverlay
extends Button
## Ağ oyununun mola katmanı: "Duraklatıldı", molanın süresi ve bir not. Hostta not ekranın açık
## kalması gerektiğini hatırlatır, düğmeler Devam et ve Oyunu bitir'dir; katılan oyuncuda not
## hostu beklediğini söyler, tek düğme Oyundan çık'tır. Katmanın dışına dokunmak bir şey yapmaz.
## Aynı katman ortak reklam arasında da açılır: "Reklam arası", süre yok, not diğer oyuncuların
## beklendiğini söyler, tek düğme hostta Oyunu bitir, katılan oyuncuda Oyundan çık'tır.

signal resume_pressed
signal quit_pressed

const PAUSED_KEY := "PAUSED"
const AD_BREAK_KEY := "AD_BREAK"
const AD_BREAK_NOTE_KEY := "AD_BREAK_NOTE"
const HOST_NOTE_KEY := "PAUSE_HOST_NOTE"
const GUEST_NOTE_KEY := "PAUSE_GUEST_NOTE"
const END_MATCH_KEY := "END_MATCH"
const QUIT_MATCH_KEY := "QUIT_MATCH"

## Sayaçta gösterilen saniye; değişince yeniden yazılır.
var _shown_second := -1

@onready var _title: Label = %Title
@onready var _time: Label = %Time
@onready var _note: Label = %Note
@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_resume_button.pressed.connect(resume_pressed.emit)
	_quit_button.pressed.connect(quit_pressed.emit)
	hide()


## Mola katmanını hostun ya da katılan oyuncunun düğmeleriyle açar.
func open(is_host: bool) -> void:
	_open(PAUSED_KEY, HOST_NOTE_KEY if is_host else GUEST_NOTE_KEY, is_host)
	_resume_button.visible = is_host
	_time.show()


## Reklam arası katmanını açar; yalnızca çıkış düğmesi vardır.
func open_ad_break(is_host: bool) -> void:
	_open(AD_BREAK_KEY, AD_BREAK_NOTE_KEY, is_host)
	_resume_button.hide()
	_time.hide()


func _open(title_key: String, note_key: String, is_host: bool) -> void:
	_title.text = title_key
	_note.text = tr(note_key)
	_quit_button.text = tr(END_MATCH_KEY if is_host else QUIT_MATCH_KEY)
	_shown_second = -1
	show()


## Molanın başından beri geçen süreyi oyun saatiyle aynı biçimde yazar.
func show_time(seconds: float) -> void:
	if int(seconds) != _shown_second:
		_shown_second = int(seconds)
		_time.text = GameScreen.format_clock(seconds)
