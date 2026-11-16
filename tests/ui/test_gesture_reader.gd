## Tests for GestureReader, fed made-up touch events: what counts as a tap,
## when a drag locks to an axis, and when a release is a swipe. With the
## distances used here a tap may travel 10 units and a drag locks at 16.
extends TestCase

const TAP_TRAVEL: float = 10.0
const LOCK_DISTANCE: float = 16.0

var _taps: Array[Vector2] = []
var _started_axes: Array[GestureReader.Axis] = []
var _moves: Array[Vector2] = []
var _ends: Array[Vector2] = []
var _swipes: Array[Vector2i] = []


func test_a_touch_that_barely_moves_is_a_tap_where_it_began() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(54, 53))
	_touch(reader, Vector2(54, 53), false)
	assert_eq(_taps, [Vector2(50, 50)] as Array[Vector2])
	assert_eq(_started_axes.size(), 0, "no drag")


func test_a_touch_that_wanders_too_far_for_a_tap_but_never_locks_is_nothing() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(62, 50))
	_touch(reader, Vector2(62, 50), false)
	assert_eq(_taps.size(), 0)
	assert_eq(_started_axes.size(), 0)
	assert_eq(_swipes.size(), 0)


func test_a_sideways_drag_locks_to_horizontal_and_reports_its_offset() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(70, 55))
	_drag(reader, Vector2(90, 58))
	_touch(reader, Vector2(90, 58), false)
	assert_eq(_started_axes, [GestureReader.Axis.HORIZONTAL] as Array[GestureReader.Axis])
	assert_eq(_moves, [Vector2(20, 0), Vector2(40, 0)] as Array[Vector2], "only the sideways part")
	assert_eq(_ends, [Vector2(40, 0)] as Array[Vector2])
	assert_eq(_swipes, [Vector2i.RIGHT] as Array[Vector2i])
	assert_eq(_taps.size(), 0, "a drag is not a tap")


func test_an_upward_swipe_locks_to_vertical_and_reports_up() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 100), true)
	_drag(reader, Vector2(53, 80))
	_touch(reader, Vector2(53, 70), false)
	assert_eq(_started_axes, [GestureReader.Axis.VERTICAL] as Array[GestureReader.Axis])
	assert_eq(_swipes, [Vector2i.UP] as Array[Vector2i])


func test_a_downward_swipe_reports_down() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 100), true)
	_drag(reader, Vector2(50, 130))
	_touch(reader, Vector2(50, 130), false)
	assert_eq(_swipes, [Vector2i.DOWN] as Array[Vector2i])


func test_the_axis_does_not_change_once_it_has_locked() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(70, 50))
	_drag(reader, Vector2(70, 120))
	_touch(reader, Vector2(72, 130), false)
	assert_eq(_started_axes, [GestureReader.Axis.HORIZONTAL] as Array[GestureReader.Axis], "locked once")
	assert_eq(_moves[1], Vector2(20, 0), "the finger went down, the drag did not")
	assert_eq(_swipes, [Vector2i.RIGHT] as Array[Vector2i])


func test_the_finger_travel_is_reported_on_both_axes_even_once_locked() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(70, 50))
	_drag(reader, Vector2(80, 95))
	assert_eq(_moves[1], Vector2(30, 0), "the drag keeps to its axis")
	assert_eq(reader.finger_travel(), Vector2(30, 45), "the finger does not")


func test_a_drag_released_back_where_it_began_is_not_a_swipe() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(70, 50))
	_drag(reader, Vector2(52, 50))
	_touch(reader, Vector2(52, 50), false)
	assert_eq(_ends, [Vector2(2, 0)] as Array[Vector2])
	assert_eq(_swipes.size(), 0)
	assert_eq(_taps.size(), 0)


func test_a_second_finger_is_ignored_while_the_first_is_down() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true, 0)
	_touch(reader, Vector2(200, 200), true, 1)
	_drag(reader, Vector2(260, 200), 1)
	_touch(reader, Vector2(260, 200), false, 1)
	assert_eq(_started_axes.size(), 0, "the second finger drags nothing")
	_touch(reader, Vector2(50, 50), false, 0)
	assert_eq(_taps, [Vector2(50, 50)] as Array[Vector2])


func test_a_touch_the_system_cancels_puts_the_drag_back() -> void:
	var reader: GestureReader = _reader()
	_touch(reader, Vector2(50, 50), true)
	_drag(reader, Vector2(90, 50))
	var cancelled: InputEventScreenTouch = InputEventScreenTouch.new()
	cancelled.position = Vector2(90, 50)
	cancelled.pressed = false
	cancelled.canceled = true
	reader.handle_event(cancelled)
	assert_eq(_ends, [Vector2.ZERO] as Array[Vector2])
	assert_eq(_swipes.size(), 0)


func _reader() -> GestureReader:
	var tuning: PresentationTuning = PresentationTuning.new()
	tuning.tap_max_travel = TAP_TRAVEL
	tuning.swipe_lock_distance = LOCK_DISTANCE
	var reader: GestureReader = GestureReader.new(tuning)
	reader.tapped.connect(_taps.append)
	reader.drag_started.connect(_on_drag_started)
	reader.drag_moved.connect(_moves.append)
	reader.drag_ended.connect(_ends.append)
	reader.swiped.connect(_swipes.append)
	return reader


func _on_drag_started(_at: Vector2, axis: GestureReader.Axis) -> void:
	_started_axes.append(axis)


func _touch(reader: GestureReader, at: Vector2, pressed: bool, finger: int = 0) -> void:
	var event: InputEventScreenTouch = InputEventScreenTouch.new()
	event.index = finger
	event.position = at
	event.pressed = pressed
	reader.handle_event(event)


func _drag(reader: GestureReader, at: Vector2, finger: int = 0) -> void:
	var event: InputEventScreenDrag = InputEventScreenDrag.new()
	event.index = finger
	event.position = at
	reader.handle_event(event)
