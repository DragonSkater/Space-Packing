## The middle of the packing screen: the stack, the gantry and the
## container. It reads the gestures made anywhere on it, works out what was
## touched, and passes that to CraneControls in cells, not screen units. It
## also keeps the crane's clock: when the crane is empty it waits a moment
## and then has it fetch the next piece. It holds no rules: what a gesture
## means is CraneControls' business, and what it does is PackingSession's.
class_name LoadingBay
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named Bay
#   Shown by:   ui/packing/packing_screen.gd -> _start_round()
#   Gestures:   ui/common/gesture_reader.gd
#   Passes on:  ui/packing/crane_controls.gd -> tap_stack(), tap_door(), tap_cell(), tap_empty(),
#               grab_cell(), begin_carry(), carry_to(), end_carry(), begin_slide(), slide_by(),
#               end_slide(), turn(), wants_fetch(), fetch()
#   Numbers:    ui/common/presentation_tuning.gd, the Crane group
#   Its parts:  ui/packing/stack_view.gd -> pick_index_at(), slot_point(), ui/common/grid_view.gd, ui/packing/gantry_view.gd,
#               ui/packing/item_layer.gd

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT]

var _session: PackingSession
var _controls: CraneControls
var _reader: GestureReader
# A left-right drag has begun but its first movement, which gives its
# direction, has not arrived yet.
var _slide_pending: bool = false
var _sliding: bool = false
# The gesture in progress began on the stack and carries a piece; its
# release is a drop, not a swipe.
var _carrying: bool = false
var _warned_cramped: bool = false
var _tuning: PresentationTuning
# Seconds the crane has been empty with a piece waiting for it.
var _idle_seconds: float = 0.0

@onready var _stack_view: StackView = %StackView
@onready var _grid: GridView = %GridView
@onready var _gantry: GantryView = %GantryView
@onready var _items: ItemLayer = %ItemLayer


## Shows a new round in every part. Called by PackingScreen._start_round.
func show_round(session: PackingSession, controls: CraneControls, tuning: PresentationTuning) -> void:
	_session = session
	_controls = controls
	_tuning = tuning
	_slide_pending = false
	_sliding = false
	_carrying = false
	_idle_seconds = 0.0
	_warned_cramped = false
	if _reader == null:
		_listen_for_gestures(tuning)
	var layout: ContainerLayout = session.state().layout
	# A held piece waits outside its door, so each side with a door is given
	# room for the longest side of any piece in the round.
	var widest: int = _longest_side(session.stack())
	_grid.show_layout(layout, tuning, _apron(layout, Vector2i.LEFT, widest), _apron(layout, Vector2i.RIGHT, widest))
	_stack_view.show_round(session, controls, tuning, widest)
	_gantry.show_round(_grid, session, controls, tuning)
	_items.show_round(_grid, session, controls, tuning)
	_warn_if_cramped.call_deferred()


# Creates the gesture reader, once, and connects its signals to the handlers below.
func _listen_for_gestures(tuning: PresentationTuning) -> void:
	_reader = GestureReader.new(tuning)
	_reader.attach_to(self)
	_reader.tapped.connect(_on_tapped)
	_reader.drag_started.connect(_on_drag_started)
	_reader.drag_moved.connect(_on_drag_moved)
	_reader.drag_ended.connect(_on_drag_ended)
	_reader.swiped.connect(_on_swiped)
	_grid.resized.connect(_warn_if_cramped)


# A tap: on the stack, on a lit door or its arm, on a piece, or on nothing.
func _on_tapped(at: Vector2) -> void:
	var in_stack: Vector2 = _in_child(_stack_view, at)
	if Rect2(Vector2.ZERO, _stack_view.size).has_point(in_stack):
		var index: int = _stack_view.pick_index_at(in_stack)
		if index == StackView.NOTHING_TO_PICK:
			_controls.tap_empty()
		else:
			_controls.tap_stack(index, _stack_point(index))
		return
	var grid_point: Vector2 = _grid.grid_point_at(_in_child(_grid, at))
	var lane: EntryLane = _gantry.lane_at(grid_point)
	if lane != null:
		_controls.tap_door(lane)
		return
	# A cell with no piece on it counts as empty space.
	_controls.tap_cell(Vector2i(grid_point.floor()))


# An empty crane fetches the next piece once it has waited long enough.
func _process(delta: float) -> void:
	if _controls == null or not _tuning.crane_auto_fetch or not _controls.wants_fetch():
		_idle_seconds = 0.0
		return
	_idle_seconds += delta
	if _idle_seconds >= _tuning.crane_fetch_delay:
		_idle_seconds = 0.0
		_controls.fetch(_stack_point(0))


# A drag locked to an axis. One that starts on the stack carries a piece
# out; one that starts on a piece or a door makes that piece the active one.
# After that, only a left-right drag slides.
func _on_drag_started(at: Vector2, axis: GestureReader.Axis) -> void:
	_carrying = false
	_slide_pending = false
	var in_stack: Vector2 = _in_child(_stack_view, at)
	if Rect2(Vector2.ZERO, _stack_view.size).has_point(in_stack):
		var index: int = _stack_view.pick_index_at(in_stack)
		if index != StackView.NOTHING_TO_PICK:
			_carrying = _controls.begin_carry(index, _stack_point(index))
		return
	var grid_point: Vector2 = _grid.grid_point_at(_in_child(_grid, at))
	if not _controls.grab_cell(Vector2i(grid_point.floor())):
		var lane: EntryLane = _gantry.lane_at(grid_point)
		if lane != null:
			_controls.tap_door(lane)
	_slide_pending = axis == GestureReader.Axis.HORIZONTAL


# The finger moved: carry the piece under it, or start the slide on the
# first movement and then follow it.
func _on_drag_moved(offset: Vector2) -> void:
	if _carrying:
		var point: Vector2 = _carry_point()
		_controls.carry_to(point, _gantry.lane_at(point))
		return
	if _slide_pending:
		_slide_pending = false
		_sliding = _controls.begin_slide(Vector2i(int(signf(offset.x)), 0))
	if _sliding:
		_controls.slide_by(offset.x / _grid.spot_size())


# The finger lifted: the piece stays where it is shown.
func _on_drag_ended(_offset: Vector2) -> void:
	_slide_pending = false
	if _carrying:
		_controls.end_carry()
		return
	if _sliding:
		_sliding = false
		_controls.end_slide()


# PLAN.md section 10, D29: swipe down turns clockwise, up anticlockwise.
func _on_swiped(direction: Vector2i) -> void:
	if _carrying:
		_carrying = false
		return
	if direction == Vector2i.DOWN:
		_controls.turn(true)
	elif direction == Vector2i.UP:
		_controls.turn(false)


# One piece of the pile, in cells of the grid: where the crane picks it up.
func _stack_point(index_from_top: int) -> Vector2:
	var on_screen: Vector2 = _stack_view.get_global_transform() * _stack_view.slot_point(index_from_top)
	return _grid.grid_point_at(_grid.get_global_transform().affine_inverse() * on_screen)


# Where the finger is now, in cells of the grid.
func _carry_point() -> Vector2:
	var finger: Vector2 = _reader.start_position() + _reader.finger_travel()
	return _grid.grid_point_at(_in_child(_grid, finger))


# A position inside this control, as a position inside one of its parts.
func _in_child(child: Control, at: Vector2) -> Vector2:
	return child.get_global_transform().affine_inverse() * (get_global_transform() * at)


# The longest side of any piece, in cells.
func _longest_side(items: Array[PackItem]) -> int:
	var longest: int = 0
	for item: PackItem in items:
		var bounds: Vector2i = item.shape.bounds().size
		longest = maxi(longest, maxi(bounds.x, bounds.y))
	return longest


# Columns to keep clear on one side: none when that side has no door.
func _apron(layout: ContainerLayout, side: Vector2i, columns: int) -> int:
	if GantryView.entrance_doors(layout, side).is_empty():
		return 0
	return columns


# Says so in the console, once per round, when the spots are too small.
func _warn_if_cramped() -> void:
	if _session == null or _warned_cramped or not _grid.is_cramped():
		return
	_warned_cramped = true
	push_warning("The container needs spots of %.1f units, smaller than the minimum in presentation.tres." % _grid.spot_size())
