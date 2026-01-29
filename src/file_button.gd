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


func _ready() -> void:
	content_files.size.y = 0


func _on_pressed() -> void:
	match is_expanded:
		false:
			expand()
		true:
			collapse()


func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)


func expand() -> void:
	is_expanded = true
	reset_tween()
	tween.tween_property(self, "custom_minimum_size:y", default_min_height + content_files.size.y + 24, ANIMATION_DURATION)
	tween.tween_property(content_files_container, "custom_minimum_size:y", content_files.size.y, ANIMATION_DURATION)

func collapse() -> void:
	is_expanded = false
	reset_tween()
	tween.tween_property(self, "custom_minimum_size:y", default_min_height, ANIMATION_DURATION)
