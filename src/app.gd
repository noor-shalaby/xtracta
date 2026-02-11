extends Control


const FILE_BUTTON_SCENE: PackedScene = preload("uid://ci1dgaurp7eyb")

# UI References
@onready var file_list_container: VBoxContainer = %FileListContainer
@onready var msg_label: Label = %MessageLabel

# The path to the Download folder on any OS
var download_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/"


func _ready() -> void:
	request_android_permissions()
	await refresh_list()


func request_android_permissions() -> void:
	if OS.get_name() == "Android":
		OS.request_permissions()


func refresh_list() -> void:
	await clear_list()
	await get_tree().create_timer(0.2).timeout
	scan_dir(download_path)
	if file_list_container.get_child_count() == 0:
		show_msg_label()

func clear_list() -> void:
	if msg_label.visible:
		await hide_msg_label()
	
	for child: FileButton in file_list_container.get_children():
		@warning_ignore("missing_await")
		child.fade_out()


func scan_dir(path: String) -> void:
	# Access the directory
	var dir: DirAccess = DirAccess.open(path)
	
	if dir:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		
		while file_name != "":
			var full_path: String = path.path_join(file_name)
			if dir.current_is_dir():
				scan_dir(full_path)
			# Only process zip files
			elif file_name.get_extension().to_lower() == "zip":
				_add_file_to_ui(full_path)
			
			file_name = dir.get_next()
	else:
		request_android_permissions()


func show_msg_label(dur: float = 0.5) -> void:
	msg_label.show()
	var tween: Tween = create_tween()
	tween.tween_property(msg_label, "modulate:a", 1.0, dur)

func hide_msg_label(dur: float = 0.2) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(msg_label, "modulate:a", 0.0, dur)
	await tween.finished
	msg_label.hide()


func _add_file_to_ui(path: String) -> void:
	# Get metadata
	var file_size: int = 0
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		file_size = file.get_length()
		file.close()
	var time: int = FileAccess.get_modified_time(path)
	
	# Create the file button and add it to the file list container
	var file_button: FileButton = FILE_BUTTON_SCENE.instantiate()
	file_list_container.add_child(file_button)
	
	# Format last updated date and file size
	var date_str: String = _format_date(time)
	var file_size_str: String = _format_bytes(file_size)
	
	# Display file data
	file_button.file_name.text = path.get_file()
	file_button.last_updated.text = date_str
	file_button.file_size.text = file_size_str
	display_zip_root(path, file_button.content_files)
	file_button.zip_path = path
	if not file_button.needs_extraction():
		file_button.call_deferred("disable_extraction")


func display_zip_root(zip_path: String, label_node: Label) -> void:
	var reader: ZIPReader = ZIPReader.new()
	var err: Error = reader.open(zip_path)
	
	if err == OK:
		var all_entries: PackedStringArray = reader.get_files()
		
		var folder_list: Array[String] = []
		var file_list: Array[String] = []
		
		for entry: String in all_entries:
			var parts: PackedStringArray = entry.split("/")
			
			# CASE 1: Root File (no slashes at all)
			if parts.size() == 1:
				file_list.append(entry)
			
			# CASE 2: Root Folder (has at least one slash)
			elif parts.size() >= 2:
				var folder_name: String = parts[0] + "/"
				if not folder_name in folder_list:
					folder_list.append(folder_name)
		
		# Sort both lists alphabetically
		folder_list.sort()
		file_list.sort()
		
		# Build the final string
		var final_text: String = ""
		
		for folder: String in folder_list:
			final_text += folder + "\n"
		
		for file: String in file_list:
			final_text += file + "\n"
		
		if final_text != "":
			label_node.text = final_text
		else:
			label_node.text = "Archive is empty."
		
		reader.close()
	else:
		label_node.text = "Error: %d" % err


# --- Formatting Helpers ---

func _format_bytes(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return str(int(bytes / 1024.0)) + " KB"
	else:
		return "%.2f MB" % (bytes / (1024.0 * 1024.0))

func _format_date(unix_time: int) -> String:
	var time_init_format: String = Time.get_datetime_string_from_unix_time(unix_time, true)
	var time_final_format: String = time_init_format.substr(8, 2) + "/" + time_init_format.substr(5, 2) + "/" + time_init_format.substr(0, 4) + " " + time_init_format.substr(11, 5)
	return time_final_format


func _on_refresh_button_pressed() -> void:
	@warning_ignore("missing_await")
	refresh_list()
