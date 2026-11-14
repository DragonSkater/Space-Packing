## The controller for one round of packing: the stack, the loader, the
## container and the move budget. A screen talks to this class and to
## nothing else in core/. Every action either succeeds, costs its moves and
## emits a signal, or is refused, costs nothing and says why. It draws
## nothing, and running out of moves does not end the round; only commit does.
class_name PackingSession
extends RefCounted

signal stack_changed
## An item was taken onto, turned on, or put back from the loader.
signal held_changed
signal item_pushed_in(item: PackItem, lane: EntryLane)
signal item_shifted(item: PackItem, from_origin: Vector2i)
signal item_turned(item: PackItem)
signal item_unloaded(item: PackItem, direction: Vector2i)
signal action_refused(reason: StringName, item_ids: Array[int])
signal moves_changed(moves_left: int)
signal finished(reason: StringName)

const REFUSED_NO_MOVES: StringName = &"no_moves"
const REFUSED_BLOCKED: StringName = &"blocked"
const REFUSED_NO_DOOR: StringName = &"no_door"
const REFUSED_CANNOT_TURN: StringName = &"cannot_turn"
const REFUSED_NOT_REACHABLE: StringName = &"not_reachable"
const FINISHED_COMMITTED: StringName = &"committed"

var _state: PackState
var _manifest: Array[Batch]
var _tuning: PackingTuning
var _all_items: Array[PackItem] = []
# The top of the stack is index 0.
var _stack: Array[PackItem] = []
var _held: PackItem = null
var _budget: MoveBudget


func _init(layout: ContainerLayout, manifest: Array[Batch], tuning: PackingTuning, move_limit: int) -> void:
	_state = PackState.new(layout)
	_manifest = manifest
	_tuning = tuning
	_budget = MoveBudget.new(move_limit)
	# The first batch ends up on top, each item turned as its type draws it.
	for batch_index: int in manifest.size():
		for _copy: int in manifest[batch_index].count:
			var item: PackItem = PackItem.new(_all_items.size(), manifest[batch_index].item_type, batch_index)
			_all_items.append(item)
			_stack.append(item)


func state() -> PackState:
	return _state


## The waiting items, top first.
func stack() -> Array[PackItem]:
	return _stack.duplicate()


## The item on the loader, or null when the loader is empty.
func held() -> PackItem:
	return _held


## Free. Refused beyond stack_pick_depth, or when the loader is not empty.
func pick_from_stack(index_from_top: int) -> bool:
	if _held != null:
		return _refuse(REFUSED_NOT_REACHABLE, [_held.id])
	var reachable: int = mini(_stack.size(), _tuning.stack_pick_depth)
	if index_from_top < 0 or index_from_top >= reachable:
		return _refuse(REFUSED_NOT_REACHABLE, [])
	_held = _stack[index_from_top]
	_stack.remove_at(index_from_top)
	stack_changed.emit()
	held_changed.emit()
	return true


## Free. The held item returns to the top of the stack, turned as it is.
func put_back() -> void:
	if _held == null:
		return
	_stack.insert(0, _held)
	_held = null
	stack_changed.emit()
	held_changed.emit()


## A quarter turn on the loader, outside the container, where it always fits.
func turn_held(clockwise: bool) -> bool:
	if _held == null:
		return false
	if not _budget.can_afford(_tuning.held_turn_cost):
		return _refuse(REFUSED_NO_MOVES, [_held.id])
	if not _held.type.can_rotate:
		return _refuse(REFUSED_CANNOT_TURN, [_held.id])
	if clockwise:
		_held.shape = _held.shape.rotated_clockwise()
	else:
		_held.shape = _held.shape.rotated_anticlockwise()
	_spend(_tuning.held_turn_cost)
	held_changed.emit()
	return true


## The lanes open to the held item, as it is currently turned.
func entry_lanes() -> Array[EntryLane]:
	if _held == null:
		return []
	return AccessSolver.entry_lanes(_state, _held.shape)


## Slides the held item in along a lane and leaves it at one of the lane's
## stops. The lane and the stop must be among those currently offered.
func push_in(lane: EntryLane, stop_index: int) -> bool:
	if _held == null:
		return false
	if not _budget.can_afford(_tuning.push_in_cost):
		return _refuse(REFUSED_NO_MOVES, [_held.id])
	var offered: EntryLane = _offered_lane(lane)
	if offered == null:
		return _refuse(REFUSED_NO_DOOR, [_held.id])
	if not lane.has_same_stop(offered, stop_index):
		return _refuse(REFUSED_BLOCKED, [_held.id])
	var item: PackItem = _held
	_held = null
	item.others_present_when_placed = _state.items().size()
	_state.place(item, offered.stops[stop_index])
	_spend(_tuning.push_in_cost)
	item_pushed_in.emit(item, offered)
	held_changed.emit()
	return true


func shift_range(item_id: int) -> ShiftRange:
	return AccessSolver.shift_range(_state, item_id)


## Slides an item to another stop in its row. Asking for the origin it is
## already at does nothing and costs nothing.
func shift(item_id: int, origin: Vector2i) -> bool:
	var item: PackItem = _state.item_by_id(item_id)
	if item == null:
		return _refuse(REFUSED_NOT_REACHABLE, [item_id])
	if origin == item.origin:
		return false
	if not _budget.can_afford(_tuning.shift_cost):
		return _refuse(REFUSED_NO_MOVES, [item_id])
	if not shift_range(item_id).has_stop(origin):
		var direction: Vector2i = Vector2i.RIGHT
		if origin.x < item.origin.x:
			direction = Vector2i.LEFT
		return _refuse(REFUSED_BLOCKED, AccessSolver.blockers(_state, item_id, direction))
	var from_origin: Vector2i = item.origin
	_state.move(item_id, item.shape, origin)
	_spend(_tuning.shift_cost)
	item_shifted.emit(item, from_origin)
	return true


## A quarter turn inside the container, about the gripped cell.
func turn(item_id: int, grip: Vector2i, clockwise: bool) -> bool:
	var item: PackItem = _state.item_by_id(item_id)
	if item == null:
		return _refuse(REFUSED_NOT_REACHABLE, [item_id])
	if not _budget.can_afford(_tuning.turn_cost):
		return _refuse(REFUSED_NO_MOVES, [item_id])
	var option: TurnOption = AccessSolver.turn_option(_state, item_id, grip, clockwise)
	if option == null:
		return _refuse(REFUSED_CANNOT_TURN, [item_id])
	_state.move(item_id, option.shape, option.origin)
	_spend(_tuning.turn_cost)
	item_turned.emit(item)
	return true


## Slides an item out through a door. It goes to the top of the stack,
## still turned the way it was.
func unload(item_id: int, direction: Vector2i) -> bool:
	var item: PackItem = _state.item_by_id(item_id)
	if item == null:
		return _refuse(REFUSED_NOT_REACHABLE, [item_id])
	if not _budget.can_afford(_tuning.unload_cost):
		return _refuse(REFUSED_NO_MOVES, [item_id])
	if not shift_range(item_id).can_leave(direction):
		var in_the_way: Array[int] = AccessSolver.blockers(_state, item_id, direction)
		if in_the_way.is_empty():
			return _refuse(REFUSED_NO_DOOR, [item_id])
		return _refuse(REFUSED_BLOCKED, in_the_way)
	_state.remove(item_id)
	_stack.insert(0, item)
	_spend(_tuning.unload_cost)
	item_unloaded.emit(item, direction)
	stack_changed.emit()
	return true


func moves_left() -> int:
	return _budget.left()


func moves_used() -> int:
	return _budget.used()


## The round's moves, including any granted since it began.
func move_limit() -> int:
	return _budget.limit()


func grant_moves(count: int) -> void:
	_budget.grant(count)
	moves_changed.emit(moves_left())


## How many items of required batches are not in the container.
func required_items_left() -> int:
	var left: int = 0
	for item: PackItem in _all_items:
		if _manifest[item.batch_index].required and _state.item_by_id(item.id) == null:
			left += 1
	return left


## The player ends the round. Allowed at any time, whatever is on the stack.
func commit() -> void:
	finished.emit(FINISHED_COMMITTED)


func _spend(cost: int) -> void:
	_budget.spend(cost)
	moves_changed.emit(moves_left())


func _refuse(reason: StringName, item_ids: Array[int]) -> bool:
	action_refused.emit(reason, item_ids)
	return false


# The lane as the solver offers it right now, or null when it no longer does.
func _offered_lane(lane: EntryLane) -> EntryLane:
	if lane == null:
		return null
	for candidate: EntryLane in entry_lanes():
		if candidate.is_same_lane(lane):
			return candidate
	return null
