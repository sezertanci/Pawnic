class_name CardAnimator
extends Control
## Kartların uçuşunu canlandırır: desteden ele çekme, elden atılanlara oynama, botun
## kartını desteden atılanlara açarak götürme ve atılanları desteye karıştırma. Ekranın
## tamamını kaplayan, dokunuşları geçiren katmandır.

## Kart atılanlar yığınına indiği an yayımlanır; sayaç kart inerken artar.
signal discard_landed

var settings: GameSettings
var deck_pile: PileView
var discard_pile: PileView
## Kart uçuşlarının hız çarpanı; botun kartı gösterme süresini etkilemez.
var speed_scale := 1.0


## Kapalı kart desteden büyüyerek kalkar, yolda açılır ve elin boş yerine iner.
func draw_card(target: Rect2, shown: Card) -> void:
	var card := _spawn(_local(deck_pile.card_rect()))
	await _deal(card, _local(target), shown)
	card.queue_free()


## Oynanan ya da atılan kart, köşesinde oyuncunun renginde rozetle elden atılanlara iner.
## chosen jokerde seçilen sayıdır.
func discard_card(source: Rect2, shown: Card, color: Color, chosen: int) -> void:
	var card := _spawn(_local(source))
	card.show_card(shown, settings)
	card.show_chosen(chosen)
	card.set_badge(color)
	await _to_discard(card)


## Botun kartı köşesinde bot renginde rozetle desteden kalkar, yolda açılır, atılanlara iner
## ve orada kısa süre görünür. chosen jokerde seçilen sayıdır.
func reveal_card(shown: Card, color: Color, chosen: int) -> void:
	var card := _spawn(_local(deck_pile.card_rect()))
	card.set_badge(color)
	await _deal(card, _local(discard_pile.card_rect()), shown, chosen)
	discard_landed.emit()
	await get_tree().create_timer(settings.card_bot_hold).timeout
	card.queue_free()


## Atılanlar karıştırılıp desteye döner: kapalı kartlar karıştırma sesiyle art arda
## atılanlardan desteye uçar; son kart inince biter.
func shuffle_to_deck() -> void:
	Sound.play(Sound.SHUFFLE)
	var from := _local(discard_pile.card_rect())
	var to := _local(deck_pile.card_rect())
	var last := settings.card_shuffle_count - 1
	for index: int in range(settings.card_shuffle_count):
		var card := _spawn(from)
		if index == last:
			await _fly_and_free(card, to, settings.card_shuffle_time)
		else:
			_fly_and_free(card, to, settings.card_shuffle_time)
			await get_tree().create_timer(settings.card_shuffle_stagger / speed_scale).timeout


func _spawn(rect: Rect2) -> CardFace:
	var card := CardFace.new()
	add_child(card)
	card.position = rect.position
	card.size = rect.size
	card.pivot_offset = rect.size / 2.0
	return card


## Kapalı kartı yükselterek yolun ortasına götürür, orada açar ve hedefe indirir.
func _deal(card: CardFace, to: Rect2, shown: Card, chosen: int = Card.NO_VALUE) -> void:
	var from := Rect2(card.position, card.size)
	Sound.play(Sound.DRAW)
	var lift := Vector2.UP * to.size.y * settings.card_draw_lift
	var middle := Rect2(from.position.lerp(to.position, 0.5) + lift, to.size)
	await _fly(card, middle, settings.card_draw_rise, settings.card_draw_lift_scale)
	card.show_card(shown, settings)
	card.show_chosen(chosen)
	await _fly(card, to, settings.card_draw_land, 1.0)


func _to_discard(card: CardFace) -> void:
	var target := _local(discard_pile.card_rect())
	await _fly(card, target, settings.card_discard_time, 1.0)
	discard_landed.emit()
	card.queue_free()


func _fly_and_free(card: CardFace, target: Rect2, duration: float) -> void:
	await _fly(card, target, duration, 1.0)
	card.queue_free()


## Kartı verilen yere, boya ve ölçeğe aynı anda götürür.
func _fly(card: CardFace, target: Rect2, duration: float, card_scale: float) -> void:
	var tween := create_tween().set_parallel().set_speed_scale(speed_scale)
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(card, "position", target.position, duration)
	tween.tween_property(card, "size", target.size, duration)
	tween.tween_property(card, "pivot_offset", target.size / 2.0, duration)
	tween.tween_property(card, "scale", Vector2.ONE * card_scale, duration)
	await tween.finished


func _local(rect: Rect2) -> Rect2:
	return Rect2(rect.position - global_position, rect.size)
