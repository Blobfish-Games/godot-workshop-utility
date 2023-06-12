class_name Main
extends PanelContainer

const MOD_LOADER_URL = "https://github.com/GodotModding/godot-mod-loader"

export var max_tags := 5

var tag_dict := {}

onready var _file_dialog = $"%FileDialog" as FileDialog
onready var _preview_image_dialog = $"%PreviewImageDialog" as FileDialog
onready var _file_line_edit = $"%FileLineEdit" as LineEdit
onready var _workshop_id_line_edit = $"%WorkshopIDLineEdit" as LineEdit
onready var _preview_line_edit = $"%PreviewLineEdit" as LineEdit
onready var _scroll_container = $"%ScrollContainer" as ScrollContainer
onready var _scrollbar = $"%ScrollContainer".get_v_scrollbar()
onready var _console = $"%Console" as TextEdit
onready var _console_content = $"%ConsoleContent" as Label
onready var _tag_list = $"%TagList" as ItemList
onready var _tag_container = $"%TagContainer" as VBoxContainer
onready var _upload_container = $"%UploadContainer" as VBoxContainer
onready var _tag_label = $"%TagLabel" as Label


func _ready() -> void:
	_tag_container.hide()
	_upload_container.size_flags_horizontal = SIZE_SHRINK_CENTER
	
	SteamService.connect("log_message", self, "log_in_console")
	SteamService.connect("tags_set", self, "on_tags_set")
	SteamService.initialize()
	
	var _error_create = Steam.connect("item_created", self, "on_workshop_mod_created")
	var _error_update = Steam.connect("item_updated", self, "on_workshop_mod_updated")


func log_in_console(msg: String) -> void:
	var date_time = Time.get_datetime_dict_from_system()
	var date_prefix = "%02d:%02d:%02d - " % [date_time.hour, date_time.minute, date_time.second]
	
	if _console_content.text == "":
		_console_content.text += date_prefix + msg
	else:
		_console_content.text += "\n" + date_prefix + msg
	
	_scroll_container.scroll_vertical = _scrollbar.max_value


func on_tags_set(tags: Array) -> void:
	_tag_container.show()
	_upload_container.size_flags_horizontal = SIZE_FILL
	_tag_label.text += " (%s max)" % [max_tags]
	
	for i in tags.size():
		tag_dict[i] = tags[i]
		_tag_list.add_item(tags[i])


func _on_UploadButton_pressed() -> void:
	
	if _file_line_edit.text == "":
		log_in_console("No mod selected.")
		return
	
	if _workshop_id_line_edit.text == "":
		log_in_console("No workshop ID provided, creating new workshop item for app %s..." % SteamService.steam_app_id)
		Steam.createItem(SteamService.steam_app_id, 0)
	else:
		update_workshop_item()


func update_workshop_item() -> void:
	log_in_console("Uploading workshop item with ID %s..." % _workshop_id_line_edit.text)
	var update_handle = Steam.startItemUpdate(SteamService.steam_app_id, int(_workshop_id_line_edit.text))
	
	Steam.setItemTitle(update_handle, _file_line_edit.text.get_basename().get_file())
	
	var file = File.new()
	var preview_path = ProjectSettings.globalize_path(_preview_line_edit.text)
	
	if file.file_exists(preview_path):
		Steam.setItemPreview(update_handle, preview_path)
	
	if _tag_list.get_selected_items().size() > 0:
		var tag_names = []
		var nb_tags_added = 0
		
		for selected_tag in _tag_list.get_selected_items():
			
			if nb_tags_added >= max_tags:
				log_in_console("You've selected too many tags, only " + str(max_tags) + " of them have been added.")
				break
			
			nb_tags_added += 1
			tag_names.push_back(tag_dict[selected_tag])
		
		Steam.setItemTags(update_handle, tag_names)
	
	var abs_path = ProjectSettings.globalize_path(_file_line_edit.text)
	var content = Steam.setItemContent(update_handle, abs_path)
	
	Steam.submitItemUpdate(update_handle, "")


func on_workshop_mod_created(result: int, file_id: int, needs_to_accept_agreement: bool) -> void:
	
	if result == 1:
		log_in_console("Workshop item created successfully. Please take note of the generated workshop ID.")
	else:
		log_in_console("Workshop item could not be created.")
		
	if needs_to_accept_agreement:
		Steam.activateGameOverlayToWebPage(SteamService.STEAM_WORKSHOP_AGREEMENT_URL)
	
	_workshop_id_line_edit.text = str(file_id)
	
	update_workshop_item()


func on_workshop_mod_updated(result: int, needs_to_accept_agreement: bool) -> void:
	if result == 1: log_in_console("Item successfully uploaded.")
	else: log_in_console("Item upload has failed.")
	
	if needs_to_accept_agreement:
		Steam.activateGameOverlayToWebPage(SteamService.STEAM_WORKSHOP_AGREEMENT_URL)


func _on_FileDialog_file_selected(path: String) -> void:
	if path.get_extension() != "zip" && path.get_extension() != "pck":
		log_in_console("Please select a .zip or .pck file")
		return
	
	_file_line_edit.text = path


func _on_PreviewImageDialog_file_selected(path: String) -> void:
	if path.get_extension() != "png" && path.get_extension() != "jpg" && path.get_extension() != "jpeg":
		log_in_console("Please select an image (.png, .jpg or .jpeg)")
		return
	
	_preview_line_edit.text = path


func _on_SelectModButton_pressed() -> void:
	_file_dialog.popup()


func _on_SelectPreviewButton_pressed() -> void:
	_preview_image_dialog.popup()


func _on_Instructions_meta_clicked(meta) -> void:
	OS.shell_open(MOD_LOADER_URL)


func _on_TermsOfServiceLabel_meta_clicked(meta) -> void:
	Steam.activateGameOverlayToWebPage(SteamService.STEAM_WORKSHOP_AGREEMENT_URL)
