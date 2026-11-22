extends GutTest
## Hamle animasyonu kurucusunun birim testleri: eve giren taşın başarı sesi ve yamuk parlaması,
## kırılan taşın "ops" sesi (başlangıçtan taş çıkarınca çalmaz).

const CELL_SIZE := 10.0
## Evin önündeki son ev yolu karesi ve yol ortasında bir kare.
const LAST_LANE := "lane0:4"
const RING := "ring:2"
const NEXT_RING := "ring:3"
## Oynanan taş (0. koltuğun ilk taşı).
const PAWN := 0
## Rakip taş (2. koltuğun ilk taşı).
const RIVAL := 2

var _board: BoardState


func before_each() -> void:
	_board = BoardFixture.classic()


func test_build_pawn_entering_home_adds_home_cue_and_flash_on_landing() -> void:
	BoardFixture.put(_board, PAWN, LAST_LANE)

	var animation := _play_forward(1)

	var end := animation.duration()
	assert_has(animation.cues_between(-INF, end), Sound.HOME)
	assert_eq(animation.flashes_between(-INF, end), [PAWN] as Array[int])


func test_build_pawn_staying_outside_home_adds_no_flash() -> void:
	BoardFixture.put(_board, PAWN, RING)

	var animation := _play_forward(1)

	var end := animation.duration()
	assert_does_not_have(animation.cues_between(-INF, end), Sound.HOME)
	assert_true(animation.flashes_between(-INF, end).is_empty())


func test_build_capture_adds_capture_cue_once() -> void:
	BoardFixture.put(_board, PAWN, RING)
	BoardFixture.put(_board, RIVAL, NEXT_RING)

	var animation := _play_forward(1)

	var cues := animation.cues_between(-INF, animation.duration())
	assert_eq(cues.count(Sound.CAPTURE), 1)


func test_build_without_capture_adds_no_capture_cue() -> void:
	BoardFixture.put(_board, PAWN, RING)

	var animation := _play_forward(1)

	assert_does_not_have(animation.cues_between(-INF, animation.duration()), Sound.CAPTURE)


func test_build_exit_from_base_adds_no_capture_cue() -> void:
	var animation := _play(Card.new(Card.Type.EXIT, Card.NO_VALUE))

	assert_does_not_have(animation.cues_between(-INF, animation.duration()), Sound.CAPTURE)


func _play_forward(steps: int) -> PawnAnimation:
	return _play(Card.new(Card.Type.FORWARD, steps))


func _play(card: Card) -> PawnAnimation:
	var move := _move_of(PAWN, _board.moves_for_card(0, card, 0))
	var path := _board.move_path(move)
	var before := _centers()
	_board.apply(move)
	var builder := MoveAnimationBuilder.new(_board, _centers(), CELL_SIZE, _center)
	return builder.build(move, path, before)


func _move_of(pawn: int, moves: Array[Move]) -> Move:
	for move: Move in moves:
		if move.pawn == pawn:
			return move
	return null


## Taş merkezleri; başlangıçtaki taşlar koltuklarına göre ayrı sıralarda, sırayla dizilir
## (gerçek tahtadaki gibi biri çıkınca kalanlar kayar).
func _centers() -> Array[Vector2]:
	var centers: Array[Vector2] = []
	var in_base: Dictionary[int, int] = {}
	for pawn: int in range(_board.positions.size()):
		var square := _board.positions[pawn]
		if square != BoardState.BASE:
			centers.append(_center(square))
			continue
		var owner := _board.owners[pawn]
		var rank: int = in_base.get(owner, 0)
		in_base[owner] = rank + 1
		centers.append(Vector2(-(rank + 1), owner + 1) * CELL_SIZE)
	return centers


func _center(square: int) -> Vector2:
	return Vector2.RIGHT * square * CELL_SIZE
