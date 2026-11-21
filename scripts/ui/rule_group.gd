class_name RuleGroup
extends VBoxContainer
## "Nasıl oynanır" ekranında açılıp kapanan bir kural grubu: dokunulabilir başlık ve altında
## başlangıçta gizli satırlar. Başlığa dokunulunca grup kendini açmaz, toggle_requested ile
## bildirir; aynı anda hangi grubun açık kalacağına RuleList karar verir.

signal toggle_requested

const HEADER_VARIATION := &"RuleGroupButton"
const SEPARATION := &"separation"
const CONTENT_SEPARATION := 18

var header := Button.new()
var content := VBoxContainer.new()
var _chevron := GroupChevron.new()


func _init(title_key: String) -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	header.theme_type_variation = HEADER_VARIATION
	header.text = title_key
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	## Sürükleme kaydırma kutusuna da ulaşsın, liste başlığın üstünden de kaydırılabilsin.
	header.mouse_filter = MOUSE_FILTER_PASS
	header.pressed.connect(toggle_requested.emit)
	header.add_child(_chevron)
	add_child(header)
	content.mouse_filter = MOUSE_FILTER_IGNORE
	content.add_theme_constant_override(SEPARATION, CONTENT_SEPARATION)
	content.hide()
	add_child(content)


func is_open() -> bool:
	return content.visible


func set_open(open: bool) -> void:
	content.visible = open
	_chevron.open = open
