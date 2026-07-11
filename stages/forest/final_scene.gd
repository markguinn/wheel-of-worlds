extends Stage

@export var eye_direction_noise: FastNoiseLite
@export var eye_strength: Vector2
@export var eye_speed: float

var iris_idx := 0.0
var iris_home: Vector2
@onready var iris: Node2D = %Iris
@onready var player: Player = $Player


func _ready() -> void:
	super._ready()
	iris_home = iris.position
	#player.sprite.scale.x = -1.0
	get_tree().create_timer(0.1).timeout.connect(_ragdoll_me)
	get_tree().create_timer(0.7).timeout.connect(_fade_in)


func _ragdoll_me() -> void:
	player.state_machine.transition_by_name("Ragdoll")


func _fade_in() -> void:
	VFX.white_in(VFX.LONG)


func _process(delta: float) -> void:
	iris_idx += delta * eye_speed
	var offset := Vector2(
		eye_direction_noise.get_noise_2d(1, iris_idx),
		eye_direction_noise.get_noise_2d(100, iris_idx),
	)
	iris.position = iris_home + offset * eye_strength
