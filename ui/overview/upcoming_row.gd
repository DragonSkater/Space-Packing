## One line in the overview's list of upcoming launches: its name, where
## it goes, and whether it can be flown. Tapping an open one reports it as
## chosen, and says so when the player will pick the ship. Whether it is
## open is decided by GameState and handed in; this row only shows it.
class_name UpcomingRow
extends Button

# Where to look
#   Scene:      ui/overview/upcoming_row.tscn
#   Made by:    ui/overview/overview_screen.gd -> _fill_upcoming()
#   Shows:      game/launch/scheduled_launch.gd -> chooses_ship(), cargo_spots_needed()
#   Open from:  game/app/game_state.gd -> is_open(), is_fulfilled(), times_flown()
#   Tests:      tests/ui/test_overview_screen.gd

## The player tapped this launch to pack it.
signal chosen(scheduled: ScheduledLaunch)

const TITLE_TEXT: String = "%s  to %s"
const NO_DESTINATION: String = "nowhere yet"
const NEXT_TEXT: String = "Next. Tap to pack it."
const FLOWN_TEXT: String = "Flown %s. Tap to fly it again."
const MISSED_TEXT: String = "Flown %s, required cargo missed. Tap to try again."
const ONCE_TEXT: String = "once"
const TIMES_TEXT: String = "%d times"
const WAITING_TEXT: String = "Waiting: fly %s first, with everything required."
const PICK_SHIP_TEXT: String = " %d spots of cargo; pick a ship."

var _scheduled: ScheduledLaunch

@onready var _title: Label = %Title
@onready var _status: Label = %Status


# A press reports which launch this row stands for.
func _ready() -> void:
	pressed.connect(_on_pressed)


## Fills the row. open, fulfilled and times_flown come from GameState.
func show_launch(scheduled: ScheduledLaunch, open: bool, fulfilled: bool, times_flown: int, tuning: PresentationTuning) -> void:
	_scheduled = scheduled
	var place: String = NO_DESTINATION
	if scheduled.destination != null:
		place = scheduled.destination.display_name
	_title.text = TITLE_TEXT % [scheduled.display_name, place]
	custom_minimum_size.y = tuning.min_touch_target
	disabled = not open
	_status.modulate = Color.WHITE
	if not open:
		_status.text = WAITING_TEXT % scheduled.requires.display_name
	elif times_flown == 0:
		_status.text = NEXT_TEXT
		_status.modulate = tuning.door_lit_colour
	elif fulfilled:
		_status.text = FLOWN_TEXT % _how_often(times_flown)
	else:
		_status.text = MISSED_TEXT % _how_often(times_flown)
		_status.modulate = tuning.attention_colour
	if open and scheduled.chooses_ship():
		_status.text += PICK_SHIP_TEXT % scheduled.cargo_spots_needed()


## The launch this row stands for.
func shown_launch() -> ScheduledLaunch:
	return _scheduled


# "once", or "3 times".
func _how_often(times_flown: int) -> String:
	if times_flown == 1:
		return ONCE_TEXT
	return TIMES_TEXT % times_flown


# Only an open row can be pressed; a disabled button sends nothing.
func _on_pressed() -> void:
	chosen.emit(_scheduled)
