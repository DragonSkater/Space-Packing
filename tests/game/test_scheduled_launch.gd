## Tests ScheduledLaunch's ship choice with content built in code: who picks
## the ship, which ships may fly it, the round it builds, and how its cargo
## compares with a hull. Whether a round can be won is not judged here.
extends TestCase


func test_a_launch_with_no_scenario_and_no_named_ship_leaves_the_choice_to_the_player() -> void:
	var launch: ScheduledLaunch = _launch(4)
	assert_true(launch.chooses_ship())
	assert_true(launch.can_fly_in(_ship(2, 2)))
	assert_true(not launch.can_fly_in(ShipType.new()), "a craft with no hull cannot be packed")


func test_the_round_is_the_launch_cargo_in_the_chosen_hull() -> void:
	var launch: ScheduledLaunch = _launch(4)
	var ship: ShipType = _ship(3, 2)
	var built: PackingScenario = launch.round_in(ship)
	assert_eq(built.layout_text, ship.hull_layout_text)
	assert_true(built.legend == ship.legend)
	assert_true(built.manifest == launch.manifest)
	assert_eq(built.move_limit, launch.move_limit)
	assert_true(built.display_name.contains(ship.display_name), built.display_name)
	assert_eq(built.problems(), [] as Array[String])


func test_a_named_ship_is_flown_whatever_was_chosen() -> void:
	var launch: ScheduledLaunch = _launch(4)
	var named: ShipType = _ship(2, 2)
	launch.ship = named
	assert_true(not launch.chooses_ship())
	assert_true(not launch.can_fly_in(_ship(3, 3)), "only the named ship (PLAN.md D43)")
	assert_eq(launch.round_in(null).layout_text, named.hull_layout_text)


func test_a_ready_made_scenario_is_played_as_it_is() -> void:
	var launch: ScheduledLaunch = _launch(4)
	launch.scenario = PackingScenario.new()
	assert_true(not launch.chooses_ship())
	assert_true(launch.round_in(_ship(2, 2)) == launch.scenario)
	assert_true(not launch.can_fly_in(_ship(2, 2)))


func test_no_ship_means_no_round() -> void:
	assert_true(_launch(4).round_in(null) == null)


func test_spare_spots_compare_the_whole_stack_with_the_hull() -> void:
	var launch: ScheduledLaunch = _launch(3)
	launch.manifest.append(CoreFixtures.batch(CoreFixtures.item_type("XX\nXX"), 1, false))
	assert_eq(launch.cargo_spots_needed(), 7, "three single spots and an optional block")
	assert_eq(launch.spare_spots_in(_ship(7, 1)), 0)
	assert_eq(launch.spare_spots_in(_ship(2, 2)), -3, "too small")
	assert_eq(launch.spare_spots_in(_ship(4, 3)), 5, "room to spare")


func test_designated_spots_need_a_named_ship() -> void:
	var launch: ScheduledLaunch = _launch(1)
	launch.designation_text = "..G."
	assert_true(not launch.problems().is_empty())
	launch.ship = _ship(2, 1)
	assert_eq(launch.problems(), [] as Array[String])


# A launch whose stack is count single-spot pieces.
func _launch(count: int) -> ScheduledLaunch:
	var launch: ScheduledLaunch = ScheduledLaunch.new()
	launch.display_name = "Test launch"
	launch.manifest = [CoreFixtures.batch(CoreFixtures.item_type("X"), count)] as Array[Batch]
	launch.move_limit = 9
	return launch


# A ship whose hold is columns by rows spots, with a door on each row.
func _ship(columns: int, rows: int) -> ShipType:
	var lines: Array[String] = ["#".repeat(columns + 2)]
	for row: int in rows:
		lines.append("D" + ".".repeat(columns) + "#")
	lines.append("#".repeat(columns + 2))
	var ship: ShipType = ShipType.new()
	ship.display_name = "Ship %d by %d" % [columns, rows]
	ship.hull_layout_text = "\n".join(lines)
	ship.legend = CoreFixtures.legend()
	return ship
