class_name GameFinder
extends RefCounted
## İstemcinin oyun bulucusu: oyun bulma portunu dinler ve yayın yapan hostları listeler. Yayın
## güvenilmez veridir: özel ağ dışından gelen, büyük, bozuk ya da başka protokol sürümündeki yayın
## atılır. Süresi içinde yeniden yayın yapmayan oyun listeden çıkar. Yayın her arayüze gelebildiği
## için her arayüzde dinlenir; soket yalnızca okur, gelen veriyle bağlantı kurulmaz.

## Bulunanlar listesi değişti (oyun eklendi, çıktı ya da oyuncu sayısı değişti).
signal games_changed

## Her arayüzde dinler.
const ANY_ADDRESS := "*"
## Geçerli port aralığı [en küçük, en büyük + 1).
const PORT_MIN := 1
const PORT_END := 65536

var _settings: GameSettings
var _socket: PacketPeerUDP
## Bulunan oyunlar: hostun adresi → oyun.
var _games: Dictionary[String, FoundGame] = {}


func _init(settings: GameSettings) -> void:
	_settings = settings
	Engine.get_main_loop().process_frame.connect(_poll)


## Dinlemeye başlar; port açılamazsa false.
func start() -> bool:
	if _socket != null:
		return false
	var socket := PacketPeerUDP.new()
	if socket.bind(_settings.discovery_port, ANY_ADDRESS) != OK:
		return false
	_socket = socket
	return true


## Dinleme sürüyor mu (start() başarılı ve stop() çağrılmadı).
func is_listening() -> bool:
	return _socket != null


func stop() -> void:
	if _socket != null:
		_socket.close()
		_socket = null
	_games.clear()


## Bulunan oyunlar.
func games() -> Array[FoundGame]:
	return _games.values()


func _poll() -> void:
	if _socket == null:
		return
	var changed := false
	while _socket.get_available_packet_count() > 0:
		var bytes := _socket.get_packet()
		changed = _read(_socket.get_packet_ip(), bytes) or changed
	changed = _drop_expired() or changed
	if changed:
		games_changed.emit()


## Yayını okur; listeye yeni oyun eklendiyse ya da oyuncu sayısı değiştiyse true.
func _read(address: String, bytes: PackedByteArray) -> bool:
	if not LocalAddress.is_allowed(address) or bytes.size() > _settings.max_message_bytes:
		return false
	var message: Variant = bytes_to_var(bytes)
	if not message is Dictionary or MatchMessage.type_of(message) != MatchMessage.Type.ANNOUNCE:
		return false
	var data := MatchMessage.data_of(message)
	var port := MessageData.read_index(data, MatchMessage.KEY_PORT, PORT_MIN, PORT_END)
	var players := MessageData.read_index(
		data, MatchMessage.KEY_PLAYERS, 1, _settings.max_players + 1
	)
	var protocol := MessageData.read_int(data, MatchMessage.KEY_PROTOCOL)
	if protocol != MatchMessage.PROTOCOL_VERSION or MessageData.INVALID in [port, players]:
		return false
	return _record(address, port, players)


func _record(address: String, port: int, players: int) -> bool:
	var game: FoundGame = _games.get(address)
	var changed := game == null or game.port != port or game.players != players
	if game == null:
		game = FoundGame.new()
		game.address = address
		_games[address] = game
	game.port = port
	game.players = players
	game.seen_msec = Time.get_ticks_msec()
	return changed


## Süresi dolan oyunları listeden çıkarır; çıkan varsa true.
func _drop_expired() -> bool:
	var limit := Time.get_ticks_msec() - _settings.announce_expiry_ms
	var expired := _games.keys().filter(
		func(address: String) -> bool: return _games[address].seen_msec < limit
	)
	for address: String in expired:
		_games.erase(address)
	return not expired.is_empty()
