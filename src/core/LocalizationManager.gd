# localization_manager.gd
class_name LocalizationManager extends Node

# 信号定义
signal language_changed(new_lang: String)
signal translation_missing(key: String, lang: String)

# 公共属性
var current_language: String = "zh"
var fallback_language: String = "zh"

# 私有属性
var _translation_packs: Dictionary = {}  # lang_code -> Translation
var _font_cache: Dictionary = {}          # lang_code -> Font
var _is_initialized: bool = false

# 语言映射配置
const LANGUAGE_MAPPING = {
	"zh": "res://resources/translations/localization_zh.tres",
	"en": "res://resources/translations/localization_en.tres",
	"ja": "res://resources/translations/localization_ja.tres"
}

const FONT_MAPPING = {
	"zh": "res://resources/fonts/font_source_han_sans_zh.tres",
	"en": "res://resources/fonts/font_roboto_en.tres",
	"ja": "res://resources/fonts/font_noto_sans_ja.tres"
}

# 初始化方法
func _ready() -> void:
	if not _is_initialized:
		initialize()

# 公共方法
func initialize() -> void:
	if _is_initialized:
		return

	# 加载默认语言包
	_load_translation_pack(current_language)
	_is_initialized = true

func set_language(lang_code: String) -> bool:
	if not LANGUAGE_MAPPING.has(lang_code):
		push_error("Unsupported language: " + lang_code)
		return false

	if lang_code == current_language:
		return true

	# 加载新语言包
	var new_pack = _load_translation_pack(lang_code)
	if new_pack == null:
		push_error("Failed to load translation pack for: " + lang_code)
		return false

	# 更新当前语言
	current_language = lang_code

	# 通知语言变更
	_notify_language_change()
	return true

func get_text(key: String, params: Array = []) -> String:
	# 尝试从当前语言获取翻译
	var translation_pack = _translation_packs.get(current_language)
	if translation_pack != null:
		var translated = translation_pack.get_message(key)
		if translated != null and translated != "":
			return _format_text(translated, params)

	# 回退到备用语言
	if current_language != fallback_language:
		translation_pack = _translation_packs.get(fallback_language)
		if translation_pack != null:
			var translated = translation_pack.get_message(key)
			if translated != null and translated != "":
				return _format_text(translated, params)

	# 最终回退：显示键名
	_handle_missing_translation(key, current_language)
	return "[MISSING: " + key + "]"

func get_available_languages() -> Array:
	var languages = []
	for lang_code in LANGUAGE_MAPPING.keys():
		languages.append({"code": lang_code, "name": _get_language_name(lang_code)})
	return languages

func get_current_language() -> String:
	return current_language

func get_font_for_language(lang_code: String = "") -> Font:
	if lang_code == "":
		lang_code = current_language

	# 检查缓存
	if _font_cache.has(lang_code):
		return _font_cache[lang_code]

	# 加载字体
	if FONT_MAPPING.has(lang_code):
		var font_path = FONT_MAPPING[lang_code]
		var font = load(font_path)
		if font != null:
			_font_cache[lang_code] = font
			return font

	# 回退到默认字体
	push_warning("Failed to load font for language: " + lang_code + ", using default")
	return null

# 内部方法
func _load_translation_pack(lang: String) -> Translation:
	# 检查缓存
	if _translation_packs.has(lang):
		return _translation_packs[lang]

	# 加载翻译包
	if LANGUAGE_MAPPING.has(lang):
		var pack_path = LANGUAGE_MAPPING[lang]
		var pack = load(pack_path)
		if pack != null:
			_translation_packs[lang] = pack
			return pack

	push_error("Failed to load translation pack: " + lang)
	return null

func _get_fallback_text(key: String) -> String:
	var fallback_pack = _translation_packs.get(fallback_language)
	if fallback_pack != null:
		return fallback_pack.get_message(key)
	return ""

func _notify_language_change() -> void:
	emit_signal("language_changed", current_language)

func _handle_missing_translation(key: String, lang: String) -> void:
	emit_signal("translation_missing", key, lang)
	push_warning("Missing translation for key '" + key + "' in language '" + lang + "'")

func _format_text(text: String, params: Array) -> String:
	if params.is_empty():
		return text

	# 替换 {0}, {1}, ... 形式的参数
	for i in range(params.size()):
		text = text.replace("{" + str(i) + "}", str(params[i]))

	return text

func _get_language_name(lang_code: String) -> String:
	match lang_code:
		"zh": return "中文"
		"en": return "English"
		"ja": return "日本語"
		_: return lang_code