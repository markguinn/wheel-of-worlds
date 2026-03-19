class_name StateMachine
extends Node


signal state_changed(from_state: StateNode, to_state: StateNode)


## If not set, we'll assume its the parent node of the state machine
@export var target: Node2D

## If not set, we'll choose the first child of the state machine
@export var initial_state: StateNode

var states: Array[StateNode] = []
var active_state: StateNode


func _ready() -> void:
	if not target:
		target = get_parent()
	_init_states()


func _init_states() -> void:
	for state in get_children():
		if state is StateNode:
			state.init_state(self, target)
			_disable_state_node(state)
			states.append(state)
	if not initial_state and states.size() > 0:
		initial_state = states[0]
	prints("[StateMachine] found states", get_state_names(), "for", target.name)
	if initial_state:
		transition(initial_state)


func _enable_state_node(state: StateNode) -> void:
	state.set_process(true)
	state.set_physics_process(true)
	state.set_process_input(true)


func _disable_state_node(state: StateNode) -> void:
	state.set_process(false)
	state.set_physics_process(false)
	state.set_process_input(false)


func transition_by_name(next_state_name: String) -> bool:
	var next_state := get_state(next_state_name)
	if next_state:
		return await transition(next_state)
	else:
		push_warning("[StateMachine] invalid state name: " + next_state_name)
		return false


func transition(next_state: StateNode) -> bool:
	var cur_name := get_active()
	if can_transition(active_state, next_state):
		var prev_state := active_state
		if prev_state:
			prev_state.transitioning_out = true
			await prev_state.transition_before_exit(next_state)
			prev_state.before_exit.emit(next_state)
			_disable_state_node(prev_state)
			prev_state.transitioning_out = false

		next_state.before_enter.emit(prev_state)
		next_state.transitioning_out = false
		active_state = next_state
		prints("[StateMachine] transitioning", target.name, "from", cur_name, "to", next_state.name)
		_enable_state_node(next_state)
		active_state.entered.emit(prev_state)

		state_changed.emit(prev_state, next_state)
		return true
	else:
		push_warning("[StateMachine] invalid transition: " + cur_name + " to " + next_state.name)
		return false


func can_transition(from_state: StateNode, to_state: StateNode) -> bool:
	if from_state == to_state:
		return false
	if not to_state:
		return false
	if from_state:
		if not from_state.can_transition_to(to_state):
			return false
		# TODO: this feels bad. we should buffer the input
		# or queue up the change so inputs don't just get
		# lost. especially repeat jumps
		if from_state.transitioning_out:
			return false
	return to_state.can_enter(from_state)


func get_states() -> Array[StateNode]:
	return states


func get_state_names() -> Array[String]:
	# this is so annoying but i couldn't find a way to cast it using .map
	var names: Array[String] = []
	for s in states:
		names.append(s.name)
	return names
	

func get_state(state_name: String) -> StateNode:
	return get_node_or_null(state_name)


func get_active() -> String:
	return active_state.name as String if active_state else "NONE"


func is_valid_state(state_name: String) -> bool:
	return get_state(state_name) != null
