## The control scheme of the packing screen, without any geometry: what a
## tap or a grab on the stack, a door or a piece means, and what a slide, a
## turn or a carry does to the piece the crane has (MILESTONES.md milestone
## 2, item 8). It remembers only the selection, its grip, the chosen door,
## and the slide or carry in progress. Every change goes through PackingSession.
class_name CraneControls
extends RefCounted

# Where to look
#   Told by:    ui/packing/loading_bay.gd -> _on_tapped(), _on_drag_started(), _on_drag_moved(),
#               _on_drag_ended(), _on_swiped(), _process()
#   Changes the round through:
#               core/packing/packing_session.gd -> pick_from_stack(), put_back(), push_in(), shift(),
#               turn(), turn_held(), unload()
#   Helpers:    ui/packing/slide_preview.gd, ui/packing/door_choice.gd, ui/packing/crane_refusals.gd
#   Redrawn by: ui/packing/item_layer.gd, ui/packing/gantry_view.gd, ui/packing/stack_view.gd
#   Tests:      tests/ui/test_crane_controls.gd

## The selection, the chosen door, or the slide or carry in progress changed.
signal view_changed
## Something was tried and could not be done: shake that piece, and light
## the pieces and cells that were in its way.
signal attempt_refused(shaken_item_id: int, lit_item_ids: Array[int], lit_cells: Array[Vector2i])
## Something was tried that the moves left could not pay for.
signal moves_missed

const NO_ITEM: int = -1
const NO_ACTION: StringName = &""

var _session: PackingSession
var _selected_id: int = NO_ITEM
var _grip: Vector2i = Vector2i.ZERO
var _lane: EntryLane = null
var _slide: SlidePreview = null
# Where the stack is, in cells, so that "the nearest door" has a meaning.
var _stack_point: Vector2 = Vector2.ZERO
# While the finger carries a piece from the stack: where it is, in cells,
# and the door it is over, if any.
var _carrying: bool = false
var _carry_point: Vector2 = Vector2.ZERO
var _carry_lane: EntryLane = null
# The player put the crane's piece back by hand, so the crane waits for
# them instead of fetching it again.
var _fetch_paused: bool = false


# Listens for the session refusing an action, to show why.
func _init(session: PackingSession) -> void:
	_session = session
	_session.action_refused.connect(_on_action_refused)


## The loaded piece that was tapped or grabbed, or null.
func selected_item() -> PackItem:
	return _session.state().item_by_id(_selected_id)


## The cell of the selected piece that was tapped. A turn pivots about it.
func grip() -> Vector2i:
	return _grip


## The piece a slide or a turn acts on: the selected loaded piece, else the
## one the crane holds. The crane can wait with the next piece while the
## player works inside the container.
func active_item() -> PackItem:
	var selected: PackItem = selected_item()
	if selected != null:
		return selected
	return _session.held()


## The door the held piece waits outside, or null when no door will take it.
func held_lane() -> EntryLane:
	return _lane


## Where the held piece waits, as the origin of its top-left corner in
## cells: outside its door, or, when no door will take it as it is turned,
## outside the nearest door anyway, so it can still be seen and turned.
func held_origin() -> Vector2:
	var held: PackItem = _session.held()
	if held == null:
		return Vector2.ZERO
	if _lane != null:
		return Vector2(_lane.hold_origin)
	return Vector2(DoorChoice.waiting_origin(_session.state().layout, held, _stack_point))


## The slide in progress, or null. ItemLayer draws the piece where it says.
func slide() -> SlidePreview:
	return _slide


## Where the stack is, in cells. A piece the crane fetches sets off from here.
func stack_point() -> Vector2:
	return _stack_point


## True while the finger carries a piece from the stack.
func is_carrying() -> bool:
	return _carrying


## Where the carried piece's middle is, in cells.
func carry_point() -> Vector2:
	return _carry_point


## The door the carried piece is over, or null.
func carry_lane() -> EntryLane:
	return _carry_lane


## True when the crane is empty, the stack is not, and the player has not
## put a piece back by hand. LoadingBay then has the crane fetch the top piece.
func wants_fetch() -> bool:
	return _session.held() == null and not _session.stack().is_empty() and not _carrying and not _fetch_paused


## The crane takes the top piece to the nearest door that offers it a lane.
## Free, like any pick.
func fetch(stack_point_cells: Vector2) -> void:
	_stack_point = stack_point_cells
	if _session.pick_from_stack(0):
		_lane = DoorChoice.nearest(_session.entry_lanes(), _session.held(), _stack_point)
	view_changed.emit()


## Takes a piece from the stack to the nearest door that offers it a lane.
## With a piece already held, the tap puts that piece back instead, and the
## crane waits until the player takes one.
func tap_stack(index_from_top: int, stack_point_cells: Vector2) -> void:
	_stack_point = stack_point_cells
	_selected_id = NO_ITEM
	if _session.held() != null:
		_put_back_held()
		view_changed.emit()
		return
	if _session.pick_from_stack(index_from_top):
		_fetch_paused = false
		_lane = DoorChoice.nearest(_session.entry_lanes(), _session.held(), _stack_point)
	view_changed.emit()


## Moves the held piece to another door, free, and makes it the active
## piece. A tap on its own door only makes it active.
func tap_door(lane: EntryLane) -> void:
	if _session.held() == null:
		tap_empty()
		return
	_selected_id = NO_ITEM
	_lane = lane
	view_changed.emit()


## Selects the loaded piece on this cell, gripped by this cell. A tap on an
## empty cell deselects. The crane keeps whatever it holds.
func tap_cell(cell: Vector2i) -> void:
	if not grab_cell(cell):
		tap_empty()


## Selects the loaded piece on this cell, gripped by this cell, when there
## is one. A gesture that starts on a piece acts on that piece.
func grab_cell(cell: Vector2i) -> bool:
	var item: PackItem = _session.state().item_at(cell)
	if item == null:
		return false
	_selected_id = item.id
	_grip = cell
	view_changed.emit()
	return true


## Makes the held piece the active one when the point, in cells, is on it
## where it waits. A gesture that starts on the held piece acts on it, even
## when no door is lit for it to be grabbed by.
func grab_held(point_cells: Vector2) -> bool:
	var held: PackItem = _session.held()
	if held == null or _carrying:
		return false
	var waiting: Rect2 = Rect2(held_origin(), Vector2(held.shape.bounds().size))
	if not waiting.has_point(point_cells):
		return false
	tap_empty()
	return true


## Deselects. The crane keeps the piece it holds.
func tap_empty() -> void:
	_selected_id = NO_ITEM
	view_changed.emit()


## Starts carrying a piece from the stack with the finger. Only an empty
## crane can be given one this way.
func begin_carry(index_from_top: int, stack_point_cells: Vector2) -> bool:
	_stack_point = stack_point_cells
	if _session.held() != null or not _session.pick_from_stack(index_from_top):
		return false
	_selected_id = NO_ITEM
	_fetch_paused = false
	_lane = null
	_carrying = true
	_carry_point = stack_point_cells
	_carry_lane = null
	view_changed.emit()
	return true


## The finger moved: the carried piece is under it, over a door or not.
func carry_to(point_cells: Vector2, lane_under: EntryLane) -> void:
	if not _carrying:
		return
	_carry_point = point_cells
	_carry_lane = lane_under
	view_changed.emit()


## The finger lifted. Over a door, the crane takes the piece there; anywhere
## else it goes back on the stack, and the crane waits.
func end_carry() -> void:
	if not _carrying:
		return
	_carrying = false
	if _carry_lane != null:
		_lane = _carry_lane
	else:
		_put_back_held()
	_carry_lane = null
	view_changed.emit()


## Starts sliding the active piece. Returns false, and says why through a
## signal, when there is no piece, no moves, or nowhere to go on that side.
func begin_slide(direction: Vector2i) -> bool:
	var item: PackItem = active_item()
	if item == null or _carrying:
		return false
	# PLAN.md section 3.2: when no moves are left the crane stops.
	if _session.moves_left() <= 0:
		moves_missed.emit()
		return false
	var preview: SlidePreview = SlidePreview.entering(item, _lane)
	if item != _session.held():
		var layout_width: int = _session.state().layout.size().x
		preview = SlidePreview.shifting(item, _session.shift_range(item.id), layout_width)
	if not preview.has_stop_towards(direction):
		var lit_ids: Array[int] = CraneRefusals.items_in_the_way(_session, item, direction)
		var lit_cells: Array[Vector2i] = CraneRefusals.walls_in_the_way(_session, item, direction)
		attempt_refused.emit(item.id, lit_ids, lit_cells)
		return false
	_slide = preview
	return true


## Follows the finger: how far it is from where the slide began, in cells.
func slide_by(cells_from_start: float) -> void:
	if _slide != null and _slide.snap_to(cells_from_start):
		view_changed.emit()


## What letting go now would do: one of PackingSession's ACTION_ constants,
## or NO_ACTION when the piece would be left where it started, for free.
func pending_action() -> StringName:
	if _slide == null or _slide.current == _slide.start:
		return NO_ACTION
	if _slide.item == _session.held():
		return PackingSession.ACTION_PUSH_IN
	if _slide.exits.has(_slide.current):
		return PackingSession.ACTION_UNLOAD
	return PackingSession.ACTION_SHIFT


## The finger lifted: the piece stays where it is shown. Leaving it where it
## started costs nothing.
func end_slide() -> void:
	var preview: SlidePreview = _slide
	_slide = null
	if preview == null:
		return
	if preview.current != preview.start:
		_leave_at(preview)
	view_changed.emit()


## A quarter turn of the active piece. A loaded piece turns about its grip.
## A turn that changes nothing may be free, so the session, not this, says
## whether the moves left can pay for it.
func turn(clockwise: bool) -> void:
	var item: PackItem = active_item()
	if item == null or _carrying:
		return
	if item == _session.held():
		var waited_at: Vector2 = held_origin() + Vector2(item.shape.bounds().size) / 2.0
		if _session.turn_held(clockwise):
			_lane = DoorChoice.nearest(_session.entry_lanes(), item, waited_at)
	else:
		_session.turn(item.id, _grip, clockwise)
	view_changed.emit()


# Tells the session where the slid piece was left: pushed in, unloaded or shifted.
func _leave_at(preview: SlidePreview) -> void:
	var item: PackItem = preview.item
	if item == _session.held():
		if _session.push_in(_lane, _lane.stops.find(preview.current)):
			_lane = null
	elif preview.exits.has(preview.current):
		if _session.unload(item.id, preview.exits[preview.current]):
			_selected_id = NO_ITEM
	elif _session.shift(item.id, preview.current):
		_grip += preview.current - preview.start


# Returns the held piece to the stack and forgets its door. The crane then
# waits for the player rather than fetching it straight back.
func _put_back_held() -> void:
	if _session.held() != null:
		_fetch_paused = true
	_session.put_back()
	_lane = null


# The session refused an action: turn its reason into a flash or a shake.
func _on_action_refused(reason: StringName, item_ids: Array[int]) -> void:
	if reason == PackingSession.REFUSED_NO_MOVES:
		moves_missed.emit()
		return
	var active: PackItem = active_item()
	var shaken_id: int = NO_ITEM
	if active != null:
		shaken_id = active.id
	var no_cells: Array[Vector2i] = []
	attempt_refused.emit(shaken_id, CraneRefusals.others(item_ids, active), no_cells)
