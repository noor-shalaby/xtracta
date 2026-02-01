extends Button
class_name FileButton


const MIN_ANIMATION_DURATION: float = 0.16
var expand_animtion_duration: float

@onready var file_icon: TextureRect = %FileIcon
@onready var file_name: Label = %FileName
@onready var last_updated: Label = %LastUpdated
@onready var file_size: Label = %FileSize
@onready var extract_button: Button = %ExtractButton
@onready var content_files_container: Control = %ContentFilesContainer
@onready var content_files: Label = %ContentFiles
@onready var default_min_height: float = custom_minimum_size.y

var tween: Tween
var is_expanded: bool = false
var extraction_thread: Thread
var zip_path: String
var output_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).path_join("Xtracta")

signal extraction_progress_updated(progress: float)


func _ready() -> void:
	content_files.size.y = 0


func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)


func expand() -> void:
	is_expanded = true
	reset_tween()
	expand_animtion_duration = max((content_files.get_line_count() - 1) * 0.02, MIN_ANIMATION_DURATION)
	tween.tween_property(self, "custom_minimum_size:y", default_min_height + content_files.size.y, expand_animtion_duration)
	tween.tween_property(content_files_container, "custom_minimum_size:y", content_files.size.y, expand_animtion_duration)

func collapse() -> void:
	is_expanded = false
	reset_tween()
	var collapse_animation_duration: float = max(expand_animtion_duration / 2.0, MIN_ANIMATION_DURATION)
	tween.tween_property(self, "custom_minimum_size:y", default_min_height, collapse_animation_duration)


func extract_all(_output_dir: String) -> bool:
	var reader: ZIPReader = ZIPReader.new()
	var err: Error = reader.open(zip_path)
	
	if err != OK:
		print("Failed to open ZIP. Error code: ", err)
		return false
	
	var files: PackedStringArray = reader.get_files()
	var total_files: int = files.size()
	var current_file_index: int = 0
	for file_path: String in files:
		# 1. Handle Folders inside the ZIP
		# In ZIP structures, folders are entries ending in "/"
		if file_path.ends_with("/"):
			var target_dir: String = _output_dir.path_join(file_path)
			DirAccess.make_dir_recursive_absolute(target_dir)
			continue
		
		# 2. Safety: Ensure parent folder exists for this specific file
		# Some ZIPs don't have explicit folder entries, just paths
		var parent_dir: String = _output_dir.path_join(file_path.get_base_dir())
		if not DirAccess.dir_exists_absolute(parent_dir):
			DirAccess.make_dir_recursive_absolute(parent_dir)
		
		# 3. Read raw data from ZIP and write to storage
		var data: PackedByteArray = reader.read_file(file_path)
		var final_file_path: String = _output_dir.path_join(file_path)
		
		var file: FileAccess = FileAccess.open(final_file_path, FileAccess.WRITE)
		if file:
			file.store_buffer(data)
			file.close()
		else:
			print("Critical: Could not write file to ", final_file_path)
			reader.close()
			return false
		
		# Update Progress
		current_file_index += 1
		var percentage: float = (float(current_file_index) / total_files) * 100
		call_deferred("emit_signal", "extraction_progress_updated", percentage)
	
	reader.close()
	disable_extraction()
	flatten_folder(_output_dir)
	save_extraction_meta(_output_dir)
	print("Extraction Complete: Files saved to ", _output_dir)
	return true


func start_extraction_with_flatten() -> void:
	var zip_name: String = zip_path.get_file().get_basename()
	var target_path: String = output_dir.path_join(zip_name)
	
	# Always create the folder
	DirAccess.make_dir_recursive_absolute(target_path)
	
	# Connect signals if not already connected
	if not extraction_progress_updated.is_connected(_on_progress_updated):
		extraction_progress_updated.connect(_on_progress_updated)
	
	# Start the thread
	extraction_thread = Thread.new()
	extraction_thread.start(extract_all.bind(target_path))


func flatten_folder(target_path: String) -> void:
	var dir: DirAccess = DirAccess.open(target_path)
	if not dir:
		return

	dir.list_dir_begin()
	var items: Array[String] = []
	var item: String = dir.get_next()
	
	# 1. Collect everything in the root of the extracted folder
	while item != "":
		items.append(item)
		item = dir.get_next()
	
	# 2. Check if there is ONLY one item and it's a directory
	if items.size() == 1 and dir.dir_exists(items[0]):
		var subfolder_name: String = items[0]
		var subfolder_path: String = target_path.path_join(subfolder_name)
		
		# 3. Move all contents of the subfolder up to the target_path
		var sub_dir: DirAccess = DirAccess.open(subfolder_path)
		if sub_dir:
			sub_dir.list_dir_begin()
			var sub_item: String = sub_dir.get_next()
			while sub_item != "":
				# Move file/folder from '.../Folder/Sub/' to '.../Folder/'
				var old_path: String = subfolder_path.path_join(sub_item)
				var new_path: String = target_path.path_join(sub_item)
				dir.rename(old_path, new_path)
				sub_item = sub_dir.get_next()
			
			# 4. Delete the now-empty subfolder
			dir.remove(subfolder_name)
			print("Folder flattened: Moved contents of ", subfolder_name, " up.")
	
	print("Extraction and flattening complete!")


func needs_extraction() -> bool:
	var zip_name: String = zip_path.get_file().get_basename()
	var target_path: String = output_dir.path_join(zip_name)
	var meta_path: String = target_path.path_join(".xtracta_meta")
	
	# 1. If folder doesn't exist, we definitely need to extract
	if not DirAccess.dir_exists_absolute(target_path) or not FileAccess.file_exists(meta_path):
		return true
	
	# 2. Get the current ZIP's modified time
	var current_zip_time: int = FileAccess.get_modified_time(zip_path)
	
	# 3. Read the stored time from the hidden file
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
	if file:
		var stored_time: int = file.get_as_text().to_int()
		file.close()
		
		# If the ZIP is newer than our record, it has been updated
		return current_zip_time > stored_time
	
	return true # Default to true if something went wrong reading the file


func save_extraction_meta(target_path: String) -> void:
	var meta_path: String = target_path.path_join(".xtracta_meta")
	var current_zip_time: int = FileAccess.get_modified_time(zip_path)
	
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.WRITE)
	if file:
		file.store_string(str(current_zip_time))
		file.close()
		print("Metadata saved: ", current_zip_time)


func disable_extraction() -> void:
	extract_button.set_deferred("disabled", true)
	extract_button.set_deferred("text", "EXTRACTED")


func _on_pressed() -> void:
	match is_expanded:
		false:
			expand()
		true:
			collapse()


func _on_extract_button_pressed() -> void:
	start_extraction_with_flatten()


func _on_progress_updated(_percentage: float) -> void:
	extract_button.text = str(int(_percentage)) + "%"
