class_name GameSettings
extends RefCounted
## Kural, bot, taş, kart animasyonu, ekran efekti ve arayüz ayarları. Değerler data/tuning.json
## dosyasından okunur.

const DEFAULT_PATH := "res://data/tuning.json"
const KEY_BOARD := "board"
const KEY_RULES := "rules"
const KEY_BOT := "bot"
const KEY_ANIMATION := "animation"
const KEY_CARDS := "cards"
const KEY_DECK := "deck"
## Destedeki her öğenin kart sayısı anahtarı.
const KEY_CARD_COUNT := "count"
const KEY_EFFECTS := "effects"
const KEY_UI := "ui"
const KEY_ADS := "ads"
const KEY_NETWORK := "network"
## Tahta bölümünde tahta dosyasının yolunun anahtarı.
const KEY_LAYOUT := "layout"
const REQUIRED_KEYS: Array[String] = [
	KEY_BOARD,
	KEY_RULES,
	KEY_BOT,
	KEY_ANIMATION,
	KEY_CARDS,
	KEY_DECK,
	KEY_EFFECTS,
	KEY_UI,
	KEY_ADS,
	KEY_NETWORK,
]

## Ayar ve tahta dosyalarının içeriğinden alınan özet; ağ oyununda iki cihazın aynı kurallarla
## oynadığı bununla denetlenir.
var digest := ""
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
## Tehdit okuyan botta taşın değerinin çarpılma olasılığıyla ne kadar düşeceği: kendi taşları
## için danger, rakip taşları için attack (0: hiç, 1: tamamen).
var bot_danger_weight := 0.0
var bot_attack_weight := 0.0
## Bot seviyelerinin davranışı, Bot.Level sırasıyla.
var bot_profiles: Array[BotProfile] = []
## Çok zor botun aramasında bütün oyuncuların yerine oynayan hızlı botun davranışı.
var bot_rollout_policy: BotProfile
## Animasyon süreleri saniye, yükseklikler kare boyunun katı cinsindendir.
var hop_time := 0.0
var hop_height := 0.0
var boost_pause := 0.0
## Kısayolda ve yer değiştirmede taşın yol üstünden kayma süresi (ışınlanma sesiyle aynı
## uzunlukta), kayma bitince ışık kuyruğunun toplanma süresi ve kuyruğun kare cinsinden en
## fazla uzunluğu.
var slide_time := 0.0
var trail_time := 0.0
var trail_squares := 0.0
var capture_time := 0.0
var capture_height := 0.0
## Hamleden sonra aynı karedeki taşların yeniden dizilme süresi.
var settle_time := 0.0
## Eve giren taşın bitiş karesindeki küçük cama girerken küçülme süresi.
var home_shrink_time := 0.0
## Başlangıç kurası: sıra okunun oyuncular arasında kaç tur döndüğü, ilk ve son adımın süresi
## (ok giderek yavaşlar) ve başlayanda durduktan sonra bekleme süresi.
var starter_spin_rounds := 0
var starter_spin_first_step := 0.0
var starter_spin_last_step := 0.0
var starter_spin_hold := 0.0
## Oyun hızı seviyelerinin (yavaş, normal, hızlı) animasyon hız çarpanları.
var speed_levels: Array[float] = []
## Kart animasyonu süreleri saniye cinsindendir.
var card_draw_rise := 0.0
var card_draw_land := 0.0
## Çekilen kartın yolda ne kadar yükseleceği (kart boyunun katı) ve ne kadar büyüyeceği.
var card_draw_lift := 0.0
var card_draw_lift_scale := 0.0
## Botun oynadığı kartın atılanlar üstünde rozetiyle görünme süresi.
var card_bot_hold := 0.0
var card_discard_time := 0.0
## Karıştırmada atılanlardan desteye art arda uçan kapalı kart sayısı, kalkışlar arası süre ve
## bir kartın uçuş süresi.
var card_shuffle_count := 0
var card_shuffle_stagger := 0.0
var card_shuffle_time := 0.0
## Ana ekran logosundaki taşların bir kareden ötekine zıplama süresi (saniye) ve yüksekliği
## (kare boyuna oranla).
var logo_hop_time := 0.0
var logo_hop_height := 0.0
## Kazanma ekranının küçükten büyüyerek açılma süresi (saniye) ve başladığı ölçek.
var win_pop_time := 0.0
var win_pop_start_scale := 0.0
## Oyun sürerken bitiren oyuncunun duyurusunun ekranda kalma süresi (saniye).
var finish_banner_time := 0.0
## Konfeti parça sayısı, düşüş hızı aralığı (piksel/saniye), salınma genişliği (piksel),
## salınma ve dönme hızı sınırları (radyan/saniye).
var confetti_count := 0
var confetti_min_fall_speed := 0.0
var confetti_max_fall_speed := 0.0
var confetti_sway := 0.0
var confetti_max_sway_speed := 0.0
var confetti_max_spin := 0.0
## Menü düğmelerinin (ana ekran, yeni oyun, oyun sonu, kurallar) ortak en küçük boyutu (piksel).
var menu_button_size := Vector2.ZERO
## Menü ekranlarındaki arka plan resminin bulanıklığı (resmin pikseli cinsinden örnek uzaklığı).
var backdrop_blur := 0.0
## Evdeki (bitiş karesindeki küçük camdaki) taşların normal boylarına oranı.
var home_pawn_scale := 0.0
## Oyun içi geçiş reklamları arasında en az geçen oyun süresi (saniye).
var interstitial_interval := 0.0
## Oyun içi reklamdan bu kadar süre geçmeden oyun biterse oyun sonu reklamı atlanır (saniye).
var end_ad_cooldown := 0.0
## Ağ oyununda hostun dinlediği UDP portu.
var network_port := 0
## Ağdan gelen bir mesajın en fazla bayt sayısı; büyüğü çözülmeden atılır.
var max_message_bytes := 0
## Bir eşten saniyede okunan en fazla mesaj; fazlası atılır.
var max_messages_per_sec := 0
## Oyun bulma yayınının UDP portu (oyun portundan ayrı).
var discovery_port := 0
## Hostun "burada oyun var" yayınları arasındaki süre (milisaniye).
var announce_interval_ms := 0
## Bu kadar süre yayını gelmeyen oyun bulunanlar listesinden çıkar (milisaniye).
var announce_expiry_ms := 0


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
	settings._read_ui(root[KEY_UI])
	settings._read_ads(root[KEY_ADS])
	settings._read_network(root[KEY_NETWORK])
	for entry: Dictionary in root[KEY_DECK]:
		settings.deck.append(entry)
	var board_path: String = root[KEY_BOARD][KEY_LAYOUT]
	settings.digest = (
		(FileAccess.get_file_as_string(path) + FileAccess.get_file_as_string(board_path))
		. sha256_text()
	)
	return settings


## Destedeki toplam kart sayısı.
func deck_size() -> int:
	var total := 0
	for entry: Dictionary in deck:
		total += int(entry[KEY_CARD_COUNT])
	return total


func _read_board(board: Dictionary) -> void:
	board_layout = BoardLayout.load_from(board[KEY_LAYOUT])


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
	bot_danger_weight = float(bot["danger_weight"])
	bot_attack_weight = float(bot["attack_weight"])
	bot_rollout_policy = BotProfile.from_dict(bot["rollout_policy"])
	for level: Dictionary in bot["levels"]:
		bot_profiles.append(BotProfile.from_dict(level))


func _read_animation(animation: Dictionary) -> void:
	hop_time = float(animation["hop_sec"])
	hop_height = float(animation["hop_height"])
	boost_pause = float(animation["boost_pause_sec"])
	slide_time = float(animation["slide_sec"])
	trail_time = float(animation["trail_sec"])
	trail_squares = float(animation["trail_squares"])
	capture_time = float(animation["capture_sec"])
	capture_height = float(animation["capture_height"])
	settle_time = float(animation["settle_sec"])
	home_shrink_time = float(animation["home_shrink_sec"])
	starter_spin_rounds = int(animation["starter_spin_rounds"])
	starter_spin_first_step = float(animation["starter_spin_first_step_sec"])
	starter_spin_last_step = float(animation["starter_spin_last_step_sec"])
	starter_spin_hold = float(animation["starter_spin_hold_sec"])
	for level: Variant in animation["speed_levels"]:
		speed_levels.append(float(level))


func _read_cards(cards: Dictionary) -> void:
	card_draw_rise = float(cards["draw_rise_sec"])
	card_draw_land = float(cards["draw_land_sec"])
	card_draw_lift = float(cards["draw_lift"])
	card_draw_lift_scale = float(cards["draw_lift_scale"])
	card_bot_hold = float(cards["bot_hold_sec"])
	card_discard_time = float(cards["discard_sec"])
	card_shuffle_count = int(cards["shuffle_cards"])
	card_shuffle_stagger = float(cards["shuffle_stagger_sec"])
	card_shuffle_time = float(cards["shuffle_sec"])


func _read_effects(effects: Dictionary) -> void:
	logo_hop_time = float(effects["logo_hop_sec"])
	logo_hop_height = float(effects["logo_hop_height"])
	win_pop_time = float(effects["win_pop_sec"])
	win_pop_start_scale = float(effects["win_pop_start_scale"])
	finish_banner_time = float(effects["finish_banner_sec"])
	confetti_count = int(effects["confetti_count"])
	confetti_min_fall_speed = float(effects["confetti_min_fall_speed"])
	confetti_max_fall_speed = float(effects["confetti_max_fall_speed"])
	confetti_sway = float(effects["confetti_sway"])
	confetti_max_sway_speed = float(effects["confetti_max_sway_speed"])
	confetti_max_spin = float(effects["confetti_max_spin"])


func _read_ui(ui: Dictionary) -> void:
	menu_button_size = Vector2(float(ui["button_width"]), float(ui["button_height"]))
	backdrop_blur = float(ui["backdrop_blur"])
	home_pawn_scale = float(ui["home_pawn_scale"])


func _read_ads(ads: Dictionary) -> void:
	interstitial_interval = float(ads["interstitial_interval_sec"])
	end_ad_cooldown = float(ads["end_ad_cooldown_sec"])


func _read_network(network: Dictionary) -> void:
	network_port = int(network["port"])
	max_message_bytes = int(network["max_message_bytes"])
	max_messages_per_sec = int(network["max_messages_per_sec"])
	discovery_port = int(network["discovery_port"])
	announce_interval_ms = int(network["announce_interval_ms"])
	announce_expiry_ms = int(network["announce_expiry_ms"])
