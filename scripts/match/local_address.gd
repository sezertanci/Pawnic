class_name LocalAddress
extends RefCounted
## Yerel ağ adresleri. Host yalnızca özel ağdaki IPv4 adresinde dinler (her arayüzde değil; mobil
## veride dışarıdan erişilebilir adres olabilir). QR ve oda kodundan gelen adres de güvenilmez
## veridir; yalnızca özel ağ adreslerine bağlanılır.

## Android'de Wi-Fi arayüzünün adının başı.
const WIFI_PREFIX := "wlan"
const OCTET_COUNT := 4
const OCTET_MAX := 255
## Aynı cihazın adresi; dışarıdan erişilemez, aynı cihazdaki iki uçla deneme için kullanılır.
const LOOPBACK := "127.0.0.1"
## Özel ağ aralıkları: ilk sayı ve ikinci sayının izin verilen en küçük ve en büyük değeri.
const PRIVATE_RANGES: Array[Array] = [[10, 0, 255], [172, 16, 31], [192, 168, 168]]


## Adres özel ağdaki (10.x, 172.16–31.x, 192.168.x) bir IPv4 adresiyse true.
static func is_private(address: String) -> bool:
	var parts := address.split(".")
	if parts.size() != OCTET_COUNT:
		return false
	for part: String in parts:
		if not part.is_valid_int() or int(part) < 0 or int(part) > OCTET_MAX:
			return false
	var first := int(parts[0])
	var second := int(parts[1])
	return PRIVATE_RANGES.any(
		func(span: Array) -> bool:
			return first == span[0] and second >= span[1] and second <= span[2]
	)


## Taşıyıcının dinleyebileceği ya da bağlanabileceği adres: özel ağ adresi ya da aynı cihaz.
static func is_allowed(address: String) -> bool:
	return address == LOOPBACK or is_private(address)


## Hostun dinleyeceği adres: Wi-Fi arayüzündeki özel IPv4 adresi, yoksa herhangi bir arayüzdeki
## ilk özel IPv4 adresi (bilgisayarda kablolu ağ). Hiçbiri yoksa boş metin.
static func wifi_address() -> String:
	var fallback := ""
	for interface: Dictionary in IP.get_local_interfaces():
		for address: String in interface["addresses"]:
			if not is_private(address):
				continue
			if String(interface["name"]).begins_with(WIFI_PREFIX):
				return address
			if fallback.is_empty():
				fallback = address
	return fallback
