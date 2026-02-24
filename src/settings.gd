extends Node


const SAVE_PATH: String = "user://"
const FILE_NAME: String = "settings.res"

@onready var scene_tree: SceneTree = get_tree()


var audio: bool = true:
	set = set_audio
func set_audio(_audio: bool) -> void:
	audio = _audio
	save_settings()


func _ready() -> void:
	load_settings()


func save_settings() -> void:
	var data: SettingsData = SettingsData.new()
	data.audio = audio
	ResourceSaver.save(data, SAVE_PATH + FILE_NAME)

func load_settings() -> void:
	if not ResourceLoader.exists(SAVE_PATH + FILE_NAME):
		return
	
	var data: SettingsData = ResourceLoader.load(SAVE_PATH + FILE_NAME)
	audio = data.audio
