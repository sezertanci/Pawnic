extends SceneTree
## Mağazanın öne çıkan görseli için birkaç çeşit kartı saydam zeminli PNG olarak kaydeder.
## Çıktılar card_0.png … card_4.png adıyla yazılır; tools/make_feature_graphic.py bunları kullanır.
## Pencereli çalıştırılmalıdır (--headless çizim yapmaz).
## Çalıştırma: godot --path . -s tools/render_cards.gd -- <çıktı klasörü>

const CARD_WIDTH := 300.0
## Kart gölgesi ve kenar çizgisi kesilmesin diye her yana bırakılan saydam pay.
const MARGIN := 20
const JOKER_MAX := 6
const FILE_NAME := "card_%d.png"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var settings := GameSettings.new()
	settings.joker_max = JOKER_MAX
	var cards: Array[Card] = [
		Card.new(Card.Type.FORWARD, 5),
		Card.new(Card.Type.BACK, 3),
		Card.new(Card.Type.SWAP, 0),
		Card.new(Card.Type.SEND_BACK, 8),
		Card.new(Card.Type.JOKER, 0),
	]
	for i: int in cards.size():
		var image := await _render(cards[i], settings)
		image.save_png(out_dir.path_join(FILE_NAME % i))
	quit()


## Kartı ayrı bir SubViewport'ta çizer ve görüntüsünü döndürür.
func _render(card: Card, settings: GameSettings) -> Image:
	var size := Vector2(CARD_WIDTH, CARD_WIDTH * CardFace.ASPECT)
	var viewport := SubViewport.new()
	viewport.transparent_bg = true
	viewport.size = Vector2i(size) + Vector2i(MARGIN, MARGIN) * 2
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	var face := CardFace.new()
	face.position = Vector2(MARGIN, MARGIN)
	face.size = size
	viewport.add_child(face)
	root.add_child(viewport)
	face.show_card(card, settings)
	# İlk karede yerleşim, ikincisinde çizim tamamlanır.
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	return image
