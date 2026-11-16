## One line in the overview's list of launched ships: a small picture of
## the hull exactly as it was packed, which launch it was, where it went,
## the moves it took, and whether required cargo was left behind. It shows
## what it is given and takes no input.
class_name LaunchedRow
extends PanelContainer

# Where to look
#   Scene:      ui/overview/launched_row.tscn
#   Made by:    ui/overview/overview_screen.gd -> _fill_launched()
#   Shows:      game/launch/launch_record.gd, its load in ui/common/fixed_cargo_view.gd -> show_record()
#   Tests:      tests/ui/test_overview_screen.gd

const TITLE_TEXT: String = "#%d  %s"
const DETAIL_TEXT: String = "To %s.  Moves %d of %d.  %d aboard, %d left on the stack."
const NO_DESTINATION: String = "nowhere yet"
const ARRIVED_TEXT: String = "Arrived with everything required."
const MISSED_TEXT: String = "Arrived, but %d required pieces were left behind."

@onready var _thumbnail: FixedCargoView = %Thumbnail
@onready var _title: Label = %Title
@onready var _detail: Label = %Detail
@onready var _status: Label = %Status


## Fills the row from one launch.
func show_record(record: LaunchRecord, tuning: PresentationTuning) -> void:
	var kept: CommitRecord = record.committed_load
	var place: String = NO_DESTINATION
	if record.destination() != null:
		place = record.destination().display_name
	_thumbnail.show_record(kept, tuning)
	_title.text = TITLE_TEXT % [record.number, record.round_name]
	_detail.text = DETAIL_TEXT % [place, kept.moves_used, kept.moves_allowed, kept.loaded.size(), kept.left_behind.size()]
	if record.missed_requirements():
		_status.text = MISSED_TEXT % kept.required_left
		_status.modulate = tuning.attention_colour
	else:
		_status.text = ARRIVED_TEXT
		_status.modulate = tuning.map_ship_colour
