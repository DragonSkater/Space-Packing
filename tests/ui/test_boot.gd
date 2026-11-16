## Walks once round the whole loop through the main scene, by pressing
## buttons: overview, pack the first launch, Done, Back to packing, Done,
## launch, and back on the overview with the ship recorded against the
## launch it flew. It uses the running GameState and clears it afterwards.
extends TestCase

const BOOT_PATH: String = "res://ui/boot/boot.tscn"


func test_the_loop_goes_overview_packing_launch_and_back() -> void:
	GameState.clear_launches()
	var boot: Control = (load(BOOT_PATH) as PackedScene).instantiate() as Control
	scene_host.add_child(boot)
	var overview: Control = boot.get_node("%OverviewScreen") as Control
	var packing: Control = boot.get_node("%PackingScreen") as Control
	var launch: Control = boot.get_node("%LaunchScreen") as Control
	assert_eq(_showing(boot), [overview] as Array[Control], "opens on the overview")

	var first: ScheduledLaunch = Catalog.scheduled_launches()[0]
	(overview as OverviewScreen).launch_chosen.emit(first)
	assert_eq(_showing(boot), [packing] as Array[Control], "choosing a launch opens packing")

	_press(packing, "%DoneButton")
	assert_eq(_showing(boot), [launch] as Array[Control], "Done opens the launch screen")
	_press(launch, "%BackButton")
	assert_eq(_showing(boot), [packing] as Array[Control], "Back returns to packing")
	_press(packing, "%DoneButton")
	_press(launch, "%LaunchButton")
	assert_eq(_showing(boot), [overview] as Array[Control], "launching returns to the overview")

	var launches: Array[LaunchRecord] = GameState.launches()
	assert_eq(launches.size(), 1, "one launch, though Done was pressed twice")
	assert_true(launches[0].scheduled == first, "recorded against the launch it flew")
	boot.free()
	GameState.clear_launches()


func test_the_overview_button_leaves_packing_without_launching() -> void:
	GameState.clear_launches()
	var boot: Control = (load(BOOT_PATH) as PackedScene).instantiate() as Control
	scene_host.add_child(boot)
	var overview: OverviewScreen = boot.get_node("%OverviewScreen") as OverviewScreen
	overview.launch_chosen.emit(Catalog.scheduled_launches()[0])
	_press(boot.get_node("%PackingScreen"), "%OverviewButton")
	assert_eq(_showing(boot), [overview as Control] as Array[Control])
	assert_eq(GameState.launches().size(), 0)
	boot.free()


# The screens that are visible.
func _showing(boot: Control) -> Array[Control]:
	var found: Array[Control] = []
	for screen_name: String in ["%OverviewScreen", "%PackingScreen", "%LaunchScreen"]:
		var screen: Control = boot.get_node(screen_name) as Control
		if screen.visible:
			found.append(screen)
	return found


func _press(owner_node: Node, button_name: String) -> void:
	(owner_node.get_node(button_name) as Button).pressed.emit()
