## Draws a ContainerLayout as a grid of square spots and converts between
## positions inside this control and grid cells. Each cell is drawn from its
## legend entry: the pattern when one is assigned, otherwise the colour and
## label. It can keep empty columns either side of the grid (the aprons) for
## other layers to draw outside the doors. It draws no items and reads no input.
class_name GridView
extends Control

# Where to look
#   Shown by:   ui/packing/loading_bay.gd -> show_round()
#   Drawn over: ui/packing/gantry_view.gd -> _draw()
#               ui/packing/item_layer.gd -> _draw()
#   Reads:      core/grid/container_layout.gd -> entry_at(), overlay_entry_at()
#               core/grid/legend_entry.gd, for each cell's colour, label and pattern
#   Numbers:    ui/common/presentation_tuning.gd, the Spots group
#   Tests:      tests/ui/test_grid_view.gd

var _layout: ContainerLayout
var _tuning: PresentationTuning
var _apron_left: int = 0
var _apron_right: int = 0


## Shows a layout. The aprons are counted in columns of spots.
func show_layout(shown_layout: ContainerLayout, tuning: PresentationTuning, left_columns: int = 0, right_columns: int = 0) -> void:
	_layout = shown_layout
	_tuning = tuning
	_apron_left = left_columns
	_apron_right = right_columns
	queue_redraw()


## The layout being shown.
func layout() -> ContainerLayout:
	return _layout


## Empty columns kept to the left of the grid.
func apron_left() -> int:
	return _apron_left


## Empty columns kept to the right of the grid.
func apron_right() -> int:
	return _apron_right


## The largest spot that fits the space this control was given, capped by
## presentation.tres.
func spot_size() -> float:
	var columns_and_rows: Vector2i = _drawn_cells()
	if columns_and_rows.x == 0 or columns_and_rows.y == 0:
		return 0.0
	var fitted: float = minf(size.x / float(columns_and_rows.x), size.y / float(columns_and_rows.y))
	return minf(fitted, _tuning.spot_size)


## True when the grid had to be drawn with spots below the tuned minimum.
func is_cramped() -> bool:
	return _layout != null and spot_size() < _tuning.spot_size_min


## Where a point given in cells is inside this control. (0, 0) is the
## top-left corner of the layout's first cell; (0.5, 0.5) is its centre.
func point_of(grid_point: Vector2) -> Vector2:
	var spot: float = spot_size()
	var drawn: Vector2 = Vector2(_drawn_cells()) * spot
	var corner: Vector2 = (size - drawn) / 2.0
	return corner + (Vector2(_apron_left, 0.0) + grid_point) * spot


## The reverse of point_of: a position inside this control, in cells.
func grid_point_at(at: Vector2) -> Vector2:
	var spot: float = spot_size()
	if spot <= 0.0:
		return Vector2.ZERO
	return (at - point_of(Vector2.ZERO)) / spot


## The cell under a position inside this control. Cells in the left apron have negative columns.
func cell_at(at: Vector2) -> Vector2i:
	return Vector2i(grid_point_at(at).floor())


## The rectangle a cell is drawn in.
func cell_rect(cell: Vector2i) -> Rect2:
	var spot: float = spot_size()
	return Rect2(point_of(Vector2(cell)), Vector2(spot, spot))


# Paints every cell of the layout, then any designation over it.
func _draw() -> void:
	if _layout == null:
		return
	var font_size: int = LabelPainter.size_for_spot(spot_size(), _tuning)
	for row: int in _layout.size().y:
		for column: int in _layout.size().x:
			var cell: Vector2i = Vector2i(column, row)
			if _layout.is_outside(cell):
				continue
			_draw_entry(cell_rect(cell), _layout.entry_at(cell), font_size)
			var marked: LegendEntry = _layout.overlay_entry_at(cell)
			if marked != null:
				_draw_designation(cell_rect(cell), marked, font_size)


# One cell: its pattern, or its colour, a thin line and its label.
func _draw_entry(rect: Rect2, entry: LegendEntry, font_size: int) -> void:
	if entry.pattern != null:
		draw_texture_rect(entry.pattern, rect, false)
		return
	draw_rect(rect, entry.colour)
	draw_rect(rect, _tuning.grid_line_colour, false)
	LabelPainter.draw_centred(self, rect, entry.label, font_size, _tuning.cell_label_colour)


# A designated spot keeps the look of the spot beneath and wears the mark's
# pattern or colour over it.
func _draw_designation(rect: Rect2, entry: LegendEntry, font_size: int) -> void:
	if entry.pattern != null:
		draw_texture_rect(entry.pattern, rect, false)
		return
	var wash: Color = entry.colour
	wash.a *= _tuning.designation_opacity
	draw_rect(rect, wash)
	draw_rect(rect.grow(-_tuning.piece_inset), entry.colour, false, _tuning.outline_width)
	LabelPainter.draw_centred(self, rect, entry.label, font_size, _tuning.cell_label_colour)


# Columns and rows the control makes room for, aprons included.
func _drawn_cells() -> Vector2i:
	if _layout == null:
		return Vector2i.ZERO
	return Vector2i(_apron_left + _layout.size().x + _apron_right, _layout.size().y)
