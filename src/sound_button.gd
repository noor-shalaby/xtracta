extends TextureButton


const TEXTURE_ON: CompressedTexture2D = preload("uid://dp77nbmdv48tq")
const TEXTURE_OFF: CompressedTexture2D = preload("uid://dwtne5as7ccum")

@export var pop_on_pressed: bool = true
@export var pop_scale: float = 1.5

var tween: Tween


func _ready() -> void:
	# Connect signals
	pressed.connect(_on_pressed)
	resized.connect(_on_resized)
	
	pick_texture()
	
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


func pick_texture() -> void:
	match Settings.audio:
		false:
			texture_normal = TEXTURE_OFF
		true:
			texture_normal = TEXTURE_ON


func _on_pressed() -> void:
	Settings.audio = !Settings.audio
	pick_texture()
	
	if pop_on_pressed:
		pop_animation()

func _on_resized() -> void:
	set_deferred("pivot_offset", size / 2)
