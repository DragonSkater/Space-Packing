## The controller for one round of packing: the stack, the loader, the
## container and the move budget. A screen talks to this class and to
## nothing else in core/. Every action either succeeds, costs its moves and
## emits a signal, or is refused, costs nothing and says why. It draws
## nothing, and running out of moves does not end the round; only commit does.
class_name PackingSession
extends RefCounted

# Where to look
#   Started by: core/packing/packing_scenario.gd -> start()
#   Movement:   core/packing/access_solver.gd -> entry_lanes(), shift_range(), blockers(), turn_option()
#   Contents:   core/packing/pack_state.gd -> place(), move(), remove()
#   The stack:  core/packing/item_stack.gd -> can_take(), take(), put_on_top()
#   Moves:      core/packing/move_budget.gd -> spend(), grant()
#   Record:     core/packing/commit_record.gd -> from_session()
#   Costs:      core/packing/packing_tuning.gd
#   Tests:      tests/core/test_packing_session.gd, tests/core/test_van_and_pastry.gd,
#               tests/core/test_commit_record.gd

signal stack_changed
## An item was taken onto, turned on, or put back from the loader.
signal held_changed
signal item_pushed_in(item: PackItem, lane: EntryLane)
signal item_shifted(item: PackItem, from_origin: Vector2i)
signal item_turned(item: PackItem)
signal item_unloaded(item: PackItem, direction: Vector2i)
signal action_refused(reason: StringName, item_ids: Array[int])
signal moves_changed(moves_left: int)
## Moves were spent on one action, named by one of the ACTION_ constants.
## Emitted before moves_changed, so a screen can say what the moves paid for.
signal moves_spent(action: StringName, cost: int)
signal finished(reason: StringName)

const REFUSED_NO_MOVES: StringName = &"no_moves"
const REFUSED_BLOCKED: StringName = &"blocked"
const REFUSED_NO_DOOR: StringName = &"no_door"
const REFUSED_CANNOT_TURN: StringName = &"cannot_turn"
const REFUSED_NOT_REACHABLE: StringName = &"not_reachable"
const FINISHED_COMMITTED: StringName = &"committed"
const ACTION_PUSH_IN: StringName = &"push_in"
const ACTION_SHIFT: StringName = &"shift"
const ACTION_TURN: StringName = &"turn"
const ACTION_HELD_TURN: StringName = &"held_turn"
const ACTION_UNLOAD: StringName = &"unload"

var _state: PackState
var _manifest: Array[Batch]
var _tuning: PackingTuning
var _all_items: Array[PackItem] = []
var _stack: ItemStack = ItemStack.new()
var _held: PackItem = null
var _budget: MoveBudget


# Builds the stack from the manifest. Called by PackingScenario.start.
func _init(layout: ContainerLayout, manifest: Array[Batch], tuning: PackingTuning, move_limit: int) -> void:
	_state = PackState.new(layout)
	_manifest = manifest
	_tuning = tuning
	_budget = MoveBudget.new(move_limit)
	# The first batch ends up on top, each item turned as its type draws it.
	for batch_index: int in manifest.size():
		var batch: Batch = manifest[batch_index]
		# A manifest line left empty in the Inspector is skipped so the round
		# still runs. Batch.problems() is where that mistake is reported.
		if batch == null or batch.item_type == null:
			continue
		for _copy: int in batch.count:
			var item: PackItem = PackItem.new(_all_items.size(), batch.item_type, batch_index)
			_all_items.append(item)
			_stack.put_at_bottom(item)


## What is where inside the container.
func state() -> PackState:
	return _state


## The waiting items, top first.
func stack() -> Array[PackItem]:
	return _stack.items()


## Lets the bottom item of the stack be taken as well as the top. A round
## sets this once, before play; PackingScenario.start does it.
func set_stack_bottom_reachable(reachable: bool) -> void:
	_stack.bottom_reachable = reachable
	stack_changed.emit()


## True when the item this far down the stack is within reach: within
## stack_pick_depth, or the bottom one when the round allows it. Screens
## raise these items whether or not the loader is free.
func stack_reachable(index_from_top: int) -> bool:
	return _stack.can_take(index_from_top, _tuning.stack_pick_depth)


## True when the item this far down the stack could be taken now: it is
## within reach and the loader is empty.
func can_pick(index_from_top: int) -> bool:
	return _held == null and stack_reachable(index_from_top)


## The item on the loader, or null when the loader is empty.
func held() -> PackItem:
	return _held


## Free. Refused for an item can_pick does not allow, or when the loader
## is not empty.
func pick_from_stack(index_from_top: int) -> bool:
	if _held != null:
		return _refuse(REFUSED_NOT_REACHABLE, [_held.id])
	if not can_pick(index_from_top):
		return _refuse(REFUSED_NOT_REACHABLE, [])
	_held = _stack.take(index_from_top)
	stack_changed.emit()
	held_changed.emit()
	return true


## Free. The held item returns to the top of the stack, turned as it is.
func put_back() -> void:
	if _held == null:
		return
	_stack.put_on_top(_held)
	_held = null
	stack_changed.emit()
	held_changed.emit()


## A quarter turn on the loader, outside the container, where it always fits.
func turn_held(clockwise: bool) -> bool:
	if _held == null:
		return false
	if not _held.type.can_rotate:
		return _refuse(REFUSED_CANNOT_TURN, [_held.id])
	var turned: CellShape = _held.shape.rotated_clockwise()
	if not clockwise:
		turned = _held.shape.rotated_anticlockwise()
	var cost: int = _turn_cost(_tuning.held_turn_cost, turned.matches(_held.shape))
	if not _budget.can_afford(cost):
		return _refuse(REFUSED_NO_MOVES, [_held.id])
	_held.shape = turned
	_held.note_quarter_turn(clockwise)
	_spend(ACTION_HELD_TURN, cost)
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
	_spend(ACTION_PUSH_IN, _tuning.push_in_cost)
	item_pushed_in.emit(item, offered)
	held_changed.emit()
	return true


## Where an item in the container can slide to, and the sides it can leave by.
func shift_range(item_id: int) -> ShiftRange:
	return AccessSolver.shift_range(_state, item_id)


## The other items in the way of an item's straight path out on one side.
## Empty when a wall, not an item, is what stops it.
func blockers(item_id: int, direction: Vector2i) -> Array[int]:
	return AccessSolver.blockers(_state, item_id, direction)


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
	_spend(ACTION_SHIFT, _tuning.shift_cost)
	item_shifted.emit(item, from_origin)
	return true


## A quarter turn inside the container, about the gripped cell.
func turn(item_id: int, grip: Vector2i, clockwise: bool) -> bool:
	var item: PackItem = _state.item_by_id(item_id)
	if item == null:
		return _refuse(REFUSED_NOT_REACHABLE, [item_id])
	var option: TurnOption = AccessSolver.turn_option(_state, item_id, grip, clockwise)
	if option == null:
		return _refuse(REFUSED_CANNOT_TURN, [item_id])
	var cost: int = _turn_cost(_tuning.turn_cost, _same_cells(item.cells(), option.shape.cells_at(option.origin)))
	if not _budget.can_afford(cost):
		return _refuse(REFUSED_NO_MOVES, [item_id])
	_state.move(item_id, option.shape, option.origin)
	item.note_quarter_turn(clockwise)
	_spend(ACTION_TURN, cost)
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
	_stack.put_on_top(item)
	_spend(ACTION_UNLOAD, _tuning.unload_cost)
	item_unloaded.emit(item, direction)
	stack_changed.emit()
	return true


## Moves still to spend.
func moves_left() -> int:
	return _budget.left()


## Moves spent so far.
func moves_used() -> int:
	return _budget.used()


## The round's moves, including any granted since it began.
func moves_allowed() -> int:
	return _budget.limit()


## Adds moves to the round, as a bonus would.
func grant_moves(count: int) -> void:
	_budget.grant(count)
	moves_changed.emit(moves_left())


## What one of the ACTION_ constants costs right now, in moves. Screens use
## it to say what letting go would cost before it is spent. An unknown
## action costs nothing.
func cost_of(action: StringName) -> int:
	match action:
		ACTION_PUSH_IN:
			return _tuning.push_in_cost
		ACTION_SHIFT:
			return _tuning.shift_cost
		ACTION_TURN:
			return _tuning.turn_cost
		ACTION_HELD_TURN:
			return _tuning.held_turn_cost
		ACTION_UNLOAD:
			return _tuning.unload_cost
	return 0


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


## A copy of the container, the stack and the moves as they are now. Asked
## for once the round is committed, so the result can be kept.
func commit_record() -> CommitRecord:
	return CommitRecord.from_session(self)


# What a turn costs: nothing when it leaves the item covering exactly the
# cells it covered before, as a single-cell item always does, and the
# tuning allows it; otherwise the full cost.
func _turn_cost(full_cost: int, changes_nothing: bool) -> int:
	if changes_nothing and _tuning.free_turn_when_unchanged:
		return 0
	return full_cost


# True when two lists hold the same cells, in any order.
func _same_cells(before: Array[Vector2i], after: Array[Vector2i]) -> bool:
	var sorted_before: Array[Vector2i] = before.duplicate()
	var sorted_after: Array[Vector2i] = after.duplicate()
	sorted_before.sort()
	sorted_after.sort()
	return sorted_before == sorted_after


# Deducts a cost, says what it paid for, and announces the new total. A
# free action spends nothing and says nothing.
func _spend(action: StringName, cost: int) -> void:
	if cost == 0:
		return
	_budget.spend(cost)
	moves_spent.emit(action, cost)
	moves_changed.emit(moves_left())


# Announces a refusal and returns false, so that a caller can return it.
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
