class_name RuleList
extends VBoxContainer
## "Nasıl oynanır" ekranındaki açılır kural grupları. Başta bütün gruplar kapalıdır; bir gruba
## dokununca o grup açılır, açık olan diğer grup kapanır. Açık gruba yeniden dokununca kapanır.
## Kural satırlarında solda kurala özel simge, kart satırlarında kartın kendisi, kurulum
## satırlarında mod simgesi durur. Wi-Fi grubunda simge yoktur; oyunda görünen uyarı mesajı
## kırmızı başlık olarak yazılır, altında ne yapılacağı anlatılır. Metinler çeviri anahtarıdır,
## sayılar (süreler, oyuncu sayısı) ayarlardan okunur.

const ICON_SIZE := Vector2(76, 76)
const ROW_SEPARATION := 18
const WARNING_SEPARATION := 4
const SEPARATION := &"separation"
const LABEL_VARIATION := &"RuleLabel"
const WARNING_VARIATION := &"RuleWarning"
const ICON_STYLE := &"RuleIcon"
const GOAL_RULES: Dictionary[RuleIcon.Icon, String] = {
	RuleIcon.Icon.DIRECTION: "RULE_DIRECTION",
	RuleIcon.Icon.CARDS: "RULE_DRAW",
	RuleIcon.Icon.DISCARD: "RULE_DISCARD",
	RuleIcon.Icon.WIN: "RULE_WIN",
}
const BOARD_RULES: Dictionary[RuleIcon.Icon, String] = {
	RuleIcon.Icon.EXIT: "RULE_EXIT",
	RuleIcon.Icon.CAPTURE: "RULE_CAPTURE",
	RuleIcon.Icon.SHIELD: "RULE_SHIELD",
	RuleIcon.Icon.BOOST: "RULE_BOOST",
	RuleIcon.Icon.HOME: "RULE_HOME_LANE",
}
const CARD_RULES: Dictionary[Card.Type, String] = {
	Card.Type.FORWARD: "RULE_CARD_FORWARD",
	Card.Type.EXIT: "RULE_CARD_EXIT",
	Card.Type.BACK: "RULE_CARD_BACK",
	Card.Type.SEND_BACK: "RULE_CARD_SEND_BACK",
	Card.Type.SWAP: "RULE_CARD_SWAP",
	Card.Type.SHORTCUT: "RULE_CARD_SHORTCUT",
	Card.Type.JOKER: "RULE_CARD_JOKER",
}
const SETUP_RULES: Dictionary[Texture2D, String] = {
	preload("res://assets/images/icon_single.svg"): "SETUP_SINGLE",
	preload("res://assets/images/icon_wifi.svg"): "SETUP_NETWORK",
	preload("res://assets/images/icon_multi.svg"): "SETUP_MULTI",
}
## Wi-Fi grubunun satırları: oyunda görünen mesajlar (MESSAGES, varsa), açıklama (TEXT) ve
## açıklamadaki sayının okunduğu GameSettings alanı (SETTING, varsa).
const MESSAGES := &"messages"
const TEXT := &"text"
const SETTING := &"setting"
const NETWORK_HELP: Array[Dictionary] = [
	{TEXT: "NET_HELP_TURN_TIME", SETTING: &"turn_time_limit"},
	{MESSAGES: ["RECONNECTING"], TEXT: "NET_HELP_RECONNECT", SETTING: &"rejoin_wait_time"},
	{TEXT: "NET_HELP_LEAVE"},
	{TEXT: "NET_HELP_PAUSE"},
	{TEXT: "SEARCH_NOT_FOUND"},
	{MESSAGES: ["NETWORK_FAILED"], TEXT: "NET_HELP_NO_WIFI"},
	{MESSAGES: ["REFUSED_WRONG_CODE"], TEXT: "NET_HELP_WRONG_CODE"},
	{
		MESSAGES: ["REFUSED_ROOM_FULL", "REFUSED_MATCH_STARTED"],
		TEXT: "NET_HELP_ROOM_CLOSED",
		SETTING: &"max_players",
	},
	{MESSAGES: ["REFUSED_VERSION"], TEXT: "NET_HELP_VERSION"},
	{MESSAGES: ["HOST_UNREACHABLE", "GAME_ENDED"], TEXT: "NET_HELP_HOST_LOST"},
]


func _ready() -> void:
	var settings := Tuning.settings
	_add_rule_group("RULES_GROUP_GOAL", GOAL_RULES)
	_add_rule_group("RULES_GROUP_BOARD", BOARD_RULES)
	var cards := _add_group("RULES_CARDS")
	for card_type: Card.Type in CARD_RULES:
		cards.add_child(_make_row(_make_card_icon(card_type, settings), CARD_RULES[card_type]))
	var setup := _add_group("RULES_GROUP_SETUP")
	for texture: Texture2D in SETUP_RULES:
		setup.add_child(_make_row(_make_texture_icon(texture), SETUP_RULES[texture]))
	var network := _add_group("RULES_GROUP_NETWORK")
	for entry: Dictionary in NETWORK_HELP:
		network.add_child(_make_help(entry, settings))


## Bütün grupları kapatır ve listeyi başa sarar.
func collapse_all() -> void:
	for group: RuleGroup in _groups():
		group.set_open(false)
	var scroll := get_parent() as ScrollContainer
	if scroll != null:
		scroll.scroll_vertical = 0


func _groups() -> Array[RuleGroup]:
	var groups: Array[RuleGroup] = []
	for child: Node in get_children():
		if child is RuleGroup:
			groups.append(child as RuleGroup)
	return groups


## Yeni bir grup ekler ve satırların ekleneceği kutuyu döner.
func _add_group(title_key: String) -> VBoxContainer:
	var group := RuleGroup.new(title_key)
	group.toggle_requested.connect(_on_toggle_requested.bind(group))
	add_child(group)
	return group.content


func _add_rule_group(title_key: String, rules: Dictionary[RuleIcon.Icon, String]) -> void:
	var box := _add_group(title_key)
	for icon_kind: RuleIcon.Icon in rules:
		box.add_child(_make_row(_make_rule_icon(icon_kind), rules[icon_kind]))


func _on_toggle_requested(group: RuleGroup) -> void:
	var opening := not group.is_open()
	for other: RuleGroup in _groups():
		other.set_open(opening and other == group)
	if opening:
		_scroll_to(group)


## Açılan grubun başlığı listenin üstüne gelir; yerleşim bir kare sonra güncellendiği için
## kaydırma beklenir.
func _scroll_to(group: RuleGroup) -> void:
	var scroll := get_parent() as ScrollContainer
	if scroll == null:
		return
	await get_tree().process_frame
	scroll.scroll_vertical = int(group.position.y)


func _make_row(icon: Control, text_key: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(SEPARATION, ROW_SEPARATION)
	icon.custom_minimum_size = ICON_SIZE
	icon.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(icon)
	var label := _make_label(Label.new(), LABEL_VARIATION, text_key)
	label.size_flags_vertical = SIZE_SHRINK_CENTER
	row.add_child(label)
	return row


func _make_label(label: Label, variation: StringName, text_key: String) -> Label:
	label.theme_type_variation = variation
	if not text_key.is_empty():
		label.text = text_key
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	return label


## Wi-Fi grubunun bir satırı: varsa kırmızı mesaj başlıkları, altında açıklama.
func _make_help(entry: Dictionary, settings: GameSettings) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(SEPARATION, WARNING_SEPARATION)
	for message: String in entry.get(MESSAGES, []):
		box.add_child(_make_label(Label.new(), WARNING_VARIATION, message))
	var text_key: String = entry[TEXT]
	if entry.has(SETTING):
		var value: float = settings.get(entry[SETTING])
		box.add_child(_make_label(FormattedLabel.new(text_key, value), LABEL_VARIATION, ""))
	else:
		box.add_child(_make_label(Label.new(), LABEL_VARIATION, text_key))
	return box


func _make_rule_icon(icon_kind: RuleIcon.Icon) -> RuleIcon:
	var icon := RuleIcon.new()
	icon.show_icon(icon_kind)
	return icon


## Kurulum ekranındaki mod simgesi, kural simgesiyle aynı kutuda ve yazı renginde.
func _make_texture_icon(texture: Texture2D) -> PanelContainer:
	var box := PanelContainer.new()
	box.mouse_filter = MOUSE_FILTER_IGNORE
	box.theme_type_variation = ICON_STYLE
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.self_modulate = get_theme_color(ThemeKeys.FONT_COLOR, LABEL_VARIATION)
	box.add_child(image)
	return box


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
