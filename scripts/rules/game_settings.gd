class_name GameSettings
extends RefCounted
## Kural, bot, taş, kart animasyonu ve ekran efekti ayarları. Değerler data/tuning.json
## dosyasından okunur.

const DEFAULT_PATH := "res://data/tuning.json"
const KEY_BOARD := "board"
const KEY_RULES := "rules"
const KEY_BOT := "bot"
const KEY_ANIMATION := "animation"
const KEY_CARDS := "cards"
const KEY_DECK := "deck"
const KEY_EFFECTS := "effects"
const REQUIRED_KEYS: Array[String] = [
	KEY_BOARD, KEY_RULES, KEY_BOT, KEY_ANIMATION, KEY_CARDS, KEY_DECK, KEY_EFFECTS
]

var board_layout: BoardLayout
var hand_size := 0
var exit_value := 0
var joker_max := 0
var min_players := 0
var max_players := 0
var min_pawns := 0
var max_pawns := 0
var default_pawns := 0
## Her öğe: {"type": String, "value": int, "count": int}
var deck: Array[Dictionary] = []
var bot_delay := 0.0
var bot_track_base := 0.0
var bot_lane_bonus := 0.0
var bot_home_value := 0.0
var bot_rival_weight := 0.0
## Animasyon süreleri saniye, yükseklikler kare boyunun katı cinsindendir.
var hop_time := 0.0
var hop_height := 0.0
var boost_pause := 0.0
## Kısayolda ve yer değiştirmede taşın yol üstünden kayma süresi (ışınlanma sesiyle aynı
## uzunlukta) ve ışık kuyruğu.
var slide_time := 0.0
var trail_time := 0.0
var capture_time := 0.0
var capture_height := 0.0
## Hamleden sonra aynı karedeki taşların yeniden dizilme süresi.
var settle_time := 0.0
var home_pulse_time := 0.0
var home_pulse_scale := 0.0
## Kart animasyonu süreleri saniye cinsindendir.
var card_draw_rise := 0.0
var card_draw_land := 0.0
## Çekilen kartın yolda ne kadar yükseleceği (kart boyunun katı) ve ne kadar büyüyeceği.
var card_draw_lift := 0.0
var card_draw_lift_scale := 0.0
## Botun oynadığı kartın atılanlar üstünde rozetiyle görünme süresi.
var card_bot_hold := 0.0
var card_discard_time := 0.0
## Ana ekran logosundaki taşların bir kareden ötekine zıplama süresi (saniye) ve yüksekliği
## (kare boyuna oranla).
var logo_hop_time := 0.0
var logo_hop_height := 0.0
## Kazanma ekranının küçükten büyüyerek açılma süresi (saniye) ve başladığı ölçek.
var win_pop_time := 0.0
var win_pop_start_scale := 0.0
## Konfeti parça sayısı, düşüş hızı aralığı (piksel/saniye), salınma genişliği (piksel),
## salınma ve dönme hızı sınırları (radyan/saniye).
var confetti_count := 0
var confetti_min_fall_speed := 0.0
var confetti_max_fall_speed := 0.0
var confetti_sway := 0.0
var confetti_max_sway_speed := 0.0
var confetti_max_spin := 0.0


## Ayarları dosyadan okur; dosya ya da içindeki tahta dosyası bozuksa null döner.
static func load_from(path: String) -> GameSettings:
	var root := JsonData.read(path, REQUIRED_KEYS)
	if root.is_empty():
		return null
	var settings := GameSettings.new()
	settings._read_board(root[KEY_BOARD])
	if settings.board_layout == null:
		return null
	settings._read_rules(root[KEY_RULES])
	settings._read_bot(root[KEY_BOT])
	settings._read_animation(root[KEY_ANIMATION])
	settings._read_cards(root[KEY_CARDS])
	settings._read_effects(root[KEY_EFFECTS])
	for entry: Dictionary in root[KEY_DECK]:
		settings.deck.append(entry)
	return settings


func _read_board(board: Dictionary) -> void:
	board_layout = BoardLayout.load_from(board["layout"])


func _read_rules(rules: Dictionary) -> void:
	hand_size = int(rules["hand_size"])
	exit_value = int(rules["exit_value"])
	joker_max = int(rules["joker_max"])
	min_players = int(rules["min_players"])
	max_players = int(rules["max_players"])
	min_pawns = int(rules["min_pawns"])
	max_pawns = int(rules["max_pawns"])
	default_pawns = int(rules["default_pawns"])


func _read_bot(bot: Dictionary) -> void:
	bot_delay = float(bot["delay_sec"])
	bot_track_base = float(bot["track_base"])
	bot_lane_bonus = float(bot["lane_bonus"])
	bot_home_value = float(bot["home_value"])
	bot_rival_weight = float(bot["rival_weight"])


func _read_animation(animation: Dictionary) -> void:
	hop_time = float(animation["hop_sec"])
	hop_height = float(animation["hop_height"])
	boost_pause = float(animation["boost_pause_sec"])
	slide_time = float(animation["slide_sec"])
	trail_time = float(animation["trail_sec"])
	capture_time = float(animation["capture_sec"])
	capture_height = float(animation["capture_height"])
	settle_time = float(animation["settle_sec"])
	home_pulse_time = float(animation["home_pulse_sec"])
	home_pulse_scale = float(animation["home_pulse_scale"])


func _read_cards(cards: Dictionary) -> void:
	card_draw_rise = float(cards["draw_rise_sec"])
	card_draw_land = float(cards["draw_land_sec"])
	card_draw_lift = float(cards["draw_lift"])
	card_draw_lift_scale = float(cards["draw_lift_scale"])
	card_bot_hold = float(cards["bot_hold_sec"])
	card_discard_time = float(cards["discard_sec"])


func _read_effects(effects: Dictionary) -> void:
	logo_hop_time = float(effects["logo_hop_sec"])
	logo_hop_height = float(effects["logo_hop_height"])
	win_pop_time = float(effects["win_pop_sec"])
	win_pop_start_scale = float(effects["win_pop_start_scale"])
	confetti_count = int(effects["confetti_count"])
	confetti_min_fall_speed = float(effects["confetti_min_fall_speed"])
	confetti_max_fall_speed = float(effects["confetti_max_fall_speed"])
	confetti_sway = float(effects["confetti_sway"])
	confetti_max_sway_speed = float(effects["confetti_max_sway_speed"])
	confetti_max_spin = float(effects["confetti_max_spin"])
