class_name GuestRoom
extends RefCounted
## Ağ oyununda katılan oyuncunun odası: hosta bağlanır, bağlantı kurulunca oda koduyla el sıkışır.
## Host reddederse bağlantı kapatılır ve nedeni bildirilir. Oyun başladıktan sonra bağlantı koparsa
## aynı hosta rejoin_interval_ms aralıkla, yeniden katılma anahtarıyla bağlanmaya çalışılır; deneme
## oda kapatılana, host odayı kapattığını bildirene, hostun oyunu artık tanımadığı anlaşılana ya da
## bağlantı host_lost_sec boyunca kopuk kalana kadar sürer. Bağlantının kopuk olduğu (yeniden
## bağlanılıyor ya da hostun sesi kesildi) ve düzeldiği bildirilir.

## Host el sıkışmayı reddetti (MatchMessage.Refusal); bağlantı kapatıldı.
signal refused(reason: int)
## Bağlantı kayboldu ve oda kapandı (Loss).
signal lost(loss: Loss)
## Oyun sürerken bağlantı koptu (lost true) ya da düzeldi.
signal connection_changed(lost: bool)

## Bağlantı kayboldu ve oda kapandı.
enum Loss {
	## Oyun başlamadan hosta bağlanılamadı ya da bağlantı koptu.
	CONNECT_FAILED,
	## Host odayı kapattı.
	HOST_CLOSED,
	## Host oyunu artık tanımıyor (yeni oda açtı ya da oyun bitti) ya da hosta uzun süre
	## ulaşılamadı.
	HOST_LOST,
}

var session: ClientSession

var _settings: GameSettings
var _transport: ENetTransport
var _address := ""
var _code := ""
var _welcomed := false
## Bağlantı koptu, yeniden bağlanılmaya çalışılıyor.
var _reconnecting := false
## Son bildirilen bağlantı durumu: true ise kopuk.
var _connection_lost := false
## Bağlantı her koptuğunda ve oda kapandığında artar; eski vazgeçme sayacı bununla geçersizleşir.
var _loss_generation := 0


func _init(settings: GameSettings) -> void:
	_settings = settings
	_transport = ENetTransport.new(settings)
	session = ClientSession.new(_transport, settings)
	_transport.peer_connected.connect(_on_connected)
	_transport.closed.connect(_on_closed)
	session.welcomed.connect(_on_welcomed)
	session.refused.connect(_on_refused)
	session.host_silent_changed.connect(_on_host_silent_changed)
	session.closed_by_host.connect(_on_closed_by_host)


## Hosta bağlanmaya başlar; adres izinli değilse ya da bağlantı kurulamazsa false.
func join(address: String, room_code: String) -> bool:
	_address = address
	_code = room_code
	return _transport.join(address)


## Katılırken verilen oda kodu.
func code() -> String:
	return _code


## Odayı kapatır; yeniden bağlanma denemesi durur.
func close() -> void:
	_reconnecting = false
	_loss_generation += 1
	_transport.close()


func _on_connected(peer_id: int) -> void:
	if peer_id == MatchTransport.HOST_PEER:
		session.join(_code)


func _on_welcomed() -> void:
	_welcomed = true
	_reconnecting = false
	_report_connection()


## Yeniden bağlanırken gelen ret, hostun oyunu artık tanımadığını gösterir.
func _on_refused(reason: int) -> void:
	var was_reconnecting := _reconnecting
	close()
	if was_reconnecting:
		lost.emit(Loss.HOST_LOST)
	else:
		refused.emit(reason)


func _on_closed_by_host() -> void:
	close()
	lost.emit(Loss.HOST_CLOSED)


func _on_host_silent_changed(_silent: bool) -> void:
	_report_connection()


## Oyun sürerken kopan bağlantı yeniden kurulmaya çalışılır; oyundan önce kopan bağlantı odayı
## kapatır.
func _on_closed() -> void:
	if _reconnecting:
		_retry_later()
	elif session.view != null:
		_reconnecting = true
		session.drop_connection()
		_report_connection()
		_retry_later()
	else:
		lost.emit(Loss.HOST_LOST if _welcomed else Loss.CONNECT_FAILED)


func _retry_later() -> void:
	var delay := _settings.rejoin_interval_ms / ClientSource.MSEC_PER_SECOND
	Engine.get_main_loop().create_timer(delay).timeout.connect(_retry)


## Oda bu arada kapatıldıysa denenmez.
func _retry() -> void:
	if _reconnecting and not _transport.join(_address):
		_retry_later()


func _report_connection() -> void:
	var connection_lost := _reconnecting or session.is_host_silent()
	if connection_lost != _connection_lost:
		_connection_lost = connection_lost
		_loss_generation += 1
		if connection_lost:
			_give_up_later()
		connection_changed.emit(connection_lost)


## Bağlantı host_lost_sec boyunca kopuk kalırsa oda kapanır ve host kaybedilmiş sayılır.
func _give_up_later() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var timer := tree.create_timer(_settings.host_lost_wait_time)
	timer.timeout.connect(_give_up.bind(_loss_generation))


func _give_up(generation: int) -> void:
	if generation == _loss_generation:
		close()
		lost.emit(Loss.HOST_LOST)
