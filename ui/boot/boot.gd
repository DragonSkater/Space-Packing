## The first scene the game opens, and the one that moves the player round
## the loop: the overview, then packing the launch they chose, then the
## launch screen, then back to the overview with the ship on the map. It
## shows one screen at a time. It holds no rules of its own: GameState
## records the launch, and each screen only reports what was pressed.
extends Control

# Where to look
#   Scene:      ui/boot/boot.tscn, the project's main scene
#   Screens:    ui/overview/overview_screen.gd -> refresh()
#               ui/packing/packing_screen.gd -> open_scenario()
#               ui/reports/launch_screen.gd -> show_load()
#   Rounds:     game/launch/scheduled_launch.gd -> round_in()
#   Keeps:      game/app/game_state.gd -> record_launch()
#   Tests:      tests/ui/test_boot.gd

# The upcoming launch being packed, and its load once Done is pressed.
var _scheduled: ScheduledLaunch
var _round_name: String = ""
var _committed: CommitRecord

@onready var _overview: OverviewScreen = %OverviewScreen
@onready var _packing: PackingScreen = %PackingScreen
@onready var _launch: LaunchScreen = %LaunchScreen


# Joins the screens' signals and opens on the overview.
func _ready() -> void:
	_overview.launch_chosen.connect(_open_packing)
	_packing.overview_requested.connect(_show_overview)
	_packing.round_committed.connect(_open_launch)
	_launch.back_pressed.connect(_show_only.bind(_packing))
	_launch.launch_pressed.connect(_on_launch_pressed)
	_show_overview()


# The overview, brought up to date.
func _show_overview() -> void:
	_overview.refresh()
	_show_only(_overview)


# A fresh round of the chosen launch, in the chosen ship. ship is null
# when the launch brings its own hull.
func _open_packing(scheduled: ScheduledLaunch, ship: ShipType) -> void:
	for problem: String in scheduled.problems():
		push_error("%s: %s" % [scheduled.display_name, problem])
	var packing_round: PackingScenario = scheduled.round_in(ship)
	if packing_round == null:
		push_error("Boot: %s has no scenario and no ship to pack." % scheduled.display_name)
		return
	_scheduled = scheduled
	# Shown first: a hidden container is not laid out, and the round sizes
	# its grid from the space it is given.
	_show_only(_packing)
	_packing.open_scenario(packing_round)


# Done was pressed: show the load before it launches. The packing round is
# kept as it is, so Back returns to it with nothing lost.
func _open_launch(round_name: String, record: CommitRecord) -> void:
	_round_name = round_name
	_committed = record
	var destination: Body = null
	if _scheduled != null:
		destination = _scheduled.destination
	_show_only(_launch)
	_launch.show_load(round_name, record, destination)


# The launch button: the load becomes a launch, and the overview shows it.
func _on_launch_pressed() -> void:
	GameState.record_launch(_round_name, _committed, _scheduled)
	_show_overview()


# Shows one screen and hides the others.
func _show_only(screen: Control) -> void:
	for each: Control in [_overview, _packing, _launch]:
		each.visible = each == screen
