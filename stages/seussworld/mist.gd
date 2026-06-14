extends Sprite2D

@export var min_lacunity := 4.0
@export var max_lacunity := 6.0
@export var tick_delta := 0.001
@export var ms_per_frame := 60

var last_tick := 0
var noise : FastNoiseLite

func _ready() -> void:
	var tex: NoiseTexture2D = self.texture
	noise = tex.noise


func _process(_delta: float) -> void:
	if GameManager.now_ms() > last_tick + ms_per_frame:
		# NOTE: this is beatiful but also slows the web build down to a crawl.
		# TODO: can we just export a few frames of this as static files?
		#noise.fractal_lacunarity += tick_delta
		#if noise.fractal_lacunarity > max_lacunity:
			#noise.fractal_lacunarity = max_lacunity
			#tick_delta = -abs(tick_delta)
		#if noise.fractal_lacunarity < min_lacunity:
			#noise.fractal_lacunarity = min_lacunity
			#tick_delta = abs(tick_delta)
		last_tick = GameManager.now_ms()
