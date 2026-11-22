extends GutTest
## Klasik kaplamanın sade kalması; ahşap ve gece neon kaplamalarının kendine özgü alanları.

const CLASSIC := "res://themes/skins/classic.tres"
const WOOD := "res://themes/skins/wood.tres"
const NEON := "res://themes/skins/neon.tres"


func test_classic_skin_stays_plain() -> void:
	var skin := load(CLASSIC) as BoardSkin

	assert_null(skin.inlay_texture)
	assert_null(skin.background_texture)


func test_wood_skin_has_inlay_table_and_full_color_lanes() -> void:
	var skin := load(WOOD) as BoardSkin

	assert_not_null(skin.inlay_texture)
	assert_not_null(skin.background_texture)
	assert_eq(skin.lane_tint, 1.0)


func test_neon_skin_has_no_inlay_and_full_color_lanes() -> void:
	var skin := load(NEON) as BoardSkin

	assert_null(skin.inlay_texture)
	assert_not_null(skin.track_texture)
	assert_eq(skin.lane_tint, 1.0)


func test_every_skin_has_every_seat_color_and_pawn() -> void:
	var classic := load(CLASSIC) as BoardSkin

	for path: String in [WOOD, NEON]:
		var skin := load(path) as BoardSkin
		assert_eq(skin.seat_colors.size(), classic.seat_colors.size(), path)
		assert_eq(skin.pawn_textures.size(), classic.pawn_textures.size(), path)
		assert_eq(skin.seat_name_keys, classic.seat_name_keys, path)
