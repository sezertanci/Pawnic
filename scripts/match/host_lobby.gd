class_name HostLobby
extends RefCounted
## Ağ oyununda hostun lobisi (ekransız). Host oyuncu ve taş sayısını seçer; katılan oyuncu doğru
## oda koduyla el sıkışınca sıradaki boş yere oturur, ilk boş rengi alır ve sonra boş bir renge
## geçebilir. Her değişiklikte lobi her oyuncuya kendi görünümüyle gönderilir. Yanlış kodla gelen
## eş reddedilir; toplam max_wrong_codes yanlış denemede yeni oda kodu üretilir. Başlatınca
## oyuncular katılma sırasıyla koltuk alır, boş koltuklara Orta bot oturur ve yeni bağlantı
## alınmaz.

## Lobi değişti (oyuncu, renk ya da ayar).
signal changed
## Oda kodu değişti (yanlış denemeler sınırı aştı).
signal code_changed(room_code: String)

## Oyun başlarken boş koltuklara oturan botların seviyesi.
const BOT_LEVEL := Bot.Level.MEDIUM
const DECIMAL_BASE := 10

## Katılmak için gereken oda kodu; room_code_digits basamaklı rakam.
var code := ""
var seat_count := 0
var pawns := 0

var _settings: GameSettings
var _transport: MatchTransport
var _session: HostSession
var _rng: RandomNumberGenerator
## Katılan eşler, katılma sırasıyla.
var _members: Array[int] = []
## Oyuncuların renkleri: eş numarası → renk; host HOST_PEER ile tutulur.
var _colors: Dictionary[int, int] = {}
var _wrong_codes := 0
var _started := false


func _init(
	settings: GameSettings,
	transport: MatchTransport,
	session: HostSession,
	rng: RandomNumberGenerator
) -> void:
	_settings = settings
	_transport = transport
	_session = session
	_rng = rng
	seat_count = settings.max_players
	pawns = settings.default_pawns
	_colors[MatchTransport.HOST_PEER] = _first_free_color()
	_session.admission = _admit
	_session.peer_welcomed.connect(_on_welcomed)
	_transport.message_received.connect(_on_message)
	_transport.peer_disconnected.connect(_on_peer_left)
	_renew_code()


## Lobinin hosta görünen hâli.
func info() -> LobbyInfo:
	return _info_for(0)


## Oyuncu sayısını değiştirir; aralık dışıysa, lobidekilerden azsa ya da oyun başladıysa false.
func set_seat_count(count: int) -> bool:
	var low := maxi(_settings.min_players, _members.size() + 1)
	if _started or count < low or count > _settings.max_players:
		return false
	seat_count = count
	_broadcast()
	return true


## Taş sayısını değiştirir; aralık dışıysa ya da oyun başladıysa false.
func set_pawns(count: int) -> bool:
	if _started or count < _settings.min_pawns or count > _settings.max_pawns:
		return false
	pawns = count
	_broadcast()
	return true


## Hostun rengini değiştirir; renk başkasındaysa ya da geçersizse false.
func choose_host_color(color: int) -> bool:
	return _choose_color(MatchTransport.HOST_PEER, color)


## Oyunu kurar ve katılanları koltuklarına oturtur; hakemin start()'ı, oturumun share_match()'i ve
## hakemin begin()'i bundan sonra çağrılır. Host sıra düzeninde ilk yerdedir. İkinci çağrıda null.
func start() -> GameMatch:
	if _started:
		return null
	_started = true
	_transport.refuse_new_peers()
	var players: Array[int] = [MatchTransport.HOST_PEER]
	players.append_array(_members)
	var bot_flags: Array[bool] = []
	for index: int in range(seat_count):
		bot_flags.append(index >= players.size())
	var game := GameMatch.create(_settings, bot_flags, pawns, _rng)
	game.bot_level = BOT_LEVEL
	var chosen: Dictionary[int, int] = {}
	for index: int in range(players.size()):
		chosen[game.seats[index]] = _colors[players[index]]
		if players[index] != MatchTransport.HOST_PEER:
			_session.seat_peer(players[index], game.seats[index])
	game.colors = SeatColors.with_choices(game.colors.size(), game.seats, chosen)
	MatchStarter.choose(game, _rng)
	return game


func _admit(data: Dictionary) -> int:
	if _started:
		return MatchMessage.Refusal.MATCH_STARTED
	var given: Variant = data.get(MatchMessage.KEY_CODE)
	if not given is String or given != code:
		_count_wrong_code()
		return MatchMessage.Refusal.WRONG_CODE
	if _members.size() + 1 >= seat_count:
		return MatchMessage.Refusal.ROOM_FULL
	return MatchMessage.NO_REFUSAL


func _count_wrong_code() -> void:
	_wrong_codes += 1
	if _wrong_codes >= _settings.max_wrong_codes:
		_renew_code()


## Öncekinden farklı yeni bir oda kodu üretir ve yanlış deneme sayacını sıfırlar.
func _renew_code() -> void:
	var limit := int(pow(DECIMAL_BASE, _settings.room_code_digits))
	var next := code
	while next == code:
		next = str(_rng.randi_range(0, limit - 1)).pad_zeros(_settings.room_code_digits)
	code = next
	_wrong_codes = 0
	code_changed.emit(code)


func _on_welcomed(peer_id: int) -> void:
	_members.append(peer_id)
	_colors[peer_id] = _first_free_color()
	_broadcast()


func _on_peer_left(peer_id: int) -> void:
	if _started or not _members.has(peer_id):
		return
	_members.erase(peer_id)
	_colors.erase(peer_id)
	_broadcast()


## Üyenin renk seçimi; kabul edilmezse üyeye lobinin güncel hâli yeniden gönderilir.
func _on_message(peer_id: int, message: Dictionary) -> void:
	if MatchMessage.type_of(message) != MatchMessage.Type.COLOR_CHOICE:
		return
	if not _members.has(peer_id):
		return
	var color := MessageData.read_int(MatchMessage.data_of(message), MatchMessage.KEY_COLOR)
	if not _choose_color(peer_id, color):
		_send_info(peer_id)


func _choose_color(peer_id: int, color: int) -> bool:
	if _started or color < 0 or color >= LobbyInfo.color_count(_settings):
		return false
	if _colors.values().has(color) and _colors[peer_id] != color:
		return false
	_colors[peer_id] = color
	_broadcast()
	return true


func _first_free_color() -> int:
	var color := 0
	while _colors.values().has(color):
		color += 1
	return color


func _broadcast() -> void:
	for peer_id: int in _members:
		_send_info(peer_id)
	changed.emit()


func _send_info(peer_id: int) -> void:
	_transport.send(peer_id, MatchMessage.lobby(_info_for(_members.find(peer_id) + 1)))


## Lobinin colors içinde own sırasındaki oyuncuya görünen hâli.
func _info_for(own: int) -> LobbyInfo:
	var lobby := LobbyInfo.new()
	lobby.seat_count = seat_count
	lobby.pawns = pawns
	lobby.colors.append(_colors[MatchTransport.HOST_PEER])
	for peer_id: int in _members:
		lobby.colors.append(_colors[peer_id])
	lobby.own = own
	return lobby
