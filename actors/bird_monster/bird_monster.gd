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

## When the bird returns to its nest, minimum of the range it might stay there
@export var nest_min_seconds := 1.0

## When the bird returns to its nest, minimum of the range it might stay there
@export var nest_max_seconds := 5.0

## These would be potential locations where it returns to rest and/or brings props it has snatched
@export var nests: Array[Node2D] = []

## How close will the bird get to the player?
@export var min_player_distance := 200.0


# TODO: can it pick up the orb or player?
var carried_obj: GrabBox = null
var recently_carried: Array[GrabBox] = []
