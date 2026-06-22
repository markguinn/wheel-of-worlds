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
