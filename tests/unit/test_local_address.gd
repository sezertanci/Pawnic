extends GutTest
## Yerel adres yardımcısı: yalnızca özel ağ adresleri ve aynı cihaz kabul edilir.

const PRIVATE: Array[String] = ["10.0.0.5", "172.16.1.2", "172.31.255.1", "192.168.1.20"]
const NOT_PRIVATE: Array[String] = [
	"8.8.8.8", "172.15.0.1", "172.32.0.1", "192.169.1.1", "127.0.0.1", "0.0.0.0"
]
const MALFORMED: Array[String] = ["", "192.168.1", "192.168.1.1.1", "192.168.1.x", "192.168.1.256"]


func test_private_addresses_are_recognised() -> void:
	for address: String in PRIVATE:
		assert_true(LocalAddress.is_private(address), address)


func test_public_and_special_addresses_are_not_private() -> void:
	for address: String in NOT_PRIVATE + MALFORMED:
		assert_false(LocalAddress.is_private(address), address)


func test_loopback_is_allowed_but_public_is_not() -> void:
	assert_true(LocalAddress.is_allowed(LocalAddress.LOOPBACK))
	assert_false(LocalAddress.is_allowed("8.8.8.8"))


func test_wifi_address_is_private_or_empty() -> void:
	var address := LocalAddress.wifi_address()

	assert_true(address.is_empty() or LocalAddress.is_private(address), address)
