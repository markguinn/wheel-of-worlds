@tool
extends Control


@export var speed := 1.0
@export var amount := 10.0
@export var wave_layers: Array[TextureRect] = []
@export var wave_layer_extra_y: Array[float] = []
@export var wave_offset := Vector2(0.0, -120.0)
@export var animating := true


var rnd_layers: Array[float] = []
var start_layers: Array[Vector2] = []
var t := 0.0


func _ready() -> void:
	if wave_layers.size() == 0:
		for n in get_children():
			if n is TextureRect:
				wave_layers.append(n)
	for l in wave_layers:
		rnd_layers.append(randf())


func _process(delta: float) -> void:
	if not animating:
		return
	t += delta * speed
	for i in range(wave_layers.size()):
		var my_t := t + rnd_layers[i]
		var my_dir: float = 1.0 if i % 2 == 0 else -1.0
		var my_amount: float = amount * lerp(0.8, 1.2, rnd_layers[i])
		var my_extra_y: float = 0.0 if not wave_layer_extra_y or i >= wave_layer_extra_y.size() else wave_layer_extra_y[i]
		var my_offset := Vector2(
			cos(my_t * my_dir) * my_amount + lerp(-200.0, 200.0, rnd_layers[i]),
			sin(my_t * my_dir) * my_amount + my_extra_y
		)
		wave_layers[i].position = wave_offset + my_offset
