class_name StateNode 
extends Node

signal before_enter(from_state: StateNode)
signal entered(from_state: StateNode)
signal before_exit(to_state: StateNode)


var target: Node2D
var machine: StateMachine


func init_state(_machine: StateMachine, _target: Node2D) -> void:
	target = _target
	machine = _machine
	if self.has_method("_entered"):
		entered.connect(self._entered)
	if self.has_method("_before_enter"):
		before_enter.connect(self._before_enter)
	if self.has_method("_before_exit"):
		before_exit.connect(self._before_exit)


func can_enter(_from_state: StateNode) -> bool:
	return true


func can_transition_to(_to_state: StateNode) -> bool:
	return true


# Subclasses can implement this to implement any animations or behaviors
# that need to happen and fully complete before the transition.
# The state machine will await this method before initiating the
# transition (i.e. before the "before_exit" signal is triggered)
func transition_before_exit(_to_state: StateNode) -> void:
	pass
