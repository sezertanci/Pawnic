extends GutTest
## Lobi görünümünün (LobbyInfo) sözlüğe çevrilmesi ve ağdan gelen bozuk lobinin reddi.

const SEAT_COUNT := 3
const PAWNS := 4
const OUT_OF_RANGE := 99

var _settings: GameSettings


func before_each() -> void:
	_settings = GameSettings.load_from(GameSettings.DEFAULT_PATH)


func test_round_trip_keeps_fields() -> void:
	var data := _valid_data()

	var info := LobbyInfo.from_dict(_settings, data)

	assert_eq(info.to_dict(), data)


func test_duplicate_colors_are_rejected() -> void:
	var data := _valid_data()
	data[LobbyInfo.KEY_COLORS] = [1, 1]

	assert_null(LobbyInfo.from_dict(_settings, data))


func test_out_of_range_fields_are_rejected() -> void:
	for key: String in [LobbyInfo.KEY_SEAT_COUNT, LobbyInfo.KEY_PAWNS, LobbyInfo.KEY_OWN]:
		var data := _valid_data()
		data[key] = OUT_OF_RANGE
		assert_null(LobbyInfo.from_dict(_settings, data), key)


func test_more_players_than_seats_is_rejected() -> void:
	var data := _valid_data()
	data[LobbyInfo.KEY_COLORS] = [0, 1, 2, 3]

	assert_null(LobbyInfo.from_dict(_settings, data))


func test_unknown_color_is_rejected() -> void:
	var data := _valid_data()
	data[LobbyInfo.KEY_COLORS] = [0, OUT_OF_RANGE]

	assert_null(LobbyInfo.from_dict(_settings, data))


func _valid_data() -> Dictionary:
	var colors: Array[int] = [2, 0]
	return {
		LobbyInfo.KEY_SEAT_COUNT: SEAT_COUNT,
		LobbyInfo.KEY_PAWNS: PAWNS,
		LobbyInfo.KEY_COLORS: colors,
		LobbyInfo.KEY_OWN: 1,
	}
