class_name HostRoom
extends RefCounted
## Ağ oyununda hostun odası: ENet taşıyıcısını, oturumu, lobiyi ve oyun bulma yayınını birlikte
## kurar ve kapatır. Yayındaki oyuncu sayısı lobi değiştikçe güncellenir; oyun başlayınca yayın
## durur (başlamış oyuna katılınamaz). Her oda bir kez açılır; yeniden açmak için yeni oda kurulur.

var session: HostSession
var lobby: HostLobby

var _transport: ENetTransport
var _announcer: GameAnnouncer


func _init(settings: GameSettings, referee: MatchReferee, rng: RandomNumberGenerator) -> void:
	_transport = ENetTransport.new(settings)
	_announcer = GameAnnouncer.new(settings)
	session = HostSession.new(referee, _transport, settings)
	lobby = HostLobby.new(settings, _transport, session, rng)
	lobby.changed.connect(_on_lobby_changed)


## Hostu verilen adreste kurar ve yayını başlatır; biri olmazsa oda kapatılır ve false döner.
## target yalnızca testte değişir (aynı cihaza yayın).
func open(address: String, target: String = GameAnnouncer.BROADCAST) -> bool:
	if _transport.host(address) and _announcer.start(address, target):
		return true
	close()
	return false


## Lobideki oyunu başlatır ve yayını durdurur; oyun zaten başladıysa null (HostLobby.start()).
func start_match() -> GameMatch:
	var game := lobby.start()
	if game != null:
		_announcer.stop()
	return game


func close() -> void:
	_announcer.stop()
	_transport.close()


func _on_lobby_changed() -> void:
	_announcer.player_count = lobby.info().colors.size()
