extends GutTest
## Koltuk ile renk eşlemesinin (SeatColors) birim testleri.

const SEAT_COUNT := 4
const TOP := 0
const RIGHT := 1
const BOTTOM := 2
const LEFT := 3
const RED := 0
const BLUE := 1
const GREEN := 2
const YELLOW := 3


func test_identity_gives_every_seat_its_own_color() -> void:
	var expected: Array[int] = [RED, BLUE, GREEN, YELLOW]

	var colors := SeatColors.identity(SEAT_COUNT)

	assert_eq(colors, expected)


func test_with_choice_gives_human_chosen_color() -> void:
	var seats: Array[int] = [BOTTOM, TOP]

	var colors := SeatColors.with_choice(SEAT_COUNT, seats, BOTTOM, YELLOW)

	assert_eq(colors[BOTTOM], YELLOW)


func test_with_choice_gives_bots_remaining_colors_in_order() -> void:
	var seats: Array[int] = [BOTTOM, LEFT, TOP, RIGHT]

	var colors := SeatColors.with_choice(SEAT_COUNT, seats, BOTTOM, BLUE)

	assert_eq(colors[LEFT], RED)
	assert_eq(colors[TOP], GREEN)
	assert_eq(colors[RIGHT], YELLOW)


func test_with_choice_keeps_every_color_once() -> void:
	var seats: Array[int] = [BOTTOM, LEFT, TOP]

	var colors := SeatColors.with_choice(SEAT_COUNT, seats, BOTTOM, RED)

	assert_true(SeatColors.is_valid(colors, SEAT_COUNT))


func test_is_valid_with_repeated_color_returns_false() -> void:
	var colors: Array[int] = [RED, RED, GREEN, YELLOW]

	assert_false(SeatColors.is_valid(colors, SEAT_COUNT))


func test_is_valid_with_wrong_size_returns_false() -> void:
	var colors: Array[int] = [RED, BLUE]

	assert_false(SeatColors.is_valid(colors, SEAT_COUNT))
