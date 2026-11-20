class_name GameAnnouncer
extends RefCounted
## Hostun oyun bulma yayıncısı: belli aralıkla yerel ağa "burada oyun var" yayını (UDP) gönderir.
## Yayında yalnızca protokol sürümü, oyun portu ve oyuncu sayısı vardır; oda kodu ve kişisel bilgi
## yoktur. Yayın hostun özel ağ adresinden çıkar. Gönderim her karede zamanı gelince yapılır.

## Yerel ağın tamamına yayın adresi.
const BROADCAST := "255.255.255.255"
## Gönderen soketin portu: işletim sistemi boş bir port seçer.
const ANY_PORT := 0

## Yayında bildirilen oyuncu sayısı; lobi değiştikçe güncellenir.
var player_count := 1

var _settings: GameSettings
var _socket: PacketPeerUDP
var _next_msec := 0


func _init(settings: GameSettings) -> void:
	_settings = settings
	Engine.get_main_loop().process_frame.connect(_tick)


## Yayını başlatır; ilk yayın hemen gider. Adres izinli değilse ya da soket açılamazsa false.
## target yalnızca testte değişir (aynı cihaza yayın).
func start(bind_address: String, target: String = BROADCAST) -> bool:
	if _socket != null or not LocalAddress.is_allowed(bind_address):
		return false
	var socket := PacketPeerUDP.new()
	socket.set_broadcast_enabled(true)
	if socket.bind(ANY_PORT, bind_address) != OK:
		return false
	socket.set_dest_address(target, _settings.discovery_port)
	_socket = socket
	_next_msec = Time.get_ticks_msec()
	return true


func stop() -> void:
	if _socket != null:
		_socket.close()
		_socket = null


func _tick() -> void:
	var now := Time.get_ticks_msec()
	if _socket == null or now < _next_msec:
		return
	_next_msec = now + _settings.announce_interval_ms
	var message := MatchMessage.announce(_settings.network_port, player_count)
	_socket.put_packet(var_to_bytes(message))
