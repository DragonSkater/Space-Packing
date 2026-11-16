## Draws, above the pieces, the crane that holds the held piece: its arm
## across the piece to each door it waits at, and the gripper along the
## piece's outer edge, in the active colour. It is drawn whether or not those
## doors will take the piece, so it is plain the crane has it. GantryView
## draws the rest of the gantry, under the pieces. It changes nothing.
class_name CraneGripView
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named CraneGripView, after ItemLayer
#   Shown by:   ui/packing/loading_bay.gd -> show_round()
#   Reads:      core/packing/packing_session.gd -> held()
#               ui/packing/crane_controls.gd -> held_doors(), held_origin(), slide()
#   Draws on:   ui/common/grid_view.gd -> cell_rect(), point_of(), spot_size()
#   Numbers:    ui/common/presentation_tuning.gd, the Gantry and Colours groups
#   Tests:      tests/ui/test_crane_controls.gd covers what it reads; how it looks is checked by eye

var _grid: GridView
var _session: PackingSession
var _controls: CraneControls
var _tuning: PresentationTuning


## Shows a new round. Called by LoadingBay.show_round.
func show_round(grid: GridView, session: PackingSession, controls: CraneControls, tuning: PresentationTuning) -> void:
	_grid = grid
	_session = session
	_controls = controls
	_tuning = tuning
	_session.held_changed.connect(queue_redraw)
	_controls.view_changed.connect(queue_redraw)
	queue_redraw()


# Paints the holding arms and the gripper. Nothing while the crane is empty,
# while the finger carries the piece, or while it slides in, since the
# crane has let go of it then.
func _draw() -> void:
	if _session == null:
		return
	var held: PackItem = _session.held()
	var doors: Array[Vector2i] = _controls.held_doors()
	if held == null or doors.is_empty():
		return
	var slide: SlidePreview = _controls.slide()
	if slide != null and slide.item == held:
		return
	var origin: Vector2 = _controls.held_origin()
	var top_left: Vector2 = _grid.point_of(origin)
	var bottom_right: Vector2 = _grid.point_of(origin + Vector2(held.shape.bounds().size))
	var waits_on_left: bool = origin.x < 0.0
	var outer_edge: float = bottom_right.x
	if waits_on_left:
		outer_edge = top_left.x
	for door: Vector2i in doors:
		_draw_arm_across(door, outer_edge, waits_on_left)
	var reach: float = _grid.spot_size() * _tuning.arm_gripper_scale / 2.0
	var top: Vector2 = Vector2(outer_edge, top_left.y - reach)
	var bottom: Vector2 = Vector2(outer_edge, bottom_right.y + reach)
	draw_line(top, bottom, _tuning.active_colour, _tuning.arm_width)


# One holding arm, from the piece's outer edge across it to its door.
func _draw_arm_across(door: Vector2i, outer_edge: float, waits_on_left: bool) -> void:
	var door_rect: Rect2 = _grid.cell_rect(door)
	var height: float = door_rect.get_center().y
	var door_edge: float = door_rect.end.x
	if waits_on_left:
		door_edge = door_rect.position.x
	draw_line(Vector2(outer_edge, height), Vector2(door_edge, height), _tuning.active_colour, _tuning.arm_width)
