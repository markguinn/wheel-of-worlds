extends Node

const DEBUG = 1
const INFO = 2
const WARNING = 3
const ERROR = 4
const EMPTY = []

const HEADER_FORMAT = "[%s] %8d %s:"
const DEFAULT_LEVEL = INFO

const LABELS = {
	DEBUG: "D",
	INFO: "I",
	WARNING: "W",
	ERROR: "E",
}

# TODO: move this to a gitignored json file?
# Feel free to add any component here that's too noisy or that we might want more output 
# from during development. What's listed here will be the minimum level that gets through
const levels = {
	#"AudioManager": DEBUG,
	#"BirdMonster": DEBUG,
	#"Activator": DEBUG,
	#"FishMonster": DEBUG,
	#"FishPatrollingState": DEBUG,
	#"GameManager": DEBUG,
	#"GrabBox": DEBUG,
	#"Plank": DEBUG,
	#"Player": DEBUG,
	#"Portal": DEBUG,
	#"StateMachine": DEBUG,
	#"StateManager": DEBUG,
}


func _format(source: Variant, level: int, args: Array[Variant]) -> Array[Variant]:
	var source_name: String
	if source is String or source is StringName:
		source_name = source
	elif source.get_script():
		source_name = source.get_script().get_global_name()
	if not source_name:
		if source is Node:
			source_name = source.name
		else:
			source_name = str(source)
	if level < levels.get(source_name, DEFAULT_LEVEL):
		return EMPTY
	var header := HEADER_FORMAT % [
		LABELS[level],
		Time.get_ticks_msec(),
		source_name,
	]
	var output: Array[Variant] = [header]
	output.append_array(args)
	return output


func _log(source: Variant, level: int, args: Array[Variant]) -> void:
	var output = _format(source, level, args)
	if output:
		prints.callv(output)


func _convert_and_join(a: Array[Variant]) -> String:
	return " ".join(a.map(func(v): return str(v)))


func error(source: Variant, ...args) -> void:
	var output = _format(source, WARNING, args)
	if output:
		push_error(_convert_and_join(output))
		prints.callv(output)


func warn(source: Variant, ...args) -> void:
	var output = _format(source, WARNING, args)
	if output:
		push_warning(_convert_and_join(output))
		prints.callv(output)


func info(source: Variant, ...args) -> void:
	if GameManager.DEV_MODE:
		_log(source, INFO, args)


func debug(source: Variant, ...args) -> void:
	if GameManager.DEV_MODE:
		_log(source, DEBUG, args)


var debounced_log_ms := 500
var debounced_log_level := DEBUG
func debounced(source: Variant, ...args) -> void:
	if GameManager.DEV_MODE and not GameManager.rate_limit(debounced_log_ms, str(source)):
		_log(source, debounced_log_level, args)
	
