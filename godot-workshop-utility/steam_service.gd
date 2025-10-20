extends Node

signal log_message(message)
signal tags_set(tags)

const STEAM_WORKSHOP_AGREEMENT_URL: String = "https://steamcommunity.com/sharedfiles/workshoplegalagreement"

var steam_app_id: int = -1
var steam_workshop_tags: Array = []


func initialize() -> void:
	var init_result: Dictionary = Steam.steamInitEx(0, true)
	if init_result["status"] == 0:
		emit_signal("log_message", "Steam initialization OK!")
	else:
		emit_signal("log_message", "Steam could not initialize: %s" % str(init_result))

	var game_install_directory := get_game_dir()

	var file = File.new()

	if file.open(game_install_directory.plus_file("steam_data.json"), File.READ) == OK:
		var file_content: Dictionary = parse_json(file.get_as_text())
		file.close()

		if !file_content.has("app_id"):
			emit_signal("log_message", "The steam_data file does not contain an app ID, mod uploading will not work.")
			return

		if file_content.has("tags"):
			steam_workshop_tags = file_content.tags as Array
			emit_signal("tags_set", steam_workshop_tags)

		steam_app_id = file_content.app_id as int
	else:
		emit_signal("log_message", "Can't open steam_data file %s. Please make sure the file exists and is valid." % game_install_directory.plus_file("steam_data.json"))


func get_game_dir() -> String:
	var game_install_directory := OS.get_executable_path().get_base_dir()

	if OS.get_name() == "OSX":
		game_install_directory = game_install_directory.get_base_dir().get_base_dir()
		if game_install_directory.ends_with(".app"):
			game_install_directory = game_install_directory.get_base_dir()

	if OS.has_feature("editor"):
		game_install_directory = "res://"

	return game_install_directory
