## Opens the launch screen with a committed load and checks that it shows
## what it was given (the destination, the fixed cargo, the required-cargo
## check, the moves) and that Back and the launch button are reported. It
## cannot judge how the star chart or the round button look.
extends TestCase

const SCREEN_PATH: String = "res://ui/reports/launch_screen.tscn"


func test_it_shows_the_load_and_where_it_is_going() -> void:
	var screen: LaunchScreen = _open_screen()
	var scheduled: ScheduledLaunch = Catalog.scheduled_launches()[0]
	var record: CommitRecord = _committed(scheduled.scenario)
	screen.show_load("A round", record, scheduled.destination)
	var heading: String = (screen.get_node("%Heading") as Label).text
	assert_true(heading.contains(scheduled.destination.display_name), "the heading names the destination")
	assert_true((screen.get_node("%FixedCargo") as FixedCargoView).shown_record() == record, "the fixed cargo is the load")
	assert_true((screen.get_node("%ChecksLine") as Label).text.begins_with("MISSED"), "nothing was loaded")
	assert_eq((screen.get_node("%MovesLine") as Label).text, "Moves used: 0 of %d" % record.moves_allowed)
	screen.free()


func test_back_and_launch_are_reported() -> void:
	var screen: LaunchScreen = _open_screen()
	var heard: Array[String] = []
	screen.back_pressed.connect(heard.append.bind("back"))
	screen.launch_pressed.connect(heard.append.bind("launch"))
	screen.show_load("A round", _committed(Catalog.scenarios()[0]), null)
	(screen.get_node("%BackButton") as Button).pressed.emit()
	(screen.get_node("%LaunchButton") as Button).pressed.emit()
	assert_eq(heard, ["back", "launch"] as Array[String])
	assert_true(not (screen.get_node("%LaunchButton") as Button).disabled, "never disabled")
	screen.free()


# The screen has to be in the tree for its parts to find each other.
func _open_screen() -> LaunchScreen:
	var packed: PackedScene = load(SCREEN_PATH) as PackedScene
	var screen: LaunchScreen = packed.instantiate() as LaunchScreen
	scene_host.add_child(screen)
	return screen


# A round of the scenario committed before anything was loaded.
func _committed(scenario: PackingScenario) -> CommitRecord:
	var session: PackingSession = scenario.start(Tuning.packing)
	session.commit()
	return session.commit_record()
