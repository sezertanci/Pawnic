class_name StarterDraw
extends Control
## Yeni oyunun başındaki kura: ekran kararır, ortada oyuncuların taşları sırayla döner, giderek
## yavaşlar ve başlayan oyuncuda durur; başlık önce soruyu, sonra başlayanı yazar.

## Kura bittiğinde ya da yarıda kapatıldığında gelir.
signal closed

var _tween: Tween

@onready var _pawn: PawnIcon = %Pawn
@onready var _title: Label = %Title
@onready var _glass: FrostedGlass = %Glass


## colors oyuncuların renkleri (sıra düzeninde), starter başlayanın bu listedeki yeri;
## speed oyun hızının çarpanıdır.
func play(colors: Array[int], starter: int, settings: GameSettings, speed: float) -> void:
	if _tween != null:
		_tween.kill()
	_title.text = tr("STARTER_DRAW")
	show()
	var count := colors.size()
	var steps := settings.starter_spin_rounds * count + starter + 1
	_tween = create_tween().set_speed_scale(speed)
	for step: int in range(steps):
		_tween.tween_callback(_show_color.bind(colors[step % count]))
		var progress := float(step) / maxf(steps - 1, 1)
		var first := settings.starter_spin_first_step
		_tween.tween_interval(lerpf(first, settings.starter_spin_last_step, progress))
	_tween.tween_callback(_announce.bind(colors[starter]))
	_tween.tween_interval(settings.starter_spin_hold)
	_tween.tween_callback(close)


func close() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	hide()
	closed.emit()


func _show_color(color: int) -> void:
	_pawn.color = color
	_glass.set_tint(Skins.current.seat_color(color))


func _announce(color: int) -> void:
	_title.text = tr("STARTER_RESULT") % Skins.current.seat_name(color)
