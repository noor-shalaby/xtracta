extends Button


@onready var file_icon: TextureRect = %FileIcon
@onready var default_min_height: float = custom_minimum_size.y

var tween: Tween
var is_expanded: bool = false


func _on_pressed() -> void:
	match is_expanded:
		false:
			expand(default_min_height + 512)
		true:
			collapse()


func reset_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)


func expand(target_size: float) -> void:
	reset_tween()
	tween.tween_property(self, "custom_minimum_size:y", target_size, 0.2)
	is_expanded = true

func collapse() -> void:
	reset_tween()
	tween.tween_property(self, "custom_minimum_size:y", default_min_height, 0.2)
	is_expanded = false
