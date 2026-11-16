## The overview, which is also the contract screen (PLAN.md section 2): the
## map with the launched ships on it, a list of launched ships, each with a
## picture of how it was packed, and the upcoming launches, which are
## placeholders until the contracts of milestone 6. A launch that leaves the
## ship to the player opens the ship picker first. It reads GameState and
## Catalog; choosing only reports, and whoever opened the screen starts it.
class_name OverviewScreen
extends Control

# Where to look
#   Scene:      ui/overview/overview_screen.tscn
#   Opened by:  ui/boot/boot.gd -> _show_overview()
#   Reads:      game/app/game_state.gd -> launches(), is_open(), is_fulfilled(), times_flown()
#               game/app/catalog.gd -> space_maps(), scheduled_launches(), ships()
#   Its parts:  ui/overview/space_map_view.gd, ui/overview/launched_row.gd, ui/overview/upcoming_row.gd,
#               ui/overview/ship_picker.gd -> offer()
#   Numbers:    ui/common/presentation_tuning.gd, the Overview and Screen margins groups
#   Tests:      tests/ui/test_overview_screen.gd, tests/ui/test_ship_picker.gd

## The player chose an upcoming launch to pack, and the ship to pack it in.
## ship is null when the launch brings its own hull (a ready-made scenario).
signal launch_chosen(scheduled: ScheduledLaunch, ship: ShipType)

const LAUNCHED_ROW: PackedScene = preload("res://ui/overview/launched_row.tscn")
const UPCOMING_ROW: PackedScene = preload("res://ui/overview/upcoming_row.tscn")
const COUNT_TEXT: String = "Launches so far: %d"

@onready var _margins: MarginContainer = %Margins
@onready var _count: Label = %Count
@onready var _map_view: SpaceMapView = %MapView
@onready var _launched_list: VBoxContainer = %LaunchedList
@onready var _no_launches: Label = %NoLaunches
@onready var _upcoming_list: VBoxContainer = %UpcomingList
@onready var _nothing_scheduled: Label = %NothingScheduled
@onready var _ship_picker: ShipPicker = %ShipPicker


# Applies the margins, and redraws whenever a launch is recorded.
func _ready() -> void:
	var tuning: PresentationTuning = PresentationTuning.current()
	_margins.add_theme_constant_override("margin_top", roundi(tuning.margin_top))
	_margins.add_theme_constant_override("margin_bottom", roundi(tuning.margin_bottom))
	_margins.add_theme_constant_override("margin_left", roundi(tuning.edge_guard))
	_margins.add_theme_constant_override("margin_right", roundi(tuning.edge_guard))
	GameState.launch_recorded.connect(_on_launch_recorded)
	_ship_picker.ship_chosen.connect(_on_ship_chosen)
	_ship_picker.cancelled.connect(_ship_picker.close)
	_redraw()


## Brings everything on the screen up to date. Called by Boot each time the
## overview is shown. A ship picker left open is closed.
func refresh() -> void:
	_ship_picker.close()
	_redraw()


# A launch was recorded while the screen was hidden or showing.
func _on_launch_recorded(_record: LaunchRecord) -> void:
	_redraw()


# The map, then both lists, from what GameState and Catalog hold now.
func _redraw() -> void:
	var tuning: PresentationTuning = PresentationTuning.current()
	var launches: Array[LaunchRecord] = GameState.launches()
	var maps: Array[SpaceMap] = Catalog.space_maps()
	var map: SpaceMap = null
	if not maps.is_empty():
		map = maps[0]
		for problem: String in map.problems():
			push_error("%s: %s" % [map.display_name, problem])
	_map_view.show_map(map, launches, tuning)
	_count.text = COUNT_TEXT % launches.size()
	_fill_launched(launches, tuning)
	_fill_upcoming(tuning)


# Newest first, so the ship just launched is at the top.
func _fill_launched(launches: Array[LaunchRecord], tuning: PresentationTuning) -> void:
	_clear(_launched_list)
	_no_launches.visible = launches.is_empty()
	for index: int in range(launches.size() - 1, -1, -1):
		var row: LaunchedRow = LAUNCHED_ROW.instantiate() as LaunchedRow
		_launched_list.add_child(row)
		row.show_record(launches[index], tuning)


# In file-name order, each with what GameState says about it.
func _fill_upcoming(tuning: PresentationTuning) -> void:
	_clear(_upcoming_list)
	var scheduled_launches: Array[ScheduledLaunch] = Catalog.scheduled_launches()
	_nothing_scheduled.visible = scheduled_launches.is_empty()
	for scheduled: ScheduledLaunch in scheduled_launches:
		var row: UpcomingRow = UPCOMING_ROW.instantiate() as UpcomingRow
		_upcoming_list.add_child(row)
		var open: bool = GameState.is_open(scheduled)
		row.show_launch(scheduled, open, GameState.is_fulfilled(scheduled), GameState.times_flown(scheduled), tuning)
		row.chosen.connect(_on_upcoming_chosen)


# A launch was tapped. When the player picks the ship, the picker opens
# with every ship that can fly it; otherwise the launch goes straight on.
func _on_upcoming_chosen(scheduled: ScheduledLaunch) -> void:
	if not scheduled.chooses_ship():
		launch_chosen.emit(scheduled, scheduled.ship)
		return
	var offered: Array[ShipType] = []
	for ship: ShipType in Catalog.ships():
		if scheduled.can_fly_in(ship):
			offered.append(ship)
	_ship_picker.offer(scheduled, offered, PresentationTuning.current())


# A ship was picked in the picker: the launch goes on in it.
func _on_ship_chosen(scheduled: ScheduledLaunch, ship: ShipType) -> void:
	_ship_picker.close()
	launch_chosen.emit(scheduled, ship)


# Rows are rebuilt on every redraw; there are only a handful.
func _clear(list: Container) -> void:
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
