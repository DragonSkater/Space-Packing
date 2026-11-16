## One ship in the overview's ship picker: a picture of its empty hull, its
## name and cargo spots, and how the launch's stack compares. A stack bigger
## than the hull is a warning, not a refusal: the player may still pick it
## and leave required cargo behind (PLAN.md D42). It only shows and reports.
class_name ShipRow
extends Button

# Where to look
#   Scene:      ui/overview/ship_row.tscn
#   Made by:    ui/overview/ship_picker.gd -> offer()
#   Shows:      game/ships/ship_type.gd, its hull in ui/common/grid_view.gd -> show_layout()
#   Compared:   game/launch/scheduled_launch.gd -> spare_spots_in()
#   Numbers:    ui/common/presentation_tuning.gd, the Touch and Colours groups
#   Tests:      tests/ui/test_ship_picker.gd

## The player tapped this ship.
signal chosen(ship: ShipType)

const TITLE_TEXT: String = "%s  (%d cargo spots)"
const MATCH_TEXT: String = "Same size as the stack: %d spots."
const TOO_SMALL_TEXT: String = "Too small: the stack needs %d spots and this hull has %d. Required cargo may be left behind."
const SPARE_TEXT: String = "Room to spare: %d of its %d spots stay empty."

var _ship: ShipType

@onready var _thumbnail: GridView = %Thumbnail
@onready var _title: Label = %Title
@onready var _status: Label = %Status


# A press reports which ship this row stands for.
func _ready() -> void:
	pressed.connect(_on_pressed)


## Fills the row. spare is the launch's spare_spots_in() for this ship.
func show_ship(ship: ShipType, spare: int, tuning: PresentationTuning) -> void:
	_ship = ship
	var spots: int = ship.cargo_spot_count()
	_thumbnail.show_layout(ship.layout(), tuning)
	_title.text = TITLE_TEXT % [ship.display_name, spots]
	custom_minimum_size.y = maxf(custom_minimum_size.y, tuning.min_touch_target)
	_status.modulate = Color.WHITE
	if spare == 0:
		_status.text = MATCH_TEXT % spots
		_status.modulate = tuning.door_lit_colour
	elif spare < 0:
		_status.text = TOO_SMALL_TEXT % [spots - spare, spots]
		_status.modulate = tuning.attention_colour
	else:
		_status.text = SPARE_TEXT % [spare, spots]


## The ship this row stands for.
func shown_ship() -> ShipType:
	return _ship


## The line under the ship's name, as the player reads it.
func status_text() -> String:
	return _status.text


# Reports the ship, whatever the warning says.
func _on_pressed() -> void:
	chosen.emit(_ship)
