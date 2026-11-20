class_name MessageData
extends RefCounted
## Ağdan gelen mesaj sözlüklerini savunmacı okur. Gelen veri güvenilmezdir: eksik ya da yanlış
## türdeki alan çökertmez, okuyan tarafa "geçersiz" olarak döner.

## Sayı okunamadığında döner; geçerli alanlarda bu değer kullanılmaz.
const INVALID := -2147483648
## Birden çok mesajda geçen anahtarlar.
const KEY_KIND := "kind"
const KEY_SEAT := "seat"
const KEY_CARD_INDEX := "card_index"
const KEY_MOVE := "move"


## Değer tam sayı ya da (JSON'dan gelmiş olabilecek) ondalık sayıysa true.
static func is_number(value: Variant) -> bool:
	return value is int or value is float


## Anahtardaki sayıyı verir; yoksa ya da sayı değilse INVALID.
static func read_int(data: Dictionary, key: String) -> int:
	var value: Variant = data.get(key)
	return int(value) if is_number(value) else INVALID


## Anahtardaki sayı [low, high) aralığındaysa onu, değilse INVALID verir.
static func read_index(data: Dictionary, key: String, low: int, high: int) -> int:
	var value := read_int(data, key)
	return value if value >= low and value < high else INVALID


## Anahtardaki sözlüğü verir; yoksa ya da sözlük değilse boş sözlük.
static func read_dict(data: Dictionary, key: String) -> Dictionary:
	var value: Variant = data.get(key)
	return value if value is Dictionary else {}


## Anahtardaki sayı dizisini verir; dizi değilse ya da sayı olmayan öğe varsa null.
static func read_ints(data: Dictionary, key: String) -> Variant:
	var value: Variant = data.get(key)
	if not value is Array:
		return null
	var result: Array[int] = []
	for item: Variant in value:
		if not is_number(item):
			return null
		result.append(int(item))
	return result


## Değer enum'un değerlerinden biriyse true.
static func is_enum_value(value: int, values: Array) -> bool:
	return value != INVALID and values.has(value)
