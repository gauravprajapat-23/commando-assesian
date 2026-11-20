extends Node
## Independent mission progression. The Master wires world markers and triggers.
class_name CommandoMissionController

signal mission_state_changed(previous_state: State, current_state: State)

enum State { NOT_STARTED, INFILTRATE, OBJECTIVE_COMPLETE, EXTRACTED, FAILED }

var state: State = State.NOT_STARTED
var mission_state: State:
	get: return state

func start_mission() -> bool:
	return _transition(State.NOT_STARTED, State.INFILTRATE)

func complete_objective() -> bool:
	return _transition(State.INFILTRATE, State.OBJECTIVE_COMPLETE)

func extract() -> bool:
	# Extraction is impossible until the objective is complete.
	return _transition(State.OBJECTIVE_COMPLETE, State.EXTRACTED)

func fail_mission() -> bool:
	if state != State.INFILTRATE and state != State.OBJECTIVE_COMPLETE:
		return false
	var previous: State = state
	state = State.FAILED
	mission_state_changed.emit(previous, state)
	return true

func _transition(expected: State, destination: State) -> bool:
	if state != expected:
		return false
	state = destination
	mission_state_changed.emit(expected, destination)
	return true
