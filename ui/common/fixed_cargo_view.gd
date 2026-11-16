## Draws a container exactly as a round left it: the grid, and every piece
## inside it where it was committed, turned as it was. It is read-only and
## takes no input. The launch screen shows it full size as FIXED CARGO; the
## overview shows it small, as the thumbnail of a launched ship.
class_name FixedCargoView
extends GridView

# Where to look
#   Shown by:   ui/reports/launch_screen.gd -> show_load()
#               ui/overview/launched_row.gd -> show_record()
#   Draws:      core/packing/commit_record.gd, through ui/common/item_painter.gd -> draw_piece()
#   Grid from:  ui/common/grid_view.gd -> _draw()
#   Numbers:    ui/common/presentation_tuning.gd, the Spots group
#   Tests:      tests/ui/test_launch_screen.gd

var _record: CommitRecord


## Shows a committed load. The spot size fits the space this control has.
func show_record(record: CommitRecord, tuning: PresentationTuning) -> void:
	_record = record
	show_layout(record.layout, tuning)


## The load being shown, or null.
func shown_record() -> CommitRecord:
	return _record


# The grid first, then each piece where it was left.
func _draw() -> void:
	super()
	if _record == null:
		return
	var spot: float = spot_size()
	for item: CommittedItem in _record.loaded:
		var corner: Vector2 = point_of(Vector2(item.origin))
		# _tuning is GridView's, set by show_layout().
		ItemPainter.draw_piece(self, item.type, item.shape, item.quarter_turns, corner, spot, _tuning)
