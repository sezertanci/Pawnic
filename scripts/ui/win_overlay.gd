class_name WinOverlay
extends Control
## Oyun bitince tahtanın üstünü karartan kutlama: kazananın taşı, dev başlık ve iki düğme.
## İçerik küçükten büyüyerek zıplayarak açılır, üstten oyuncu renklerinde konfeti dökülür.

signal replay_pressed
signal home_pressed

var _winner := 0
var _tween: Tween

@onready var _content: Control = %Content
@onready var _pawn: Control = %Pawn
@onready var _title: Label = %Title
@onready var _confetti: Confetti = %Confetti


func _ready() -> void:
	(%ReplayButton as Button).pressed.connect(replay_pressed.emit)
	(%HomeButton as Button).pressed.connect(home_pressed.emit)
	_pawn.draw.connect(_draw_pawn)


## Kazananı gösterir; colors konfetinin renkleridir.
func open(winner: int, title: String, colors: Array[Color]) -> void:
	_winner = winner
	_title.text = title
	_pawn.queue_redraw()
	show()
	_confetti.burst(colors)
	# Kapların düzeni bir kare sonra kurulur; ölçek merkezden büyüsün diye boy beklenir.
	_content.scale = Vector2.ONE * Tuning.settings.win_pop_start_scale
	await get_tree().process_frame
	_content.pivot_offset = _content.size / 2.0
	if _tween != null:
		_tween.kill()
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(_content, ^"scale", Vector2.ONE, Tuning.settings.win_pop_time)


func close() -> void:
	_confetti.stop()
	hide()


## Taş görseli, alanın yüksekliğini tam dolduracak boyda çizilir.
func _draw_pawn() -> void:
	var texture := Skins.current.pawn_textures[_winner]
	var width := _pawn.size.y / BoardPainter.aspect(texture)
	var radius := width / BoardPainter.PAWN_WIDTH_RATIO
	var foot := Vector2(_pawn.size.x / 2.0, _pawn.size.y * BoardPainter.PAWN_FOOT)
	BoardPainter.draw_pawn(_pawn, foot, radius, _winner)
