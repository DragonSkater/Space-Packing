## Checks the example ships and the two example launches that leave the
## ship to the player: the ships load cleanly with 28 and 12 cargo spots,
## each launch's stack matches one of them, and each stack can be packed
## whole into its matching ship within its moves. It guards placeholder data.
extends TestCase

const LARGE_SHIP: String = "res://data/ships/example_ship_1.tres"
const SMALL_SHIP: String = "res://data/ships/example_ship_2.tres"
const LARGE_LOAD: String = "res://data/launches/example_launch_04_full_hold.tres"
const SMALL_LOAD: String = "res://data/launches/example_launch_05_small_load.tres"


func test_every_ship_loads_with_no_problems_or_warnings() -> void:
	assert_true(Catalog.ships().size() >= 2, "both example ships are in the catalog")
	for ship: ShipType in Catalog.ships():
		assert_eq(ship.problems(), [] as Array[String], ship.display_name)
		assert_eq(ship.warnings(), [] as Array[String], ship.display_name)


func test_the_example_ships_hold_28_and_12_spots() -> void:
	assert_eq(_ship(LARGE_SHIP).cargo_spot_count(), 28, "7 by 4")
	assert_eq(_ship(SMALL_SHIP).cargo_spot_count(), 12, "4 by 3")


func test_each_example_load_is_open_from_the_start_and_leaves_the_ship_to_the_player() -> void:
	for path: String in [LARGE_LOAD, SMALL_LOAD]:
		var launch: ScheduledLaunch = _launch(path)
		assert_eq(launch.problems(), [] as Array[String], path)
		assert_true(launch.chooses_ship(), path)
		assert_true(launch.requires == null, "%s is open from the start" % path)


func test_each_load_matches_one_ship_and_overflows_or_underfills_the_other() -> void:
	var large: ShipType = _ship(LARGE_SHIP)
	var small: ShipType = _ship(SMALL_SHIP)
	assert_eq(_launch(LARGE_LOAD).spare_spots_in(large), 0)
	assert_true(_launch(LARGE_LOAD).spare_spots_in(small) < 0, "the full hold is too big for ship 2")
	assert_eq(_launch(SMALL_LOAD).spare_spots_in(small), 0)
	assert_true(_launch(SMALL_LOAD).spare_spots_in(large) > 0, "the small load leaves room in ship 1")


func test_the_full_hold_packs_whole_into_ship_1() -> void:
	var session: PackingSession = _launch(LARGE_LOAD).round_in(_ship(LARGE_SHIP)).start(Tuning.packing)
	_load_everything_as_deep_as_it_goes(session)
	assert_eq(session.required_items_left(), 0)
	assert_eq(session.stack().size(), 0)


func test_the_small_load_packs_whole_into_ship_2() -> void:
	var session: PackingSession = _launch(SMALL_LOAD).round_in(_ship(SMALL_SHIP)).start(Tuning.packing)
	_load_everything_as_deep_as_it_goes(session)
	assert_eq(session.required_items_left(), 0)
	assert_eq(session.stack().size(), 0)


# Takes each piece from the top and leaves it at the deepest stop on offer,
# the first such lane winning a tie. Stops when a piece will not go in.
func _load_everything_as_deep_as_it_goes(session: PackingSession) -> void:
	while not session.stack().is_empty():
		if not session.pick_from_stack(0):
			fail("could not take the top piece")
			return
		var best_lane: EntryLane = null
		var best_depth: int = -1
		for lane: EntryLane in session.entry_lanes():
			if lane.stops.is_empty():
				continue
			var depth: int = absi(lane.stops.back().x - lane.hold_origin.x)
			if depth > best_depth:
				best_depth = depth
				best_lane = lane
		if best_lane == null or not session.push_in(best_lane, best_lane.stops.size() - 1):
			fail("%s did not go in; %d pieces left" % [session.held().type.display_name, session.stack().size()])
			return


func _ship(path: String) -> ShipType:
	return load(path) as ShipType


func _launch(path: String) -> ScheduledLaunch:
	return load(path) as ScheduledLaunch
