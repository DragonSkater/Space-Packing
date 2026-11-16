## The launch screen, with the parts of screens/routing-screen.png stacked
## upright: the packed ship as it will launch (FIXED CARGO), CHECKS and
## TIME, the APPROVAL panel, the star chart and the round launch button. It
## only shows the load it is given and reports Back and Launch; whoever
## opened it records the launch. The bill fills APPROVAL in milestone 5.
class_name LaunchScreen
extends Control

# Where to look
#   Scene:      ui/reports/launch_screen.tscn
#   Opened by:  ui/boot/boot.gd -> _open_launch()
#   Shows:      core/packing/commit_record.gd, in ui/common/fixed_cargo_view.gd -> show_record()
#   Its parts:  ui/reports/star_chart.gd, ui/reports/launch_button.gd
#   Numbers:    ui/common/presentation_tuning.gd, the Launch screen and Screen margins groups
#   Tests:      tests/ui/test_launch_screen.gd

## The player wants to go back to packing. The round is as they left it.
signal back_pressed
## The launch button was pressed.
signal launch_pressed

const HEADING_TEXT: String = "%s to %s"
const NO_DESTINATION: String = "no destination"
const ALL_ABOARD_TEXT: String = "OK   All required cargo is aboard"
const LEFT_BEHIND_TEXT: String = "MISSED   %d required pieces left behind. The ship still flies, but this will not count."
const MOVES_TEXT: String = "Moves used: %d of %d"
const TRAVEL_TEXT: String = "Travel: arrives at once until travel time is built (milestone 6)"
const ABOARD_TEXT: String = "Aboard: %d pieces, %s t.   On the stack: %d."
const BILL_TEXT: String = "The report card and invoice arrive with milestones 4 and 5."

@onready var _margins: MarginContainer = %Margins
@onready var _heading: Label = %Heading
@onready var _cargo_view: FixedCargoView = %FixedCargo
@onready var _checks_line: Label = %ChecksLine
@onready var _moves_line: Label = %MovesLine
@onready var _travel_line: Label = %TravelLine
@onready var _aboard_line: Label = %AboardLine
@onready var _bill_line: Label = %BillLine
@onready var _launch_button: LaunchButton = %LaunchButton
@onready var _back_button: Button = %BackButton


# Applies the margins and passes the two buttons on as signals.
func _ready() -> void:
	var tuning: PresentationTuning = PresentationTuning.current()
	_margins.add_theme_constant_override("margin_top", roundi(tuning.margin_top))
	_margins.add_theme_constant_override("margin_bottom", roundi(tuning.margin_bottom))
	_margins.add_theme_constant_override("margin_left", roundi(tuning.edge_guard))
	_margins.add_theme_constant_override("margin_right", roundi(tuning.edge_guard))
	_back_button.custom_minimum_size.y = tuning.min_touch_target
	_back_button.pressed.connect(back_pressed.emit)
	_launch_button.pressed.connect(launch_pressed.emit)


## Shows a committed load before launch. destination may be null for a
## round played outside the schedule.
func show_load(round_name: String, record: CommitRecord, destination: Body) -> void:
	var tuning: PresentationTuning = PresentationTuning.current()
	var place: String = NO_DESTINATION
	if destination != null:
		place = destination.display_name
	_heading.text = HEADING_TEXT % [round_name, place]
	_cargo_view.show_record(record, tuning)
	_launch_button.apply_tuning(tuning)
	_show_checks(record, tuning)
	_moves_line.text = MOVES_TEXT % [record.moves_used, record.moves_allowed]
	_travel_line.text = TRAVEL_TEXT
	_aboard_line.text = ABOARD_TEXT % [record.loaded.size(), String.num(record.loaded_weight(), 1), record.left_behind.size()]
	_bill_line.text = BILL_TEXT


# The one check that exists before rules arrive (milestone 4): required
# cargo left behind, which PLAN.md section 3.5 says is printed first.
func _show_checks(record: CommitRecord, tuning: PresentationTuning) -> void:
	if record.required_left > 0:
		_checks_line.text = LEFT_BEHIND_TEXT % record.required_left
		_checks_line.modulate = tuning.attention_colour
	else:
		_checks_line.text = ALL_ABOARD_TEXT
		_checks_line.modulate = Color.WHITE
