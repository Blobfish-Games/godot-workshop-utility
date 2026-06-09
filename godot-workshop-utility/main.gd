class_name Main
extends PanelContainer

const MOD_LOADER_URL: String = "https://github.com/GodotModding/godot-mod-loader"

@export var max_tags := 5

var tag_dict := {}

@onready var _mod_selection_dropdown: OptionButton = %ModSelectionDropdown
@onready var _file_dialog: FileDialog = %FileDialog
@onready var _preview_image_dialog: FileDialog = %PreviewImageDialog
@onready var _file_line_edit: LineEdit = %FileLineEdit
@onready var _workshop_title_line_edit: LineEdit = %WorkshopTitleLineEdit
@onready var _workshop_id_line_edit: LineEdit = %WorkshopIDLineEdit
@onready var _preview_line_edit: LineEdit = %PreviewLineEdit
@onready var _console_content: Label = %ConsoleContent
@onready var _tag_list: ItemList = %TagList
@onready var _tag_container: VBoxContainer = %TagContainer
@onready var _upload_container: VBoxContainer = %UploadContainer
@onready var _tag_label: Label = %TagLabel
@onready var _select_file_button: Button = %SelectFileButton
@onready var _upload_button: Button = %UploadButton
@onready var _select_preview_button: Button = %SelectPreviewButton
@onready var _terms_of_service_label: RichTextLabel = %TermsOfServiceLabel
@onready var _instructions: RichTextLabel = %Instructions


func _ready() -> void:
	_mod_selection_dropdown.item_selected.connect(_on_mod_selected)
	_select_file_button.pressed.connect(_on_select_file_pressed)
	_select_preview_button.pressed.connect(_on_select_image_preview_pressed)
	_file_dialog.file_selected.connect(_on_file_selected)
	_preview_image_dialog.file_selected.connect(_on_preview_image_selected)
	_upload_button.pressed.connect(_on_upload_pressed)
	_terms_of_service_label.meta_clicked.connect(_on_tos_meta_clicked)
	_instructions.meta_clicked.connect(_on_label_meta_clicked)

	Steam.item_created.connect(_on_workshop_mod_created)
	Steam.item_updated.connect(_on_workshop_mod_updated)

	SteamService.log_message.connect(_log_in_console)
	SteamService.tags_set.connect(_on_tags_set)

	_tag_container.hide()
	_upload_container.size_flags_horizontal = SIZE_SHRINK_CENTER

	SteamService.initialize()

	_populate_existing_items()

func _populate_existing_items() -> void:
	Steam.ugc_query_completed.connect(_on_query_completed)
	var handle: int = Steam.createQueryUserUGCRequest(Steam.current_steam_id, Steam.USER_UGC_LIST_PUBLISHED, Steam.UGC_MATCHING_UGC_TYPE_ITEMS_READY_TO_USE,
		Steam.USER_UGC_LIST_SORT_ORDER_LAST_UPDATED_DESC, SteamService.steam_app_id, SteamService.steam_app_id, 1)
	Steam.sendQueryUGCRequest(handle)


func _on_query_completed(handle: int, result: int, results_returned: int, _total_matching: int, _cached: bool, _next_cursor: String) -> void:
	if result != Steam.RESULT_OK:
		_log_in_console("Existing mods couldn't be fetched.")
		_workshop_id_line_edit.editable = true
		return

	for index: int in range(results_returned):
		var item: Dictionary = Steam.getQueryUGCResult(handle, index)
		_mod_selection_dropdown.add_item(item.title + " - " + str(item.file_id))
		_mod_selection_dropdown.set_item_metadata(_mod_selection_dropdown.get_item_index(item.file_id), item)
	Steam.releaseQueryUGCRequest(handle)


func _on_mod_selected(index: int) -> void:
	_tag_list.deselect_all()
	if index == 0:
		_workshop_title_line_edit.text = ""
		_workshop_id_line_edit.text = ""
		return

	var meta: Dictionary = _mod_selection_dropdown.get_item_metadata(index)
	_workshop_title_line_edit.text = str(meta.title)
	_workshop_id_line_edit.text = str(meta.file_id)
	var tags: PackedStringArray = meta.tags.split(",")
	for tag_index: int in range(_tag_list.item_count):
		if _tag_list.get_item_text(tag_index) in tags:
			_tag_list.select(tag_index, false)


func _log_in_console(msg: String) -> void:
	var time_prefix: String = Time.get_time_string_from_system() + " - "

	if _console_content.text == "":
		_console_content.text += time_prefix + msg
	else:
		_console_content.text += "\n" + time_prefix + msg


func _on_tags_set(tags: Array) -> void:
	_tag_container.show()
	_upload_container.size_flags_horizontal = SIZE_FILL
	_tag_label.text += " (%s max)" % [max_tags]

	for i in tags.size():
		tag_dict[i] = tags[i]
		_tag_list.add_item(tags[i])


func _on_upload_pressed() -> void:
	if _file_line_edit.text == "":
		_log_in_console("No file selected.")
		return

	if _workshop_id_line_edit.text == "":
		_log_in_console("No workshop ID provided, creating new workshop item for app %s..." % SteamService.steam_app_id)
		Steam.createItem(SteamService.steam_app_id, Steam.WORKSHOP_FILE_TYPE_COMMUNITY)
	else:
		_update_workshop_item()


func _update_workshop_item() -> void:
	_log_in_console("Uploading workshop item with ID %s..." % _workshop_id_line_edit.text)
	var update_handle: int = Steam.startItemUpdate(SteamService.steam_app_id, int(_workshop_id_line_edit.text))

	Steam.setItemTitle(update_handle, _workshop_title_line_edit.text)

	var preview_path: String = ProjectSettings.globalize_path(_preview_line_edit.text)

	if FileAccess.file_exists(preview_path):
		Steam.setItemPreview(update_handle, preview_path)

	if _tag_list.get_selected_items().size() > 0:
		var tag_names: Array[String] = []
		var nb_tags_added := 0

		for selected_tag in _tag_list.get_selected_items():

			if nb_tags_added >= max_tags:
				_log_in_console("You've selected too many tags, only " + str(max_tags) + " of them have been added.")
				break

			nb_tags_added += 1
			tag_names.push_back(tag_dict[selected_tag])

		Steam.setItemTags(update_handle, tag_names)

	var abs_path: String = ProjectSettings.globalize_path(_file_line_edit.text)
	Steam.setItemContent(update_handle, abs_path)

	Steam.submitItemUpdate(update_handle, "")


func _on_workshop_mod_created(result: int, file_id: int, needs_to_accept_agreement: bool) -> void:
	if result == 1:
		_log_in_console("Workshop item created successfully. Please take note of the generated workshop ID.")
	else:
		_log_in_console("Workshop item could not be created.")

	if needs_to_accept_agreement:
		Steam.activateGameOverlayToWebPage(SteamService.STEAM_WORKSHOP_AGREEMENT_URL, Steam.OVERLAY_TO_WEB_PAGE_MODE_DEFAULT)

	_workshop_id_line_edit.text = str(file_id)

	_update_workshop_item()


func _on_workshop_mod_updated(result: int, needs_to_accept_agreement: bool, _file_id: int) -> void:
	if result == 1: _log_in_console("Item successfully uploaded.")
	else: _log_in_console("Item upload has failed.")

	if needs_to_accept_agreement:
		Steam.activateGameOverlayToWebPage(SteamService.STEAM_WORKSHOP_AGREEMENT_URL, Steam.OVERLAY_TO_WEB_PAGE_MODE_DEFAULT)


func _on_file_selected(path: String) -> void:
	if path.get_extension() != "zip" && path.get_extension() != "pck":
		_log_in_console("Please select a super.zip or super.pck file")
		return

	_file_line_edit.text = path
	if _workshop_title_line_edit.text == "":
		_workshop_title_line_edit.text = _file_line_edit.text.get_basename().get_file()


func _on_preview_image_selected(path: String) -> void:
	if path.get_extension() != "png" && path.get_extension() != "jpg" && path.get_extension() != "jpeg":
		_log_in_console("Please select an image (.png, super.jpg or super.jpeg)")
		return

	_preview_line_edit.text = path


func _on_select_file_pressed() -> void:
	_file_dialog.popup()


func _on_select_image_preview_pressed() -> void:
	_preview_image_dialog.popup()


func _on_label_meta_clicked(meta: Variant) -> void:
	OS.shell_open(meta)


func _on_tos_meta_clicked(_meta) -> void:
	Steam.activateGameOverlayToWebPage(SteamService.STEAM_WORKSHOP_AGREEMENT_URL, Steam.OVERLAY_TO_WEB_PAGE_MODE_DEFAULT)
