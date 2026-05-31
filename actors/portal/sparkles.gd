@tool
extends Node2D

@export var min_speed: float = -0.2
@export var max_speed: float = 0.2
@export var min_scale: float = 0.8
@export var max_scale: float = 0.9
@export var min_opacity: float = 0.25
@export var max_opacity: float = 0.4
@export var pulse_multiplier: float = 1.0

var speeds: Array[float] = []
var offsets: Array[float] = []
var pulse: float = 0.0

func _ready() -> void:
	for i in range(get_children().size()):
		speeds.append(randf_range(min_speed, max_speed))
		offsets.append(randf_range(0.0, 100.0))


func _process(delta: float) -> void:
	pulse += delta * pulse_multiplier
	for i in range(get_children().size()):
		var my_offset: float = sin(pulse + offsets[i])
		var node: Node2D = get_child(i)
		node.rotation += speeds[i] * delta
		node.scale = Vector2.ONE * (min_scale + my_offset * (max_scale - min_scale))
		node.modulate.a = min_opacity + my_offset * (max_opacity - min_opacity)
