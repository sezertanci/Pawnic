class_name BoardEntry
extends RefCounted
## Ayar dosyasındaki tahta listesinin bir öğesi: tahtanın kimliği, tahta dosyasının yolu, adının
## çeviri anahtarı, seçim kartındaki görselin yolu ve ödüllü reklamla açılıp açılmadığı.

const KEY_ID := "id"
const KEY_LAYOUT := "layout"
const KEY_NAME := "name"
const KEY_PREVIEW := "preview"
const KEY_NEEDS_UNLOCK := "needs_unlock"

var id := ""
var layout_path := ""
var name_key := ""
var preview_path := ""
var needs_unlock := false


static func from_dict(data: Dictionary) -> BoardEntry:
	var entry := BoardEntry.new()
	entry.id = str(data[KEY_ID])
	entry.layout_path = str(data[KEY_LAYOUT])
	entry.name_key = str(data[KEY_NAME])
	entry.preview_path = str(data[KEY_PREVIEW])
	entry.needs_unlock = bool(data[KEY_NEEDS_UNLOCK])
	return entry
