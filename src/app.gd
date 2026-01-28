extends Control


func _ready() -> void:
	if OS.get_name() == "Android":
		OS.request_permissions()
