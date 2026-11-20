class_name MatchMessage
extends RefCounted
## Ağ mesajının zarfı: {"t": tür, "d": içerik}. İçerik, türüne göre niyetin, olayın ya da
## görünümün sözlüğüdür. Zarf bozuksa tür INVALID olarak okunur ve mesaj yok sayılır.

enum Type {
	## İstemciden hosta: oyuncunun niyeti (MatchIntent).
	INTENT,
	## Hosttan istemciye: hakemin olayı (MatchEvent), alıcının görebildiği kadarıyla.
	EVENT,
	## Hosttan istemciye: oyunun alıcıya görünen tamamı (MatchView).
	SNAPSHOT,
	## Hosttan istemciye: niyet reddedildi; içerik reddedilen niyettir.
	REJECTED,
	## İstemciden hosta: kopya olayla uyuşmadı, görünümün tamamı isteniyor. İçerik boştur.
	SNAPSHOT_REQUEST,
}

const KEY_TYPE := "t"
const KEY_DATA := "d"


static func make(type: Type, data: Dictionary) -> Dictionary:
	return {KEY_TYPE: type, KEY_DATA: data}


static func intent(player_intent: MatchIntent) -> Dictionary:
	return make(Type.INTENT, player_intent.to_dict())


static func event(match_event: MatchEvent, viewer_seat: int) -> Dictionary:
	return make(Type.EVENT, match_event.to_dict(viewer_seat))


static func snapshot(view: MatchView) -> Dictionary:
	return make(Type.SNAPSHOT, view.to_dict())


static func rejected(player_intent: MatchIntent) -> Dictionary:
	return make(Type.REJECTED, player_intent.to_dict())


static func snapshot_request() -> Dictionary:
	return make(Type.SNAPSHOT_REQUEST, {})


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
