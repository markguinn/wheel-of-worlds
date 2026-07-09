class_name BirdMonster
extends Node2D


## How fast the bird flies around normally (pixels/second)
@export var fly_speed := 500.0

## When the bird is deciding what to do, how likely is it to attack (0-1)
@export var attack_probability := 0.4

## When the bird is deciding what to do, how likely is it to return to a nest (0-1)
@export var nest_probability := 0.4

## When the bird is attacking, how long before it gives up and returns to a nest?
@export var attack_max_seconds := 10.0

## Max time the bird will struggle with a prop before picking it up
## this makes the bird a little easier because you have more time to scare it away.
@export var pickup_pause_secounds := 2.0

## When the bird returns to its nest, minimum of the range it might stay there
@export var nest_min_seconds := 1.0

## When the bird returns to its nest, minimum of the range it might stay there
@export var nest_max_seconds := 5.0

## These would be potential locations where it returns to rest and/or brings props it has snatched
@export var nests: Array[Node2D] = []

## How close will the bird get to the player?
@export var min_player_distance := 200.0

## How far away from its current position will the bird look for targets?
@export var max_target_distance := 2400.0


@onready var sfx_squawk: AudioStreamPlayer2D = $SquawkSound

# TODO: can it pick up the orb or player?
var carried_obj: GrabBox = null
var recently_carried: Array[GrabBox] = []

@onready var histbuf: PositionHistoryBuffer= $Sprite/PositionHistoryBuffer
@onready var tail_target: MoveableRigidBody2D = $Sprite/TailTarget
@onready var tail_joint: PinJoint2D = %TailJoint
@onready var skeleton: Skeleton2D = %Skeleton2D
@onready var front_foot: Bone2D = %FrontFoot
@onready var back_foot: Bone2D = %BackFoot
@onready var head: Bone2D = %Head
@onready var sprite: Node2D = $Sprite
@onready var tail_anchor: StaticBody2D = %TailAnchor
@onready var tail_nodes: Array[Bone2D] = [
	$Sprite/Skeleton2D/Controller/Tail,
	$Sprite/Skeleton2D/Controller/Tail/Tail2,
	$Sprite/Skeleton2D/Controller/Tail/Tail2/Tail3,
]


func _ready() -> void:
	#_setup_tail.call_deferred()
	skeleton.get_modification_stack().enabled = true


func _setup_tail() -> void:
	tail_target.reparent(get_parent())
	tail_joint.node_b = tail_target.get_path()


func _process(delta: float) -> void:
	var t = GameManager.now_sec() * PI
	var target = histbuf.get_start() + Vector2(
		cos(t * 2.0) * 50.0, 
		sin(t) * 50.0,
	)
	tail_target.global_position = tail_target.global_position.move_toward(
		target, 
		delta * fly_speed * 2.0,
	)
		
	
