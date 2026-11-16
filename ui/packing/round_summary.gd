## The plain panel shown when the player presses Done: the moves used, how
## many required pieces were left behind, which launch the load was kept
## as, and the buttons to go again. The
## launch screen replaces it in milestone 5. It only shows what it is given
## and reports which button was pressed.
class_name RoundSummary
extends Control

# Where to look
#   Scene:      ui/packing/round_summary.tscn
#   Shown by:   ui/packing/packing_screen.gd -> _on_finished()
#   Reads:      core/packing/commit_record.gd
#   Tests:      tests/ui/test_packing_screen.gd

signal restart_pressed
signal next_scenario_pressed

const MOVES_TEXT: String = "Moves used: %d of %d"
const LEFT_BEHIND_TEXT: String = "Required pieces left behind: %d"
const KEPT_TEXT: String = "Load kept as launch %d"

@onready var _moves_label: Label = %MovesUsed
@onready var _left_behind_label: Label = %LeftBehind
@onready var _kept_label: Label = %KeptAs
@onready var _restart_button: Button = %SummaryRestart
@onready var _next_button: Button = %NextScenario


# Passes the two button presses on as signals.
func _ready() -> void:
	_restart_button.pressed.connect(restart_pressed.emit)
	_next_button.pressed.connect(next_scenario_pressed.emit)


## Fills in the lines and shows the panel. kept_as is the launch number the
## load was kept as, or 0 to leave that line out. Called by
## PackingScreen._on_finished.
func show_result(record: CommitRecord, kept_as: int, tuning: PresentationTuning) -> void:
	_moves_label.text = MOVES_TEXT % [record.moves_used, record.moves_allowed]
	_left_behind_label.text = LEFT_BEHIND_TEXT % record.required_left
	_left_behind_label.visible = record.required_left > 0
	_kept_label.text = KEPT_TEXT % kept_as
	_kept_label.visible = kept_as > 0
	_restart_button.custom_minimum_size.y = tuning.min_touch_target
	_next_button.custom_minimum_size.y = tuning.min_touch_target
	show()
