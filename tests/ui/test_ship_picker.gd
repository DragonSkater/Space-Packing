## Opens the overview and checks the ship picker: a launch that leaves the
## ship to the player opens it with a row per ship, the rows say whether the
## stack fits, any row can be picked, and Cancel closes it without choosing.
## A launch with its own hull skips the picker. It uses the running GameState.
extends TestCase

const SCREEN_PATH: String = "res://ui/overview/overview_screen.tscn"
const LARGE_LOAD: String = "res://data/launches/example_launch_04_full_hold.tres"
const SMALL_SHIP: String = "res://data/ships/example_ship_2.tres"


func test_a_launch_that_leaves_the_ship_to_the_player_opens_the_picker() -> void:
	var screen: OverviewScreen = _open_screen()
	var chosen: Array[Array] = _listen(screen)
	_tap_launch(screen, load(LARGE_LOAD) as ScheduledLaunch)
	var picker: ShipPicker = screen.get_node("%ShipPicker") as ShipPicker
	assert_true(picker.visible)
	assert_eq(picker.rows().size(), Catalog.ships().size(), "every ship with a hull is offered")
	assert_eq(chosen.size(), 0, "nothing is chosen until a ship is picked")
	screen.free()


func test_the_rows_say_whether_the_stack_fits() -> void:
	var screen: OverviewScreen = _open_screen()
	_tap_launch(screen, load(LARGE_LOAD) as ScheduledLaunch)
	var picker: ShipPicker = screen.get_node("%ShipPicker") as ShipPicker
	var small: ShipRow = _row_for(picker, load(SMALL_SHIP) as ShipType)
	assert_true(small.status_text().begins_with("Too small"), small.status_text())
	assert_true(small.status_text().contains("28"), "it names the spots the stack needs")
	assert_true(not small.disabled, "a ship that is too small can still be picked")
	screen.free()


func test_picking_a_ship_reports_the_launch_with_that_ship_and_closes_the_picker() -> void:
	var screen: OverviewScreen = _open_screen()
	var chosen: Array[Array] = _listen(screen)
	var launch: ScheduledLaunch = load(LARGE_LOAD) as ScheduledLaunch
	_tap_launch(screen, launch)
	var picker: ShipPicker = screen.get_node("%ShipPicker") as ShipPicker
	var small: ShipType = load(SMALL_SHIP) as ShipType
	_row_for(picker, small).pressed.emit()
	assert_eq(chosen.size(), 1)
	assert_true(chosen[0][0] == launch and chosen[0][1] == small, "the launch and the ship picked")
	assert_true(not picker.visible)
	screen.free()


func test_cancel_closes_the_picker_without_choosing() -> void:
	var screen: OverviewScreen = _open_screen()
	var chosen: Array[Array] = _listen(screen)
	_tap_launch(screen, load(LARGE_LOAD) as ScheduledLaunch)
	(screen.get_node("%CancelButton") as Button).pressed.emit()
	assert_true(not (screen.get_node("%ShipPicker") as ShipPicker).visible)
	assert_eq(chosen.size(), 0)
	screen.free()


func test_a_launch_with_its_own_hull_skips_the_picker() -> void:
	GameState.clear_launches()
	var screen: OverviewScreen = _open_screen()
	var chosen: Array[Array] = _listen(screen)
	var first: ScheduledLaunch = Catalog.scheduled_launches()[0]
	assert_true(first.scenario != null, "the first placeholder brings its own hull")
	_tap_launch(screen, first)
	assert_true(not (screen.get_node("%ShipPicker") as ShipPicker).visible)
	assert_eq(chosen.size(), 1)
	assert_true(chosen[0][0] == first and chosen[0][1] == null, "no ship is picked")
	screen.free()


# The screen has to be in the tree for its parts to find each other.
func _open_screen() -> OverviewScreen:
	var packed: PackedScene = load(SCREEN_PATH) as PackedScene
	var screen: OverviewScreen = packed.instantiate() as OverviewScreen
	scene_host.add_child(screen)
	return screen


# Each launch_chosen, as [launch, ship].
func _listen(screen: OverviewScreen) -> Array[Array]:
	var chosen: Array[Array] = []
	screen.launch_chosen.connect(func(scheduled: ScheduledLaunch, ship: ShipType) -> void: chosen.append([scheduled, ship]))
	return chosen


# Presses the upcoming row that stands for a launch.
func _tap_launch(screen: OverviewScreen, launch: ScheduledLaunch) -> void:
	for child: Node in screen.get_node("%UpcomingList").get_children():
		if child is UpcomingRow and not child.is_queued_for_deletion() and (child as UpcomingRow).shown_launch() == launch:
			(child as UpcomingRow).pressed.emit()
			return
	fail("no row for %s" % launch.display_name)


func _row_for(picker: ShipPicker, ship: ShipType) -> ShipRow:
	for row: ShipRow in picker.rows():
		if row.shown_ship() == ship:
			return row
	fail("no row for %s" % ship.display_name)
	return null
