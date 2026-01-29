extends Control


const FILE_BUTTON_SCENE: PackedScene = preload("uid://ci1dgaurp7eyb")

# UI References
@onready var file_list_container: VBoxContainer = %FileListContainer

# The path to the Download folder on Android
var download_path: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS) + "/"


func _ready() -> void:
	# Request permission to access storage
	if OS.get_name() == "Android":
		OS.request_permissions()
	
	# Clear the current list
	for child: FileButton in file_list_container.get_children():
		child.queue_free()
	
	# Start scanning
	scan_dir(download_path)


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
			# Only process files that end in .zip
			elif file_name.get_extension().to_lower() == "zip":
				_add_file_to_ui(full_path)
			
			file_name = dir.get_next()
	else:
		print("Could not access the Download folder. Check permissions.")


func _add_file_to_ui(path: String) -> void:
	# Get metadata
	var file_size: int = 0
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file:
		file_size = file.get_length()
		file.close()
	
	var time: int = FileAccess.get_modified_time(path)
	
	# Create the Button
	var file_button: FileButton = FILE_BUTTON_SCENE.instantiate()
	file_list_container.add_child(file_button)
	var date_str: String = _format_date(time)
	var file_size_str: String = _format_bytes(file_size)
	
	file_button.file_name.text = path.get_file()
	file_button.last_updated.text = date_str
	file_button.file_size.text = file_size_str
	
	# Connect the signal
	file_button.pressed.connect(_on_file_selected.bind(path))


func _on_file_selected(path: String) -> void:
	print("User selected: ", path)


# --- Formatting Helpers ---

func _format_bytes(bytes: int) -> String:
	if bytes < 1024:
		return str(bytes) + " B"
	elif bytes < 1024 * 1024:
		return "%.2f KB" % (bytes / 1024.0)
	else:
		return "%.2f MB" % (bytes / (1024.0 * 1024.0))

func _format_date(unix_time: int) -> String:
	var time_init_format: String = Time.get_datetime_string_from_unix_time(unix_time, true)
	var time_final_format: String = time_init_format.substr(8, 2) + "/" + time_init_format.substr(5, 2) + "/" + time_init_format.substr(0, 4) + " " + time_init_format.substr(11, 5)
	return time_final_format


func _on_refresh_button_pressed() -> void:
	# Clear the current list
	for child: FileButton in file_list_container.get_children():
		child.queue_free()
	
	scan_dir(download_path)
