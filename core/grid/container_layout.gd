## A container's grid, parsed from text with a legend. It answers questions
## about single cells: can an item pass, can it rest, is this a door, which
## zone tags are here. A cell is a Vector2i, x the column and y the row, with
## (0, 0) at the top-left character. It knows nothing about items; PackState
## records what is where.
class_name ContainerLayout
extends RefCounted

# Where to look
#   Made by:    core/packing/packing_scenario.gd -> layout()
#   Reads:      core/grid/layout_legend.gd -> entry_for()
#   Used by:    core/packing/pack_state.gd -> fits()
#               core/packing/access_solver.gd -> entry_lanes(), shift_range()
#               core/grid/layout_validator.gd -> problems(), warnings()
#   Tests:      tests/core/test_container_layout.gd

const OUTSIDE_SYMBOL: String = " "
const OVERLAY_BLANK_SYMBOLS: Array[String] = [".", " "]

var _size: Vector2i = Vector2i.ZERO
# Cells that hold a legend character. A cell missing from here is outside.
var _entries: Dictionary[Vector2i, LegendEntry] = {}
var _unknown_symbols: Dictionary[Vector2i, String] = {}
var _overlay_size: Vector2i = Vector2i.ZERO
var _overlay_entries: Dictionary[Vector2i, LegendEntry] = {}
var _overlay_unknown_symbols: Dictionary[Vector2i, String] = {}
var _outside_entry: LegendEntry = LegendEntry.new()
var _unknown_entry: LegendEntry = LegendEntry.new()


## Reads a layout text. The optional overlay is a second text of the same
## size: each of its characters other than '.' and space is looked up in the
## legend and that entry's tags are added to the cell beneath. An overlay
## changes nothing else about a cell.
static func parse(text: String, legend: LayoutLegend, overlay_text: String = "") -> ContainerLayout:
	var layout: ContainerLayout = ContainerLayout.new()
	layout._outside_entry.passable = true
	layout._read_cells(_lines_of(text), legend)
	layout._read_overlay(_lines_of(overlay_text), legend)
	return layout


## Columns and rows of the layout text.
func size() -> Vector2i:
	return _size


## True for a cell inside the layout's bounding rectangle.
func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < _size.x and cell.y < _size.y


## True when an item can come to rest on the cell.
func is_storable(cell: Vector2i) -> bool:
	return entry_at(cell).storable


## True for outside cells too: nothing stands in an item's way out there.
func is_passable(cell: Vector2i) -> bool:
	return entry_at(cell).passable


## A door is a cell of the layout that an item can pass but not rest on.
func is_door(cell: Vector2i) -> bool:
	if is_outside(cell):
		return false
	var entry: LegendEntry = entry_at(cell)
	return entry.passable and not entry.storable


## Outside is a space character, or anything beyond the edges of the text.
func is_outside(cell: Vector2i) -> bool:
	return not _entries.has(cell) and not _unknown_symbols.has(cell)


## The zone tags on a cell: its own, plus any that an overlay added.
func tags_at(cell: Vector2i) -> Array[StringName]:
	var tags: Array[StringName] = entry_at(cell).tags.duplicate()
	var marked: LegendEntry = overlay_entry_at(cell)
	if marked != null:
		for tag: StringName in marked.tags:
			if not tags.has(tag):
				tags.append(tag)
	return tags


## The legend entry for a cell. Outside and unknown cells get a stand-in.
func entry_at(cell: Vector2i) -> LegendEntry:
	if _entries.has(cell):
		return _entries[cell]
	if _unknown_symbols.has(cell):
		return _unknown_entry
	return _outside_entry


## The legend entry an overlay put on this cell, or null. Screens use it to
## draw a marked cell.
func overlay_entry_at(cell: Vector2i) -> LegendEntry:
	if _overlay_entries.has(cell):
		return _overlay_entries[cell]
	return null


## Every cell carrying a zone tag.
func cells_with_tag(tag: StringName) -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for cell: Vector2i in _all_cells():
		if tags_at(cell).has(tag):
			found.append(cell)
	return found


## Every cell where an item can rest.
func storable_cells() -> Array[Vector2i]:
	var found: Array[Vector2i] = []
	for cell: Vector2i in _all_cells():
		if is_storable(cell):
			found.append(cell)
	return found


## Layout cells whose character the legend does not list. Such a cell is
## treated as blocked. Read by LayoutValidator.
func unknown_symbols() -> Dictionary[Vector2i, String]:
	return _unknown_symbols


## Vector2i.ZERO when the layout was parsed without an overlay.
func overlay_size() -> Vector2i:
	return _overlay_size


## The cells an overlay marks.
func overlay_cells() -> Array[Vector2i]:
	return _overlay_entries.keys()


## Overlay characters the legend does not list, by cell. Read by LayoutValidator.
func overlay_unknown_symbols() -> Dictionary[Vector2i, String]:
	return _overlay_unknown_symbols


# Looks up every character of the layout text in the legend.
func _read_cells(lines: PackedStringArray, legend: LayoutLegend) -> void:
	_size = _size_of(lines)
	for row: int in lines.size():
		var line: String = lines[row]
		for column: int in line.length():
			var symbol: String = line[column]
			if symbol == OUTSIDE_SYMBOL:
				continue
			var cell: Vector2i = Vector2i(column, row)
			var entry: LegendEntry = legend.entry_for(symbol)
			if entry == null:
				_unknown_symbols[cell] = symbol
			else:
				_entries[cell] = entry


# Looks up every mark of the overlay text in the legend.
func _read_overlay(lines: PackedStringArray, legend: LayoutLegend) -> void:
	_overlay_size = _size_of(lines)
	for row: int in lines.size():
		var line: String = lines[row]
		for column: int in line.length():
			var symbol: String = line[column]
			if OVERLAY_BLANK_SYMBOLS.has(symbol):
				continue
			var cell: Vector2i = Vector2i(column, row)
			var entry: LegendEntry = legend.entry_for(symbol)
			if entry == null:
				_overlay_unknown_symbols[cell] = symbol
			else:
				_overlay_entries[cell] = entry


# Every cell of the bounding rectangle, row by row.
func _all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for row: int in _size.y:
		for column: int in _size.x:
			cells.append(Vector2i(column, row))
	return cells


# Splits a text into rows, dropping the empty lines an editor leaves before
# and after a multi-line field.
static func _lines_of(text: String) -> PackedStringArray:
	var lines: PackedStringArray = PackedStringArray()
	for raw_line: String in text.split("\n"):
		lines.append(raw_line.trim_suffix("\r"))
	while not lines.is_empty() and lines[lines.size() - 1].is_empty():
		lines.remove_at(lines.size() - 1)
	while not lines.is_empty() and lines[0].is_empty():
		lines.remove_at(0)
	return lines


# The longest line and the number of lines.
static func _size_of(lines: PackedStringArray) -> Vector2i:
	var width: int = 0
	for line: String in lines:
		width = maxi(width, line.length())
	return Vector2i(width, lines.size())
