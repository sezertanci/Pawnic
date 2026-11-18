class_name RuleList
extends VBoxContainer
## "Nasıl oynanır" ekranındaki kural satırları: solda kurala özel simge, sağda kuralın metni.
## Satırlar açılışta RULES listesinden sırayla kurulur; metinler çeviri anahtarıdır.

const ICON_SIZE := Vector2(76, 76)
const ROW_SEPARATION := 18
const SEPARATION := &"separation"
const LABEL_VARIATION := &"RuleLabel"
const RULES: Dictionary[RuleIcon.Icon, String] = {
	RuleIcon.Icon.CARDS: "RULE_DRAW",
	RuleIcon.Icon.EXIT: "RULE_EXIT",
	RuleIcon.Icon.CAPTURE: "RULE_CAPTURE",
	RuleIcon.Icon.BOOST: "RULE_BOOST",
	RuleIcon.Icon.HOME: "RULE_HOME_LANE",
	RuleIcon.Icon.DISCARD: "RULE_DISCARD",
	RuleIcon.Icon.WIN: "RULE_WIN",
}


func _ready() -> void:
	for icon_kind: RuleIcon.Icon in RULES:
		add_child(_make_row(icon_kind, RULES[icon_kind]))


func _make_row(icon_kind: RuleIcon.Icon, text_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(SEPARATION, ROW_SEPARATION)
	var icon := RuleIcon.new()
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	icon.show_icon(icon_kind)
	row.add_child(icon)
	var label := Label.new()
	label.theme_type_variation = LABEL_VARIATION
	label.text = text_key
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(label)
	return row
