## The panel the overview opens when a launch leaves the choice of ship to
## the player: how many cargo spots the stack needs, then one row per ship
## that can fly it. Every ship can be picked; a mismatch is only flagged.
## It reports the choice or a cancel and changes no game state.
class_name ShipPicker
extends Control

# Where to look
#   Scene:      part of ui/overview/overview_screen.tscn
#   Opened by:  ui/overview/overview_screen.gd -> _on_upcoming_chosen()
#   Its rows:   ui/overview/ship_row.gd -> show_ship()
#   Reads:      game/launch/scheduled_launch.gd -> cargo_spots_needed(), spare_spots_in()
#   Tests:      tests/ui/test_ship_picker.gd

## The player picked a ship for the launch.
signal ship_chosen(scheduled: ScheduledLaunch, ship: ShipType)
## The player closed the panel without picking.
signal cancelled

const SHIP_ROW: PackedScene = preload("res://ui/overview/ship_row.tscn")
const NEED_TEXT: String = "The cargo for %s covers %d spots. Pick the ship to pack it in."

var _scheduled: ScheduledLaunch

@onready var _need: Label = %Need
@onready var _ship_list: VBoxContainer = %ShipList
@onready var _no_ships: Label = %NoShips
@onready var _cancel: Button = %CancelButton


# Joins the cancel button. The panel starts closed.
func _ready() -> void:
	_cancel.pressed.connect(_on_cancel_pressed)
	visible = false


## Opens the panel for one launch, offering the given ships in order.
func offer(scheduled: ScheduledLaunch, ships: Array[ShipType], tuning: PresentationTuning) -> void:
	_scheduled = scheduled
	_need.text = NEED_TEXT % [scheduled.display_name, scheduled.cargo_spots_needed()]
	_clear_rows()
	_no_ships.visible = ships.is_empty()
	for ship: ShipType in ships:
		var row: ShipRow = SHIP_ROW.instantiate() as ShipRow
		_ship_list.add_child(row)
		row.show_ship(ship, scheduled.spare_spots_in(ship), tuning)
		row.chosen.connect(_on_row_chosen)
	visible = true


## Closes the panel.
func close() -> void:
	visible = false
	_scheduled = null


## The launch the panel is open for, or null when it is closed.
func offered_launch() -> ScheduledLaunch:
	return _scheduled


## The rows showing now, in order.
func rows() -> Array[ShipRow]:
	var found: Array[ShipRow] = []
	for child: Node in _ship_list.get_children():
		if child is ShipRow and not child.is_queued_for_deletion():
			found.append(child)
	return found


# A row was tapped: report it with the launch it was offered for.
func _on_row_chosen(ship: ShipType) -> void:
	ship_chosen.emit(_scheduled, ship)


# Cancel reports itself; whoever opened the panel closes it.
func _on_cancel_pressed() -> void:
	cancelled.emit()


# Rows are rebuilt each time the panel opens; there are only a handful.
func _clear_rows() -> void:
	for child: Node in _ship_list.get_children():
		_ship_list.remove_child(child)
		child.queue_free()
