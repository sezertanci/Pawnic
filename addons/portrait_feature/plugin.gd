@tool
extends EditorPlugin
## Android dışa aktarmasına dikey ekran özelliği eklentisini bağlar.

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	_export_plugin = PortraitExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	remove_export_plugin(_export_plugin)
	_export_plugin = null


## Ekran yönü dikey olunca Android `android.hardware.screen.portrait` özelliğini dolaylı olarak
## zorunlu sayar ve Play bu yüzden uyarı verir. Özellik `required="false"` ile açıkça yazılınca
## uyarı kalkar ve uygulama yalnızca yatay ekranı olan cihazlarda da listelenir.
class PortraitExportPlugin:
	extends EditorExportPlugin

	const FEATURE_NAME := "android.hardware.screen.portrait"
	const OPTIONAL_FEATURE := '<uses-feature android:name="%s" android:required="false" />'

	func _get_name() -> String:
		return "PortraitFeature"

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_android_manifest_element_contents(
		_platform: EditorExportPlatform, _debug: bool
	) -> String:
		return OPTIONAL_FEATURE % FEATURE_NAME
