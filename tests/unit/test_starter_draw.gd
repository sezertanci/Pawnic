extends GutTest
## Başlangıç kurasının gösterim sırası: başlayanda biter, aynı renk art arda gelmez, adım sayısı
## sonuçtan bağımsızdır.

const COUNT := 4
const STEPS := 13
const SEED := 5
## Farklı tohumlarla denenecek kura sayısı.
const RUNS := 50


func test_order_ends_on_starter() -> void:
	for starter: int in range(COUNT):
		var order := StarterDraw.spin_order(COUNT, starter, STEPS, _rng(SEED + starter))

		assert_eq(order.back(), starter)
		assert_eq(order.size(), STEPS)


func test_order_never_repeats_a_color_in_a_row() -> void:
	for run: int in range(RUNS):
		var order := StarterDraw.spin_order(COUNT, run % COUNT, STEPS, _rng(run))

		for step: int in range(1, order.size()):
			assert_ne(order[step], order[step - 1])


func test_order_stays_within_players() -> void:
	var order := StarterDraw.spin_order(COUNT, 0, STEPS, _rng(SEED))

	for place: int in order:
		assert_between(place, 0, COUNT - 1)


func test_order_does_not_always_start_with_same_color() -> void:
	var firsts := {}

	for run: int in range(RUNS):
		firsts[StarterDraw.spin_order(COUNT, 0, STEPS, _rng(run)).front()] = true

	assert_gt(firsts.size(), 1)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
