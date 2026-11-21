class_name MatchMessage
extends RefCounted
## Ağ mesajının zarfı: {"t": tür, "d": içerik}. İçerik, türüne göre niyetin, olayın ya da
## görünümün sözlüğüdür. Zarf bozuksa tür INVALID olarak okunur ve mesaj yok sayılır.

enum Type {
	## İstemciden hosta: oyuncunun niyeti (MatchIntent).
	INTENT,
	## Hosttan istemciye: hakemin olayı (MatchEvent), alıcının görebildiği kadarıyla, ve olayın sıra
	## numarası.
	EVENT,
	## Hosttan istemciye: oyunun alıcıya görünen tamamı (MatchView).
	SNAPSHOT,
	## Hosttan istemciye: niyet reddedildi; içerik reddedilen niyettir.
	REJECTED,
	## İstemciden hosta: kopya olayla uyuşmadı, görünümün tamamı isteniyor. İçerik boştur.
	SNAPSHOT_REQUEST,
	## İstemciden hosta, bağlanınca: protokol sürümü, ayar özeti, oda kodu ve (yeniden bağlanırken)
	## yeniden katılma anahtarı.
	HELLO,
	## Hosttan istemciye: el sıkışma kabul edildi; içerik, bağlantı koparsa koltuğa geri dönmek için
	## kullanılan yeniden katılma anahtarıdır.
	WELCOME,
	## Hosttan istemciye: el sıkışma reddedildi; içerik nedendir (Refusal).
	REFUSED,
	## Hosttan yerel ağa (oyun bulma yayını): protokol sürümü, oyun portu ve oyuncu sayısı. Kişisel
	## bilgi taşımaz.
	ANNOUNCE,
	## Hosttan istemciye: lobinin alıcıya görünen hâli (LobbyInfo).
	LOBBY,
	## İstemciden hosta: lobide seçilen renk.
	COLOR_CHOICE,
	## İstemciden hosta: oyuncu oyundan çıktı; koltuğunu kalıcı olarak bot alır. İçerik boştur.
	LEAVE,
	## İstemciden hosta: ekran olayı bitirdi; içerik olayın sıra numarasıdır. Host bütün ekranlar son
	## olayı bitirince sıradakini yayar; eski olayın bildirimi (ör. sesi kesilip dönen eşten) sayılmaz.
	EVENT_DONE,
	## Hosttan istemciye: sıradaki insan oyuncunun sıra süresi başladı; koltuk ve saniye.
	TURN_TIMER,
	## İki yönde: bağlantı sürüyor. Bir süre hiç mesaj gelmeyen eş uzakta sayılır. İçerik boştur.
	HEARTBEAT,
	## Hosttan istemciye: oyuncunun bağlantı durumu; koltuk ve koltuğu bot alana kadar kalan saniye
	## (SeatPresence.PRESENT ise oyuncu bağlı).
	SEAT_STATUS,
	## Hosttan istemciye: host odayı kapattı. İçerik boştur.
	CLOSED,
	## Hosttan istemciye: host oyunu molaya aldı. İçerik boştur.
	PAUSED,
	## Hosttan istemciye: host oyunu moladan çıkardı. İçerik boştur.
	RESUMED,
}

## El sıkışmanın reddedilme nedeni.
enum Refusal {
	## Protokol sürümü ya da ayar özeti farklı; oyuncunun oyunu güncellemesi gerekir.
	VERSION_MISMATCH,
	## Oda kodu yanlış.
	WRONG_CODE,
	## Lobideki koltuklar dolu.
	ROOM_FULL,
	## Oyun başladı; yeni oyuncu alınmıyor.
	MATCH_STARTED,
	## Yeniden katılma anahtarı bu odanın oyununda yok (host yeni oda açtı ya da oyun bitti).
	NOT_IN_MATCH,
}

## El sıkışma kabul edildiğinde ret nedeni yerine kullanılır.
const NO_REFUSAL := -1

## Mesaj biçimi değişince artırılır; farklı sürümler birbirine bağlanmaz.
const PROTOCOL_VERSION := 7
const KEY_TYPE := "t"
const KEY_DATA := "d"
const KEY_PROTOCOL := "protocol"
const KEY_DIGEST := "digest"
const KEY_REASON := "reason"
const KEY_PORT := "port"
const KEY_PLAYERS := "players"
const KEY_CODE := "code"
const KEY_COLOR := "color"
## Görünümle birlikte giden, hostun oyun hızı seviyesi (GameSpeed.Level).
const KEY_SPEED := "speed"
## Görünümle birlikte giden bayrak: host, görünümün sahibinin niyetini bekliyor.
const KEY_AWAITING := "awaiting"
## Görünümle birlikte giden, sıradaki oyuncunun sıra süresinden kalan (saniye).
const KEY_TURN_TIME := "turn_time"
## Görünümle birlikte giden, molanın başından beri geçen süre (saniye); mola yoksa
## MatchReferee.NOT_PAUSED.
const KEY_PAUSE := "pause"
const KEY_SECONDS := "seconds"
const KEY_TOKEN := "token"
const KEY_SERIAL := "serial"


static func make(type: Type, data: Dictionary) -> Dictionary:
	return {KEY_TYPE: type, KEY_DATA: data}


static func intent(player_intent: MatchIntent) -> Dictionary:
	return make(Type.INTENT, player_intent.to_dict())


static func event(match_event: MatchEvent, viewer_seat: int, serial: int) -> Dictionary:
	var data := match_event.to_dict(viewer_seat)
	data[KEY_SERIAL] = serial
	return make(Type.EVENT, data)


## Görünüm, hostun oyun hızıyla ve hostun bu oyuncunun niyetini bekleyip beklemediğiyle birlikte
## gider; istemci animasyonları bu hızla oynatır. Sıra süresi işliyorsa kalanı, oyun moladaysa
## molanın süresi de gider.
static func snapshot(
	view: MatchView,
	speed_level: int,
	awaiting := false,
	turn_time := MatchReferee.NO_TURN_TIMER,
	pause_time := MatchReferee.NOT_PAUSED,
) -> Dictionary:
	var data := view.to_dict()
	data[KEY_SPEED] = speed_level
	data[KEY_AWAITING] = awaiting
	data[KEY_TURN_TIME] = turn_time
	data[KEY_PAUSE] = pause_time
	return make(Type.SNAPSHOT, data)


static func turn_timer(seat: int, seconds: float) -> Dictionary:
	return make(Type.TURN_TIMER, {MessageData.KEY_SEAT: seat, KEY_SECONDS: seconds})


static func rejected(player_intent: MatchIntent) -> Dictionary:
	return make(Type.REJECTED, player_intent.to_dict())


static func leave() -> Dictionary:
	return make(Type.LEAVE, {})


static func event_done(serial: int) -> Dictionary:
	return make(Type.EVENT_DONE, {KEY_SERIAL: serial})


static func snapshot_request() -> Dictionary:
	return make(Type.SNAPSHOT_REQUEST, {})


## token boş değilse eş, bağlantısı kopan oyuncunun koltuğuna geri dönmek istiyordur.
static func hello(settings: GameSettings, room_code: String = "", token: String = "") -> Dictionary:
	return make(
		Type.HELLO,
		{
			KEY_PROTOCOL: PROTOCOL_VERSION,
			KEY_DIGEST: settings.digest,
			KEY_CODE: room_code,
			KEY_TOKEN: token,
		}
	)


static func welcome(token: String) -> Dictionary:
	return make(Type.WELCOME, {KEY_TOKEN: token})


static func heartbeat() -> Dictionary:
	return make(Type.HEARTBEAT, {})


static func seat_status(seat: int, seconds: float) -> Dictionary:
	return make(Type.SEAT_STATUS, {MessageData.KEY_SEAT: seat, KEY_SECONDS: seconds})


static func closed() -> Dictionary:
	return make(Type.CLOSED, {})


static func paused() -> Dictionary:
	return make(Type.PAUSED, {})


static func resumed() -> Dictionary:
	return make(Type.RESUMED, {})


## İçerikteki yeniden katılma anahtarı; yoksa ya da metin değilse boş.
static func token_of(data: Dictionary) -> String:
	var token: Variant = data.get(KEY_TOKEN)
	return token if token is String else ""


static func refused(reason: Refusal) -> Dictionary:
	return make(Type.REFUSED, {KEY_REASON: reason})


static func announce(port: int, players: int) -> Dictionary:
	return make(
		Type.ANNOUNCE, {KEY_PROTOCOL: PROTOCOL_VERSION, KEY_PORT: port, KEY_PLAYERS: players}
	)


static func lobby(info: LobbyInfo) -> Dictionary:
	return make(Type.LOBBY, info.to_dict())


static func color_choice(color: int) -> Dictionary:
	return make(Type.COLOR_CHOICE, {KEY_COLOR: color})


## HELLO içeriği bu cihazla aynı protokol sürümünü ve ayar özetini taşıyorsa true.
static func is_compatible(data: Dictionary, settings: GameSettings) -> bool:
	return (
		MessageData.read_int(data, KEY_PROTOCOL) == PROTOCOL_VERSION
		and data.get(KEY_DIGEST) is String
		and data[KEY_DIGEST] == settings.digest
	)


## Mesajın türü; zarf bozuksa MessageData.INVALID.
static func type_of(message: Dictionary) -> int:
	var type := MessageData.read_int(message, KEY_TYPE)
	if (
		not MessageData.is_enum_value(type, Type.values())
		or not message.get(KEY_DATA) is Dictionary
	):
		return MessageData.INVALID
	return type


## Mesajın içeriği; yoksa boş sözlük.
static func data_of(message: Dictionary) -> Dictionary:
	return MessageData.read_dict(message, KEY_DATA)
