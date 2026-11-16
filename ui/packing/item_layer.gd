## Draws the pieces over the grid: those in the container, the one the
## crane holds or is bringing from the stack, a piece carried by the finger,
## the Active box round the piece the next gesture acts on, the grip pin,
## the note saying what letting go of a slide would cost, and the effects of
## a refused action. Pieces glide to where the round says they are, at the
## crane's speed, so nothing jumps. It reads the round and changes nothing.
class_name ItemLayer
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named ItemLayer
#   Shown by:   ui/packing/loading_bay.gd -> show_round()
#   Reads:      core/packing/packing_session.gd -> state(), held(), cost_of()
#               ui/packing/crane_controls.gd -> active_item(), selected_item(), grip(), held_lane(),
#               slide(), pending_action(), is_carrying(), carry_point(), carry_lane(), stack_point()
#   Paints via: ui/common/item_painter.gd -> draw_item(), draw_outline()
#   Words:      ui/packing/move_words.gd -> let_go()
#   Numbers:    ui/common/presentation_tuning.gd, the Crane, Moves feedback, Colours and Animation groups

const CELL_CENTRE: Vector2 = Vector2(0.5, 0.5)
const PIN_SEGMENTS: int = 24
const ACTIVE_TEXT: String = "ACTIVE"
const NEXT_TEXT: String = "NEXT"

var _grid: GridView
var _session: PackingSession
var _controls: CraneControls
var _tuning: PresentationTuning

# Where each piece is drawn right now, in cells, by item id. A piece glides
# from here towards where the round says it is.
var _shown: Dictionary[int, Vector2] = {}
var _shaken_id: int = CraneControls.NO_ITEM
var _lit_ids: Array[int] = []
var _lit_cells: Array[Vector2i] = []
# Each runs from 0 to 1 while its effect plays; 1 means nothing to show.
var _shake_progress: float = 1.0
var _light_progress: float = 1.0
var _shake_tween: Tween
var _light_tween: Tween


## Shows a new round. Called by LoadingBay.show_round.
func show_round(grid: GridView, session: PackingSession, controls: CraneControls, tuning: PresentationTuning) -> void:
	_grid = grid
	_session = session
	_controls = controls
	_tuning = tuning
	_shown.clear()
	_shake_progress = 1.0
	_light_progress = 1.0
	_session.state().changed.connect(queue_redraw)
	_session.held_changed.connect(queue_redraw)
	_session.item_turned.connect(_on_item_turned)
	_controls.view_changed.connect(queue_redraw)
	_controls.attempt_refused.connect(_on_attempt_refused)
	queue_redraw()


# Moves every drawn piece a step towards where it belongs.
func _process(delta: float) -> void:
	if _session == null:
		return
	var targets: Dictionary[int, Vector2] = _targets()
	var moved: bool = false
	for item_id: int in _shown.keys():
		if not targets.has(item_id):
			_shown.erase(item_id)
	for item_id: int in targets:
		var target: Vector2 = targets[item_id]
		if not _shown.has(item_id):
			_shown[item_id] = _starting_point(item_id, target)
		var step: float = _speed_for(item_id) * delta
		var next: Vector2 = _shown[item_id].move_toward(target, step)
		if not next.is_equal_approx(_shown[item_id]):
			moved = true
		_shown[item_id] = next
	if moved:
		queue_redraw()


# Where every piece this layer draws belongs right now, in cells.
func _targets() -> Dictionary[int, Vector2]:
	var targets: Dictionary[int, Vector2] = {}
	for item: PackItem in _session.state().items():
		targets[item.id] = Vector2(item.origin)
	var held: PackItem = _session.held()
	if held != null and _controls.is_carrying() and _controls.carry_lane() != null:
		# Over a door, the carried piece settles where it would wait there,
		# so the player sees where letting go will put it.
		targets[held.id] = Vector2(_controls.carry_lane().hold_origin)
	elif held != null and _controls.is_carrying():
		targets[held.id] = _controls.carry_point() - Vector2(held.shape.bounds().size) / 2.0
	elif held != null and _controls.held_lane() != null:
		targets[held.id] = Vector2(_controls.held_lane().hold_origin)
	var slide: SlidePreview = _controls.slide()
	if slide != null and targets.has(slide.item.id):
		targets[slide.item.id] = Vector2(slide.finger_x, float(slide.start.y))
	return targets


# A piece seen for the first time: the held one sets off from the stack, a
# carried one starts under the finger, and anything else starts in place.
func _starting_point(item_id: int, target: Vector2) -> Vector2:
	var held: PackItem = _session.held()
	if held == null or held.id != item_id or _controls.is_carrying():
		return target
	return _controls.stack_point() - Vector2(held.shape.bounds().size) / 2.0


# A piece under the finger follows it; anything else moves at crane speed.
func _speed_for(item_id: int) -> float:
	var slide: SlidePreview = _controls.slide()
	var held: PackItem = _session.held()
	if slide != null and slide.item.id == item_id:
		return _tuning.piece_follow_speed
	if held != null and held.id == item_id and _controls.is_carrying():
		return _tuning.piece_follow_speed
	return _tuning.crane_speed


# Paints the loaded pieces, any lit cells, the held piece, then the active
# piece on top with its box, grip and cost note.
func _draw() -> void:
	if _session == null:
		return
	var active: PackItem = _controls.active_item()
	for item: PackItem in _session.state().items():
		if item != active:
			_draw_piece(item)
	for cell: Vector2i in _lit_cells:
		if _light_progress < 1.0:
			draw_rect(_grid.cell_rect(cell), _fading(_tuning.in_the_way_colour))
	var held: PackItem = _session.held()
	if held != null and held != active and _shown.has(held.id):
		_draw_piece(held)
		_draw_caption(held, NEXT_TEXT, _tuning.selection_colour)
	if active != null and _shown.has(active.id):
		_draw_piece(active)
		_draw_active_box(active)
		if active == _controls.selected_item():
			_draw_grip(active)
		_draw_cost_note(active)


# One piece where it is shown, with its shake and light as needed.
func _draw_piece(item: PackItem) -> void:
	var spot: float = _grid.spot_size()
	var corner: Vector2 = _corner(item)
	ItemPainter.draw_item(self, item, corner, spot, _tuning)
	if _lit_ids.has(item.id) and _light_progress < 1.0:
		var light: Color = _fading(_tuning.in_the_way_colour)
		for cell: Vector2i in item.shape.cells:
			draw_rect(Rect2(corner + Vector2(cell) * spot, Vector2(spot, spot)), light)


# The box round the piece the next slide or turn acts on, with its caption.
func _draw_active_box(item: PackItem) -> void:
	var box: Rect2 = _bounds(item).grow(_tuning.active_box_margin)
	draw_rect(box, _tuning.active_colour, false, _tuning.outline_width)
	_draw_caption(item, ACTIVE_TEXT, _tuning.active_colour)


# A short word just above a piece's box.
func _draw_caption(item: PackItem, text: String, colour: Color) -> void:
	var box: Rect2 = _bounds(item).grow(_tuning.active_box_margin)
	var height: float = _note_height()
	var line: Rect2 = Rect2(box.get_center().x - size.x / 2.0, box.position.y - height, size.x, height)
	LabelPainter.draw_centred(self, line, text, _tuning.cost_note_font_size, colour)


# While a piece slides, says under it what letting go there would cost.
func _draw_cost_note(item: PackItem) -> void:
	var slide: SlidePreview = _controls.slide()
	if slide == null or slide.item != item:
		return
	var action: StringName = _controls.pending_action()
	var cost: int = _session.cost_of(action)
	var colour: Color = _tuning.costly_note_colour
	if action == CraneControls.NO_ACTION or cost == 0:
		colour = _tuning.free_note_colour
	var box: Rect2 = _bounds(item).grow(_tuning.active_box_margin)
	var height: float = _note_height()
	var line: Rect2 = Rect2(box.get_center().x - size.x / 2.0, box.end.y, size.x, height)
	LabelPainter.draw_centred(self, line, MoveWords.let_go(action, cost), _tuning.cost_note_font_size, colour)


# The pin marks the cell the piece was tapped on and travels with it.
func _draw_grip(selected: PackItem) -> void:
	var travelled: Vector2 = _shown_at(selected) - Vector2(selected.origin)
	var centre: Vector2 = _grid.point_of(Vector2(_controls.grip()) + travelled + CELL_CENTRE)
	if selected.id == _shaken_id:
		centre.x += _shake_offset()
	var radius: float = _grid.spot_size() * _tuning.grip_pin_scale
	draw_circle(centre, radius, _tuning.grip_colour)
	draw_arc(centre, radius, 0.0, TAU, PIN_SEGMENTS, _tuning.selection_colour, _tuning.outline_width)


# The height of a line of the small notes and captions.
func _note_height() -> float:
	return get_theme_default_font().get_height(_tuning.cost_note_font_size)


# Where a piece is drawn, in cells: where it has glided to, or, before its
# first step, where it lies.
func _shown_at(item: PackItem) -> Vector2:
	return _shown.get(item.id, Vector2(item.origin))


# The top-left corner a piece is drawn at, shake included.
func _corner(item: PackItem) -> Vector2:
	var corner: Vector2 = _grid.point_of(_shown_at(item))
	if item.id == _shaken_id:
		corner.x += _shake_offset()
	return corner


# The rectangle round a piece where it is drawn.
func _bounds(item: PackItem) -> Rect2:
	return Rect2(_corner(item), Vector2(item.shape.bounds().size) * _grid.spot_size())


# A wobble to either side that dies away.
func _shake_offset() -> float:
	if _shake_progress >= 1.0:
		return 0.0
	var swing: float = sin(_shake_progress * TAU * float(_tuning.shake_count))
	return swing * _tuning.shake_distance * (1.0 - _shake_progress)


# A colour that fades as the light effect runs out.
func _fading(colour: Color) -> Color:
	var faded: Color = colour
	faded.a *= 1.0 - _light_progress
	return faded


# A turn changes a piece's outline at once, so it is not glided: the piece
# is shown where it now lies.
func _on_item_turned(item: PackItem) -> void:
	_shown[item.id] = Vector2(item.origin)
	queue_redraw()


# CraneControls refused something: start the shake and the light.
func _on_attempt_refused(shaken_item_id: int, lit_item_ids: Array[int], lit_cells: Array[Vector2i]) -> void:
	_shaken_id = shaken_item_id
	_lit_ids = lit_item_ids
	_lit_cells = lit_cells
	if _shake_tween != null:
		_shake_tween.kill()
	if _light_tween != null:
		_light_tween.kill()
	_shake_tween = create_tween()
	_shake_tween.tween_method(_set_shake_progress, 0.0, 1.0, _tuning.shake_duration)
	_light_tween = create_tween()
	_light_tween.tween_method(_set_light_progress, 0.0, 1.0, _tuning.in_the_way_duration)


# Stepped by a tween while the shake plays.
func _set_shake_progress(progress: float) -> void:
	_shake_progress = progress
	queue_redraw()


# Stepped by a tween while the light fades.
func _set_light_progress(progress: float) -> void:
	_light_progress = progress
	queue_redraw()
