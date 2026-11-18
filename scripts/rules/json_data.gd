class_name JsonData
extends RefCounted
## data/ altındaki JSON ayar dosyalarını okur.


## Dosyayı sözlük olarak okur. Dosya okunamazsa, kökü sözlük değilse ya da required
## anahtarlarından biri eksikse hatayı yazar ve boş sözlük döner.
static func read(path: String, required: Array[String]) -> Dictionary:
	var root: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not root is Dictionary:
		push_error("JSON dosyası okunamadı: %s" % path)
		return {}
	if not (root as Dictionary).has_all(required):
		push_error("JSON dosyasında gerekli anahtar eksik: %s %s" % [path, required])
		return {}
	return root
