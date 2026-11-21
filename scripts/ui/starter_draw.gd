class_name StarterDraw
extends Control
## Yeni oyunun başındaki kura: ekran kararır, ortada oyuncuların taşları karışık sırayla değişir,
## çark gibi sona doğru belirgin yavaşlar ve başlayan oyuncuda durur; başlık önce soruyu, sonra
## başlayanı yazar. Taş her değiştiğinde çark tıkırtısı, sonuç yazılınca çan sesi çalar.
## Adım sayısı yalnızca oyuncu sayısına bağlıdır; kuranın süresi sonucu ele vermez.

## Kura bittiğinde ya da yarıda kapatıldığında gelir.
signal closed

var _tween: Tween
## Gösterim sırası yalnızca görünüştür, sonucu etkilemez; bu yüzden oyunun tohumlu üreticisi
## kullanılmaz.
var _rng := RandomNumberGenerator.new()

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
	_rng.randomize()
	var steps := settings.starter_spin_rounds * colors.size() + 1
	var order := spin_order(colors.size(), starter, steps, _rng)
	_tween = create_tween().set_speed_scale(speed)
	for step: int in range(steps):
		_tween.tween_callback(_show_color.bind(colors[order[step]]))
		var progress := ease(float(step) / maxf(steps - 1, 1), settings.starter_spin_ease)
		var first := settings.starter_spin_first_step
		_tween.tween_interval(lerpf(first, settings.starter_spin_last_step, progress))
	_tween.tween_callback(_announce.bind(colors[starter]))
	_tween.tween_interval(settings.starter_spin_hold)
	_tween.tween_callback(close)


## Kurada adım adım gösterilecek oyuncu yerleri (count en az 2): her adım rastgele ve bir önceki
## adımdan farklıdır, son adım başlayandır. Sıra sondan başa kurulur; böylece sonuç değişmez ve
## aynı renk art arda gelmez.
static func spin_order(
	count: int, starter: int, steps: int, rng: RandomNumberGenerator
) -> Array[int]:
	var order: Array[int] = [starter]
	while order.size() < steps:
		var pick := rng.randi_range(0, count - 2)
		if pick >= order.front():
			pick += 1
		order.push_front(pick)
	return order


func close() -> void:
	if _tween != null:
		_tween.kill()
		_tween = null
	hide()
	closed.emit()


func _show_color(color: int) -> void:
	Sound.play(Sound.SPIN)
	_pawn.color = color
	_glass.set_tint(Skins.current.seat_color(color))


func _announce(color: int) -> void:
	Sound.play(Sound.STARTER)
	_title.text = tr("STARTER_RESULT") % Skins.current.seat_name(color)
