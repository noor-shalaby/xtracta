extends Button
class_name Buttona


@export var pop_on_pressed: bool = true
@export var pop_scale: float = 1.5

var tween: Tween


func _ready() -> void:
	# Connect signals
	pressed.connect(_on_pressed)
	resized.connect(_on_resized)
	
	# Center origin pivot
	set_deferred("pivot_offset", size / 2)


func refresh_tween() -> void:
	if tween:
		tween.kill()
	tween = create_tween()


# Scale up and then back down slowly
func pop_animation(dur: float = 0.1) -> void:
	var _tween: Tween = create_tween()
	var pre_anim_scale: Vector2 = scale
	_tween.tween_property(self, "scale", Vector2.ONE * pop_scale, dur / 2)
	_tween.tween_property(self, "scale", pre_anim_scale, dur)


func _on_pressed() -> void:
	if pop_on_pressed:
		pop_animation()

func _on_resized() -> void:
	set_deferred("pivot_offset", size / 2)
