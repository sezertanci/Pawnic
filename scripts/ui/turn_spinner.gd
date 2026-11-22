class_name TurnSpinner
extends CanvasGroup
## Tahtanın ortasındaki bitiş alanını (dört yamuğu) çevreleyen, saat yönünde yavaşça dönen dört
## oklu yay. Taşların hangi yönde ilerlediğini gösterir; rengi sıradaki oyuncunun rengidir ve
## altındaki kareler görünsün diye yarı saydamdır. Saydamlık CanvasGroup ile bütün çizime bir
## kez uygulanır, böylece parçaların değdiği yerler koyulaşmaz. Yaylar bir kez çizilir; dönüş
## yalnızca iç düğümün açısını değiştirir, tahta her karede yeniden çizilmez.

## Yayların sayısı, aralarındaki boşluk ve ok başına yer açmak için yayın ucundan kesilen açı.
const ARC_COUNT := 4
const GAP_ANGLE := PI / 5.0
const HEAD_TRIM := 0.2
## Varsayılan yay yarıçapı, çizgi kalınlığı ve ok başının yarı genişliği (bitiş alanının yarı
## boyuna oranla). Tahta dosyası yarıçap oranını değiştirebilir.
const RADIUS_RATIO := 1.55
const LINE_RATIO := 0.1
const HEAD_RATIO := 0.18
## Yay boyunca radyan başına nokta sayısı; yaylar köşeli görünmesin diye.
const POINTS_PER_RADIAN := 48.0
## Yayların saydamlığı (0 görünmez, 1 tam dolu).
const OPACITY := 0.45
## Bir tam turun süresi (saniye).
const TURN_SECONDS := 30.0

## Yayların rengi; sıra değişince güncellenir.
var color := Color.WHITE:
	set(value):
		color = value
		_arrows.queue_redraw()
## Bitiş alanının yarı boyu (piksel); yaylar buna oranla çizilir.
var half := 0.0:
	set(value):
		if is_equal_approx(half, value):
			return
		half = value
		_arrows.queue_redraw()

## Yay yarıçapının bitiş alanının yarı boyuna oranı.
var radius_ratio := RADIUS_RATIO:
	set(value):
		if is_equal_approx(radius_ratio, value):
			return
		radius_ratio = value
		_arrows.queue_redraw()

var _arrows := Node2D.new()


func _init() -> void:
	self_modulate.a = OPACITY
	_arrows.draw.connect(_draw_arrows)
	add_child(_arrows)


func _process(delta: float) -> void:
	_arrows.rotation = fposmod(_arrows.rotation + delta * TAU / TURN_SECONDS, TAU)


func _draw_arrows() -> void:
	if half > 0.0:
		draw_arrows(
			_arrows, Vector2.ZERO, half * radius_ratio, half * LINE_RATIO, half * HEAD_RATIO, color
		)


## Merkezin çevresine saat yönünü gösteren dört oklu yayı çizer; "Nasıl oynanır" simgesi de
## bunu kullanır.
static func draw_arrows(
	canvas: CanvasItem, center: Vector2, radius: float, width: float, head_half: float, ink: Color
) -> void:
	var step := TAU / ARC_COUNT
	for index: int in range(ARC_COUNT):
		var start := index * step
		var angles := Vector2(start + GAP_ANGLE / 2.0, start + step - GAP_ANGLE / 2.0 - HEAD_TRIM)
		CircularArrow.draw_smooth(
			canvas, center, radius, angles, width, head_half, ink, POINTS_PER_RADIAN
		)
