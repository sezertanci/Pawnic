class_name PauseOverlay
extends Button
## Ağ oyununun mola katmanı: "Duraklatıldı", molanın süresi ve bir not. Hostta not ekranın açık
## kalması gerektiğini hatırlatır, düğmeler Devam et ve Oyunu bitir'dir; katılan oyuncuda not
## hostu beklediğini söyler, tek düğme Oyundan çık'tır. Katmanın dışına dokunmak bir şey yapmaz.

signal resume_pressed
signal quit_pressed

const HOST_NOTE_KEY := "PAUSE_HOST_NOTE"
const GUEST_NOTE_KEY := "PAUSE_GUEST_NOTE"
const END_MATCH_KEY := "END_MATCH"
const QUIT_MATCH_KEY := "QUIT_MATCH"

## Sayaçta gösterilen saniye; değişince yeniden yazılır.
var _shown_second := -1

@onready var _time: Label = %Time
@onready var _note: Label = %Note
@onready var _resume_button: Button = %ResumeButton
@onready var _quit_button: Button = %QuitButton


func _ready() -> void:
	_resume_button.pressed.connect(resume_pressed.emit)
	_quit_button.pressed.connect(quit_pressed.emit)
	hide()


## Katmanı hostun ya da katılan oyuncunun düğmeleriyle açar.
func open(is_host: bool) -> void:
	_note.text = tr(HOST_NOTE_KEY if is_host else GUEST_NOTE_KEY)
	_quit_button.text = tr(END_MATCH_KEY if is_host else QUIT_MATCH_KEY)
	_resume_button.visible = is_host
	_shown_second = -1
	show()


## Molanın başından beri geçen süreyi oyun saatiyle aynı biçimde yazar.
func show_time(seconds: float) -> void:
	if int(seconds) != _shown_second:
		_shown_second = int(seconds)
		_time.text = GameScreen.format_clock(seconds)
