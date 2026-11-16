## Draws one item on any control: its texture when the item type has one,
## stretched over the item's bounding box and turned with it, otherwise a
## coloured block in the item's shape with its name on it. It also draws the
## outline of a shape, which screens use to mark a selection. It decides
## nothing about where an item is; the caller says where its corner goes.
class_name ItemPainter
extends RefCounted

# Where to look
#   Used by:    ui/packing/item_layer.gd -> _draw_piece()
#               ui/packing/stack_view.gd -> _draw()
#   Draws:      core/packing/pack_item.gd, with the colour or texture of core/packing/pack_item_type.gd
#   Letters:    ui/common/label_painter.gd -> draw_centred()
#   Numbers:    ui/common/presentation_tuning.gd, the Spots and Colours groups

const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


## Draws the item with the top-left corner of its bounding box at top_left
## and each of its cells spot units across.
static func draw_item(canvas: Control, item: PackItem, top_left: Vector2, spot: float, tuning: PresentationTuning, opacity: float = 1.0) -> void:
	if item.type.texture != null:
		_draw_texture(canvas, item, top_left, spot, opacity)
		return
	var fill: Color = item.type.colour
	fill.a *= opacity
	for cell: Vector2i in item.shape.cells:
		canvas.draw_rect(_cell_rect(item.shape, cell, top_left, spot, tuning.piece_inset), fill)
	var border: Color = fill.darkened(tuning.piece_border_darkening)
	draw_outline(canvas, item.shape, top_left, spot, tuning.piece_inset, border, tuning.outline_width)
	var label_rect: Rect2 = Rect2(top_left + Vector2(item.shape.cells[0]) * spot, Vector2(spot, spot))
	var label_colour: Color = tuning.piece_label_colour
	label_colour.a *= opacity
	LabelPainter.draw_centred(canvas, label_rect, item.type.display_name, LabelPainter.size_for_spot(spot, tuning), label_colour)


## Draws a line along every outer edge of the shape, inset from the edge of
## its cells. Edges shared by two cells of the shape are left alone, so the
## shape reads as one piece.
static func draw_outline(canvas: Control, shape: CellShape, top_left: Vector2, spot: float, inset: float, colour: Color, width: float) -> void:
	for cell: Vector2i in shape.cells:
		var rect: Rect2 = _cell_rect(shape, cell, top_left, spot, inset)
		var corner: Vector2 = rect.position
		var far: Vector2 = rect.end
		if not shape.cells.has(cell + Vector2i.LEFT):
			canvas.draw_line(corner, Vector2(corner.x, far.y), colour, width)
		if not shape.cells.has(cell + Vector2i.RIGHT):
			canvas.draw_line(Vector2(far.x, corner.y), far, colour, width)
		if not shape.cells.has(cell + Vector2i.UP):
			canvas.draw_line(corner, Vector2(far.x, corner.y), colour, width)
		if not shape.cells.has(cell + Vector2i.DOWN):
			canvas.draw_line(Vector2(corner.x, far.y), far, colour, width)


# The rectangle of one cell, pulled in by the inset on every side where the
# shape has no neighbouring cell.
static func _cell_rect(shape: CellShape, cell: Vector2i, top_left: Vector2, spot: float, inset: float) -> Rect2:
	var rect: Rect2 = Rect2(top_left + Vector2(cell) * spot, Vector2(spot, spot))
	for side: Vector2i in SIDES:
		if not shape.cells.has(cell + side):
			rect = rect.grow_side(_rect_side(side), -inset)
	return rect


# The engine's name for a side of a rectangle.
static func _rect_side(side: Vector2i) -> Side:
	if side == Vector2i.LEFT:
		return SIDE_LEFT
	if side == Vector2i.RIGHT:
		return SIDE_RIGHT
	if side == Vector2i.UP:
		return SIDE_TOP
	return SIDE_BOTTOM


# PLAN.md section 5, "From text to art": the picture is drawn once, unturned,
# over the bounding box of the shape in the item type, and turns with the item.
static func _draw_texture(canvas: Control, item: PackItem, top_left: Vector2, spot: float, opacity: float) -> void:
	var unturned_size: Vector2 = Vector2(item.type.shape().bounds().size) * spot
	var centre: Vector2 = top_left + Vector2(item.shape.bounds().size) * spot / 2.0
	canvas.draw_set_transform(centre, item.quarter_turns * PI / 2.0)
	canvas.draw_texture_rect(item.type.texture, Rect2(-unturned_size / 2.0, unturned_size), false, Color(1.0, 1.0, 1.0, opacity))
	canvas.draw_set_transform(Vector2.ZERO)
