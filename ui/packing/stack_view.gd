## Draws the cargo stack as a pile, top piece first. The pieces that can be
## taken are raised clear of the rest: the top few, and in a round that
## allows it the bottom one, drawn apart under the pile. While the
## crane is empty they wear the NEXT box. A piece the crane holds is drawn
## by ItemLayer, outside a door, never here. It answers which piece a tap is
## for; taking it is CraneControls' job.
class_name StackView
extends Control

# Where to look
#   Scene:      ui/packing/packing_screen.tscn, the node named StackView
#   Used by:    ui/packing/loading_bay.gd -> show_round(), _on_tapped(), _stack_point()
#   Reads:      core/packing/packing_session.gd -> stack(), held(), stack_reachable()
#   Redrawn by: ui/packing/crane_controls.gd, when its view changes
#   Paints via: ui/common/item_painter.gd -> draw_item()
#   Numbers:    ui/common/presentation_tuning.gd, the Stack and Crane groups

const NOTHING_TO_PICK: int = -1
const HIDDEN_COUNT_TEXT: String = "+%d"
const NEXT_TEXT: String = "NEXT"

var _session: PackingSession
var _controls: CraneControls
var _tuning: PresentationTuning


## widest_cells is the longest side of any piece of the round, in cells; the
## column is made wide enough for it.
func show_round(session: PackingSession, controls: CraneControls, tuning: PresentationTuning, widest_cells: int) -> void:
	_session = session
	_controls = controls
	_tuning = tuning
	var needed: float = float(widest_cells) * tuning.stack_spot_size + tuning.stack_gap * 2.0
	custom_minimum_size.x = maxf(needed, tuning.min_touch_target)
	_session.stack_changed.connect(queue_redraw)
	_session.held_changed.connect(queue_redraw)
	_controls.view_changed.connect(queue_redraw)
	queue_redraw()


## How far down the stack a tap reaches: the reachable piece nearest the
## tap, counted from the top. The whole column is the touch target.
func pick_index_at(at: Vector2) -> int:
	var slots: Dictionary[int, Rect2] = _slots()
	var nearest: int = NOTHING_TO_PICK
	var nearest_distance: float = INF
	for index: int in slots:
		if not _session.stack_reachable(index):
			continue
		var distance: float = absf(slots[index].get_center().y - at.y)
		if distance < nearest_distance:
			nearest = index
			nearest_distance = distance
	return nearest


## The middle of the top of the pile, inside this control.
func top_point() -> Vector2:
	return Vector2(size.x / 2.0, _tuning.stack_gap)


## The middle of one piece of the pile, inside this control, or the top of
## the pile when that piece is not drawn.
func slot_point(index_from_top: int) -> Vector2:
	var slots: Dictionary[int, Rect2] = _slots()
	if slots.has(index_from_top):
		return slots[index_from_top].get_center()
	return top_point()


# Paints the pile, then the count of pieces that did not fit. While the
# crane is empty, every piece that can be taken wears the NEXT box.
func _draw() -> void:
	if _session == null:
		return
	var spot: float = _tuning.stack_spot_size
	var stack: Array[PackItem] = _session.stack()
	var slots: Dictionary[int, Rect2] = _slots()
	for index: int in slots:
		var reachable: bool = _session.stack_reachable(index)
		var opacity: float = _tuning.stack_buried_opacity
		if reachable:
			opacity = 1.0
		ItemPainter.draw_item(self, stack[index], slots[index].position, spot, _tuning, opacity)
		if reachable and _session.held() == null:
			_draw_next_box(slots[index])
	if slots.size() < stack.size():
		_draw_hidden_count(stack.size() - slots.size())


# One rectangle per piece of the stack that is drawn, by its index from the
# top. Pieces are laid from the top down while they fit. A bottom piece that
# can be taken is always drawn: raised clear under the rest, with room kept
# for it and for the count of any pieces between that are not drawn.
func _slots() -> Dictionary[int, Rect2]:
	var slots: Dictionary[int, Rect2] = {}
	var stack: Array[PackItem] = _session.stack()
	var pile_size: int = stack.size()
	var room: float = size.y - _count_line_height()
	if _bottom_drawn_apart():
		pile_size -= 1
		room -= _slot(stack[pile_size], 0.0).size.y + _tuning.stack_gap + _tuning.stack_raise
	var top: float = _tuning.stack_gap
	for index: int in pile_size:
		var slot: Rect2 = _slot(stack[index], top)
		if slot.end.y > room:
			break
		slots[index] = slot
		top = slot.end.y + _tuning.stack_gap
		if _session.stack_reachable(index):
			top += _tuning.stack_raise
	if _bottom_drawn_apart():
		if slots.size() < pile_size:
			top += _count_line_height()
		slots[pile_size] = _slot(stack[pile_size], top + _tuning.stack_raise)
	return slots


# True when the bottom piece can be taken only because the round lets the
# bottom be reached, so it is drawn apart from the pile above it.
func _bottom_drawn_apart() -> bool:
	var last: int = _session.stack().size() - 1
	return last > 0 and _session.stack_reachable(last) and not _session.stack_reachable(last - 1)


# The rectangle of one piece, centred in the column, with its top at a height.
func _slot(item: PackItem, top: float) -> Rect2:
	var piece_size: Vector2 = Vector2(item.shape.bounds().size) * _tuning.stack_spot_size
	return Rect2(Vector2((size.x - piece_size.x) / 2.0, top), piece_size)


# The box round the piece the crane will take next, with its caption.
func _draw_next_box(slot: Rect2) -> void:
	var box: Rect2 = slot.grow(_tuning.active_box_margin)
	draw_rect(box, _tuning.active_colour, false, _tuning.outline_width)
	var font: Font = get_theme_default_font()
	var height: float = font.get_height(_tuning.cost_note_font_size)
	var line: Rect2 = Rect2(0.0, box.end.y, size.x, height)
	LabelPainter.draw_centred(self, line, NEXT_TEXT, _tuning.cost_note_font_size, _tuning.active_colour)


# Room kept at the foot of the column for the count of pieces not drawn.
func _count_line_height() -> float:
	return get_theme_default_font().get_height(get_theme_default_font_size())


# Writes how many pieces of the pile are not drawn, just under the last
# piece of the pile that is.
func _draw_hidden_count(count: int) -> void:
	var slots: Dictionary[int, Rect2] = _slots()
	var top: float = _tuning.stack_gap
	for index: int in slots:
		if index < _session.stack().size() - 1 or not _bottom_drawn_apart():
			top = maxf(top, slots[index].end.y + _tuning.stack_gap)
	var line: Rect2 = Rect2(0.0, top, size.x, _count_line_height())
	LabelPainter.draw_centred(self, line, HIDDEN_COUNT_TEXT % count, get_theme_default_font_size(), _tuning.cell_label_colour)
