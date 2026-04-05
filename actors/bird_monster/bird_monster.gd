class_name BirdMonster
extends Node2D


@export var fly_speed := 500.0
@export var attack_probability := 0.4
@export var nest_min_seconds := 1.0
@export var nest_max_seconds := 5.0
@export var nest_probability := 0.4

## these would be potential locations where it returns to rest and/or brings props it has snatched
@export var nests: Array[Node2D] = []

## TODO: do we want to limit what kinds of props/actors it will try to pick up?

var carried_obj: GrabBox = null
var recently_carried: Array[GrabBox] = []
