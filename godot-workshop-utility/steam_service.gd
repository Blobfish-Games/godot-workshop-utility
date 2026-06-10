extends Node

signal log_message(message)
signal tags_set(tags)

const STEAM_WORKSHOP_AGREEMENT_URL: String = "https://steamcommunity.com/sharedfiles/workshoplegalagreement"

var steam_app_id: int = -1
var steam_workshop_tags: Array = []


func _ready() -> void:
	get_window().content_scale_factor = DisplayServer.screen_get_scale()


func initialize() -> void:
	var init_result: Dictionary = Steam.steamInitEx()
	if init_result["status"] == 0:
		log_message.emit("Steam initialization OK!")
	else:
		log_message.emit("Steam could not initialize: %s" % str(init_result))

	var game_install_directory := get_game_dir()

	var file: FileAccess = FileAccess.open(game_install_directory.path_join("steam_data.json"), FileAccess.READ)
	if file != null:
		var test_json_conv = JSON.new()
		test_json_conv.parse(file.get_as_text())
		var file_content: Dictionary = test_json_conv.get_data()
		file.close()

		if !file_content.has("app_id"):
			emit_signal("log_message", "The steam_data file does not contain an app ID, mod uploading will not work.")
			return

		if file_content.has("tags"):
			steam_workshop_tags = file_content.tags as Array
			emit_signal("tags_set", steam_workshop_tags)

		steam_app_id = file_content.app_id as int
	else:
		log_message.emit("Can't open steam_data file %s. Please make sure the file exists and is valid." % game_install_directory.path_join("steam_data.json"))


func get_game_dir() -> String:
	var game_install_directory := OS.get_executable_path().get_base_dir()

	if OS.get_name() == "OSX":
		game_install_directory = game_install_directory.get_base_dir().get_base_dir()
		if game_install_directory.ends_with(".app"):
			game_install_directory = game_install_directory.get_base_dir()

	if OS.has_feature("editor"):
		game_install_directory = "res://"

	return game_install_directory
