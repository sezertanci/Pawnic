class_name MatchTransport
extends RefCounted
## Ağ oyununda mesajları eşler arasında taşıyan katmanın arayüzü. Gerçek taşıyıcı (yerel ağ) ve
## testteki sahte sürüm bundan türer. Eşler sayıyla tanınır; host her zaman HOST_PEER'dir.

## Bir eşten mesaj geldi. Mesaj güvenilmezdir; okuyan taraf MatchMessage ile denetler.
signal message_received(peer_id: int, message: Dictionary)
## Bir eş bağlandı (istemcide host).
signal peer_connected(peer_id: int)
## Bir eşin bağlantısı koptu.
signal peer_disconnected(peer_id: int)

## Oyunu kuran cihazın eş numarası.
const HOST_PEER := 1


## Bu cihazın eş numarası.
func own_peer() -> int:
	return HOST_PEER


## Mesajı eşe gönderir. Mesaj yalnızca sözlük, dizi, sayı, metin ve mantıksal değer içerir.
func send(_peer_id: int, _message: Dictionary) -> void:
	pass
