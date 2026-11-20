@tool
extends EditorPlugin
## Android dışa aktarmasına isteğe bağlı donanım özellikleri eklentisini bağlar.

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	_export_plugin = PortraitExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


## Android bazı donanım özelliklerini dolaylı olarak zorunlu sayar ve Play bu yüzden uyarı verir:
## dikey ekran yönü `android.hardware.screen.portrait`, Wi-Fi izinleri (ağ oyunu)
## `android.hardware.wifi` özelliğini zorunlu yapar. Özellikler `required="false"` ile açıkça
## yazılınca uyarı kalkar ve uygulama yalnızca yatay ekranı ya da Wi-Fi'ı olmayan cihazlarda da
## listelenir; ağ oyunu dışında oyun Wi-Fi olmadan çalışır.
class PortraitExportPlugin:
	extends EditorExportPlugin

	const FEATURE_NAMES: Array[String] = [
		"android.hardware.screen.portrait",
		"android.hardware.wifi",
	]
	const OPTIONAL_FEATURE := '<uses-feature android:name="%s" android:required="false" />'

	func _get_name() -> String:
		return "PortraitFeature"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_manifest_element_contents(
		_platform: EditorExportPlatform, _debug: bool
	) -> String:
		var elements: PackedStringArray = []
		for feature_name: String in FEATURE_NAMES:
			elements.append(OPTIONAL_FEATURE % feature_name)
		return "\n".join(elements)
