## Turns the touch events inside one control into gestures: a tap; a drag,
## whose axis locks to left-right or up-down once the finger has travelled
## the lock distance; and a swipe, when a drag is released away from where it
## began. Mouse input arrives as touch (project setting "emulate touch from
## mouse"). It decides nothing about the game and not what was touched.
class_name GestureReader
extends RefCounted

# Where to look
#   Made by:    ui/packing/loading_bay.gd -> _listen_for_gestures()
#   Heard by:   ui/packing/loading_bay.gd -> _on_tapped(), _on_drag_started(), _on_drag_moved(),
#               _on_drag_ended(), _on_swiped()
#   Asked by:   ui/packing/loading_bay.gd -> _carry_point()
#   Numbers:    ui/common/presentation_tuning.gd, the Touch group
#   Tests:      tests/ui/test_gesture_reader.gd

enum Axis { HORIZONTAL, VERTICAL }

signal tapped(position: Vector2)
## The finger has travelled the lock distance. The position is where it
## first touched; the axis will not change until it lifts.
signal drag_started(position: Vector2, axis: Axis)
## How far the finger is from where it began, along the locked axis only.
signal drag_moved(offset: Vector2)
signal drag_ended(offset: Vector2)
## A drag ended at least the lock distance from where it began. The
## direction is Vector2i.LEFT, RIGHT, UP or DOWN.
signal swiped(direction: Vector2i)

const NO_FINGER: int = -1

var _tuning: PresentationTuning
# Only the first finger down is followed; others are ignored until it lifts.
var _finger: int = NO_FINGER
var _start: Vector2 = Vector2.ZERO
var _latest: Vector2 = Vector2.ZERO
var _locked: bool = false
var _axis: Axis = Axis.HORIZONTAL


# The tuning supplies the tap and lock distances, read at each touch.
func _init(tuning: PresentationTuning) -> void:
	_tuning = tuning


## Reads every touch that lands on this control.
func attach_to(control: Control) -> void:
	control.gui_input.connect(handle_event)


## Takes one input event from the attached control. Tests call it directly.
func handle_event(event: InputEvent) -> void:
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	if touch != null:
		if touch.pressed:
			_press(touch)
		elif touch.index == _finger:
			_release(touch)
		return
	var drag: InputEventScreenDrag = event as InputEventScreenDrag
	if drag != null and drag.index == _finger:
		_move(drag.position)


## Where the finger in play first touched, inside the attached control.
func start_position() -> Vector2:
	return _start


## How far the finger has gone from where it touched, on both axes. A
## piece carried by the finger follows this, not the locked axis.
func finger_travel() -> Vector2:
	return _latest - _start


# A finger went down: remember where.
func _press(touch: InputEventScreenTouch) -> void:
	if _finger != NO_FINGER:
		return
	_finger = touch.index
	_start = touch.position
	_latest = touch.position
	_locked = false


# The finger moved: lock the axis once it has gone far enough, then report the drag.
func _move(at: Vector2) -> void:
	_latest = at
	var travel: Vector2 = at - _start
	if not _locked:
		if travel.length() < _tuning.swipe_lock_distance:
			return
		_locked = true
		_axis = Axis.VERTICAL
		if absf(travel.x) >= absf(travel.y):
			_axis = Axis.HORIZONTAL
		drag_started.emit(_start, _axis)
	drag_moved.emit(_along_axis(travel))


# The finger lifted: a tap, the end of a drag, or nothing.
func _release(touch: InputEventScreenTouch) -> void:
	_finger = NO_FINGER
	if touch.canceled:
		# The system took the touch away: put everything back.
		if _locked:
			drag_ended.emit(Vector2.ZERO)
		return
	var travel: Vector2 = touch.position - _start
	if not _locked:
		if travel.length() <= _tuning.tap_max_travel:
			tapped.emit(_start)
		return
	var offset: Vector2 = _along_axis(travel)
	drag_ended.emit(offset)
	if offset.length() >= _tuning.swipe_lock_distance:
		swiped.emit(Vector2i(int(signf(offset.x)), int(signf(offset.y))))


# The part of a movement that lies along the locked axis.
func _along_axis(travel: Vector2) -> Vector2:
	if _axis == Axis.HORIZONTAL:
		return Vector2(travel.x, 0.0)
	return Vector2(0.0, travel.y)
