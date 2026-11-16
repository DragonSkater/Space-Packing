## Opens the overview and checks it: the controls are listed; there is one
## row per upcoming launch, only the first open at the start; and after a
## launch there is a row for the launched ship with its packed hull, and the
## next launch is open. It uses the running GameState and clears it afterwards.
extends TestCase

const SCREEN_PATH: String = "res://ui/overview/overview_screen.tscn"


func test_at_the_start_nothing_is_launched_and_only_the_first_launch_is_open() -> void:
	GameState.clear_launches()
	var screen: OverviewScreen = _open_screen()
	var rows: Array[UpcomingRow] = _upcoming_rows(screen)
	assert_eq(rows.size(), Catalog.scheduled_launches().size())
	assert_true(not rows[0].disabled, "the first is open")
	assert_true(rows[1].disabled, "the second waits for the first")
	assert_eq(_launched_rows(screen).size(), 0)
	assert_true((screen.get_node("%NoLaunches") as Label).visible)
	screen.free()


func test_the_controls_are_listed_from_the_start() -> void:
	GameState.clear_launches()
	var screen: OverviewScreen = _open_screen()
	var controls: Label = screen.get_node("%Controls") as Label
	assert_true(controls.visible, "the list is shown before anything is launched")
	assert_true(controls.text.contains("Swipe up or down"), "turning is one of the controls listed")
	screen.free()


func test_a_launch_adds_a_row_and_opens_the_next() -> void:
	GameState.clear_launches()
	var screen: OverviewScreen = _open_screen()
	var first: ScheduledLaunch = Catalog.scheduled_launches()[0]
	GameState.record_launch("A round", _fully_loaded(), first)
	var launched: Array[LaunchedRow] = _launched_rows(screen)
	assert_eq(launched.size(), 1, "redrawn when the launch was recorded")
	var thumbnail: FixedCargoView = launched[0].get_node("%Thumbnail") as FixedCargoView
	assert_true(thumbnail.shown_record() != null, "the row shows how the ship was packed")
	assert_true(not _upcoming_rows(screen)[1].disabled, "the second is open now")
	assert_true(not (screen.get_node("%NoLaunches") as Label).visible)
	screen.free()
	GameState.clear_launches()


func test_tapping_an_open_launch_reports_it() -> void:
	GameState.clear_launches()
	var screen: OverviewScreen = _open_screen()
	var chosen: Array[ScheduledLaunch] = []
	screen.launch_chosen.connect(chosen.append)
	_upcoming_rows(screen)[0].pressed.emit()
	assert_eq(chosen.size(), 1)
	assert_true(chosen[0] == Catalog.scheduled_launches()[0])
	screen.free()


# The screen has to be in the tree for its parts to find each other.
func _open_screen() -> OverviewScreen:
	var packed: PackedScene = load(SCREEN_PATH) as PackedScene
	var screen: OverviewScreen = packed.instantiate() as OverviewScreen
	scene_host.add_child(screen)
	return screen


# Rows being freed by a redraw are left out.
func _upcoming_rows(screen: OverviewScreen) -> Array[UpcomingRow]:
	var found: Array[UpcomingRow] = []
	for child: Node in screen.get_node("%UpcomingList").get_children():
		if child is UpcomingRow and not child.is_queued_for_deletion():
			found.append(child)
	return found


func _launched_rows(screen: OverviewScreen) -> Array[LaunchedRow]:
	var found: Array[LaunchedRow] = []
	for child: Node in screen.get_node("%LaunchedList").get_children():
		if child is LaunchedRow and not child.is_queued_for_deletion():
			found.append(child)
	return found


# A tiny round with its one required item loaded, so nothing is missed.
func _fully_loaded() -> CommitRecord:
	var manifest: Array[Batch] = [CoreFixtures.batch(CoreFixtures.item_type("X"), 1)]
	var session: PackingSession = CoreFixtures.session(["#####", "D...#", "#####"] as Array[String], manifest)
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[0], 0)
	session.commit()
	return session.commit_record()
