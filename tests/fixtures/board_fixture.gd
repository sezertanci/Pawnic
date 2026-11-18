class_name BoardFixture
extends RefCounted
## Kural testleri için ortak tahta kurulumu ve yardımcılar.


## Klasik tahta: 0. koltukta iki taş (0 ve 1), 2. koltukta bir taş (2).
static func classic() -> BoardState:
	var board := BoardState.new(GameSettings.load_from(GameSettings.DEFAULT_PATH))
	board.add_pawns(0, 2)
	board.add_pawns(2, 1)
	return board


static func put(board: BoardState, pawn: int, square_name: String) -> void:
	board.positions[pawn] = board.layout.index_of(square_name)


static func names(board: BoardState, path: Array[int]) -> Array[String]:
	var result: Array[String] = []
	for square: int in path:
		result.append(board.layout.names[square])
	return result
