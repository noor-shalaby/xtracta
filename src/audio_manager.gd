extends Node


const SFX_ONESHOT_SCENE: PackedScene = preload("uid://chordet0fkhsj")
const EXTRACTION_INIT_SOUND: AudioStreamWAV = preload("uid://cnrulqs6q1lsy")
const EXTRACTION_COMPLETE_SOUND: AudioStreamWAV = preload("uid://ll1nxk27u7ko")

@onready var root: Control = get_tree().current_scene


func play_sfx_oneshot(stream: AudioStreamWAV = EXTRACTION_INIT_SOUND) -> void:
	if not Settings.audio:
		return
	
	var sfx: AudioStreamPlayer = SFX_ONESHOT_SCENE.instantiate()
	sfx.stream = stream
	root.call_deferred("add_child", sfx)
	if not sfx.is_inside_tree():
		await sfx.ready
	sfx.play()


func play_extraction_init() -> void:
	@warning_ignore("missing_await")
	play_sfx_oneshot(EXTRACTION_INIT_SOUND)

func play_extraction_complete() -> void:
	@warning_ignore("missing_await")
	play_sfx_oneshot(EXTRACTION_COMPLETE_SOUND)
