class_name Nodes
extends RefCounted
## Düğüm ağacıyla ilgili küçük ortak işler.


## Bütün çocuk düğümleri hemen ağaçtan çıkarır ve siler; yerlerine yenileri aynı karede
## eklenebilir.
static func free_children(parent: Node) -> void:
	for child: Node in parent.get_children():
		parent.remove_child(child)
		child.queue_free()


## Dokunuşu almayan, görseli verilen boya oranını koruyarak sığdıran resim düğümü.
static func picture(texture: Texture2D, picture_size: Vector2) -> TextureRect:
	var image := TextureRect.new()
	image.texture = texture
	image.custom_minimum_size = picture_size
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return image


## Düğümü üstündekini dolduracak, ama verilen çerçevenin iç boşluklarında kalacak biçimde
## yerleştirir (ör. bir düğmenin içeriği düğmenin temasındaki çerçeveye göre).
static func fit_inside(content: Control, style: StyleBox) -> void:
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = style.get_margin(SIDE_LEFT)
	content.offset_top = style.get_margin(SIDE_TOP)
	content.offset_right = -style.get_margin(SIDE_RIGHT)
	content.offset_bottom = -style.get_margin(SIDE_BOTTOM)
