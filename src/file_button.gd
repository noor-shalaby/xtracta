extends Button
class_name FileButton


const ANIMATION_DURATION: float = 0.15

@onready var file_icon: TextureRect = %FileIcon
@onready var file_name: Label = %FileName
@onready var last_updated: Label = %LastUpdated
@onready var file_size: Label = %FileSize
@onready var content_files_container: Control = %ContentFilesContainer
@onready var content_files: Label = %ContentFiles
@onready var default_min_height: float = custom_minimum_size.y

var tween: Tween
var is_expanded: bool = false
var zip_path: String
var output_dir: String = OS.get_system_dir(OS.SYSTEM_DIR_DOWNLOADS).path_join("Xtracta_Files")


func _ready() -> void:
	content_files.size.y = 0


func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)


func expand() -> void:
	is_expanded = true
	reset_tween()
	tween.tween_property(self, "custom_minimum_size:y", default_min_height + content_files.size.y, ANIMATION_DURATION)
	tween.tween_property(content_files_container, "custom_minimum_size:y", content_files.size.y, ANIMATION_DURATION)

func collapse() -> void:
	is_expanded = false
	reset_tween()
	tween.tween_property(self, "custom_minimum_size:y", default_min_height, ANIMATION_DURATION)


func extract_all() -> bool:
	var reader: ZIPReader = ZIPReader.new()
	var err: Error = reader.open(zip_path)
	
	if err != OK:
		print("Failed to open ZIP. Error code: ", err)
		return false

	var files: PackedStringArray = reader.get_files()
	
	for file_path: String in files:
		# 1. Handle Folders
		if file_path.ends_with("/"):
			var target_dir: String = output_dir.path_join(file_path)
			DirAccess.make_dir_recursive_absolute(target_dir)
			continue
			
		# 2. Handle Files & Parent Folders
		# We use get_base_dir to ensure the folder exists before writing the file
		var parent_dir: String = output_dir.path_join(file_path.get_base_dir())
		if not DirAccess.dir_exists_absolute(parent_dir):
			DirAccess.make_dir_recursive_absolute(parent_dir)
			
		# 3. Read and Write Data
		var data: PackedByteArray = reader.read_file(file_path)
		var final_file_path: String = output_dir.path_join(file_path)
		
		var file: FileAccess = FileAccess.open(final_file_path, FileAccess.WRITE)
		if file:
			file.store_buffer(data)
			file.close()
		else:
			print("Error: Could not write file to ", final_file_path)
			return false
	
	reader.close()
	print("Extraction Complete!")
	return true


func _on_pressed() -> void:
	match is_expanded:
		false:
			expand()
		true:
			collapse()


func _on_extract_button_pressed() -> void:
	extract_all()
