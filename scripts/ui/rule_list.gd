class_name RuleList
extends VBoxContainer
## "Nasıl oynanır" ekranındaki kural satırları: solda kurala özel simge, sağda kuralın metni.
## Önce RULES listesindeki genel kurallar, ardından "Kartlar" ara başlığı ve CARD_RULES
## listesindeki özel kartlar gelir; kart satırlarında simge olarak kartın kendisi küçük çizilir.
## Kartın değeri destedeki aynı türden ilk karttan alınır. Metinler çeviri anahtarıdır.

const ICON_SIZE := Vector2(76, 76)
const ROW_SEPARATION := 18
const SEPARATION := &"separation"
const LABEL_VARIATION := &"RuleLabel"
const SUBHEADING_VARIATION := &"RulesSubheading"
const CARDS_HEADING := "RULES_CARDS"
const RULES: Dictionary[RuleIcon.Icon, String] = {
	RuleIcon.Icon.CARDS: "RULE_DRAW",
	RuleIcon.Icon.EXIT: "RULE_EXIT",
	RuleIcon.Icon.CAPTURE: "RULE_CAPTURE",
	RuleIcon.Icon.BOOST: "RULE_BOOST",
	RuleIcon.Icon.HOME: "RULE_HOME_LANE",
	RuleIcon.Icon.DISCARD: "RULE_DISCARD",
	RuleIcon.Icon.WIN: "RULE_WIN",
}
const CARD_RULES: Dictionary[Card.Type, String] = {
	Card.Type.BACK: "RULE_CARD_BACK",
	Card.Type.SEND_BACK: "RULE_CARD_SEND_BACK",
	Card.Type.SWAP: "RULE_CARD_SWAP",
	Card.Type.SHORTCUT: "RULE_CARD_SHORTCUT",
	Card.Type.JOKER: "RULE_CARD_JOKER",
}


func _ready() -> void:
	for icon_kind: RuleIcon.Icon in RULES:
		add_child(_make_row(_make_rule_icon(icon_kind), RULES[icon_kind]))
	add_child(_make_subheading())
	var settings := Tuning.settings
	for card_type: Card.Type in CARD_RULES:
		add_child(_make_row(_make_card_icon(card_type, settings), CARD_RULES[card_type]))


func _make_row(icon: Control, text_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(SEPARATION, ROW_SEPARATION)
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := Label.new()
	label.theme_type_variation = LABEL_VARIATION
	label.text = text_key
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(label)
	return row


func _make_rule_icon(icon_kind: RuleIcon.Icon) -> RuleIcon:
	var icon := RuleIcon.new()
	icon.show_icon(icon_kind)
	return icon


## Simge alanının ortasında, alana sığan küçük ve açık bir kart.
func _make_card_icon(card_type: Card.Type, settings: GameSettings) -> CenterContainer:
	var box := CenterContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	var face := CardFace.new()
	face.custom_minimum_size = CardFace.fit_size(ICON_SIZE.x, ICON_SIZE.y)
	face.show_card(_sample_card(card_type, settings), settings)
	box.add_child(face)
	return box


## Destedeki card_type türünden ilk kart; destede yoksa değersiz bir kart.
static func _sample_card(card_type: Card.Type, settings: GameSettings) -> Card:
	for entry: Dictionary in settings.deck:
		var card := Card.from_dict(entry)
		if card != null and card.type == card_type:
			return card
	return Card.new(card_type, Card.NO_VALUE)


func _make_subheading() -> Label:
	var label := Label.new()
	label.theme_type_variation = SUBHEADING_VARIATION
	label.text = CARDS_HEADING
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label
