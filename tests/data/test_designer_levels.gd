## Checks the designer's two levels and their craft, drawn from the sketches
## of 2026-11-17: R0-KET holds 21 spots and P0-INT 18, both load with no
## problems or warnings, each level's stack is the size and order the
## designer gave, and each can be packed whole within its moves.
extends TestCase

const R0_KET: String = "res://data/ships/r0_ket.tres"
const P0_INT: String = "res://data/ships/p0_int.tres"
const TUTORIAL: String = "res://data/launches/level_1_r0_ket_tutorial.tres"
const P0_INT_LEVEL: String = "res://data/launches/level_2_p0_int.tres"
const HUGE_BOX: String = "res://data/cargo/huge_box.tres"


func test_both_craft_load_cleanly_with_the_spots_the_sketches_give() -> void:
	for path: String in [R0_KET, P0_INT]:
		var ship: ShipType = load(path) as ShipType
		assert_eq(ship.problems(), [] as Array[String], path)
		assert_eq(ship.warnings(), [] as Array[String], path)
	assert_eq((load(R0_KET) as ShipType).cargo_spot_count(), 21, "3 by 7")
	assert_eq((load(P0_INT) as ShipType).cargo_spot_count(), 18, "3 rows of 4 and 3 rows of 2")


func test_the_huge_box_is_three_by_three() -> void:
	var huge_box: PackItemType = load(HUGE_BOX) as PackItemType
	assert_eq(huge_box.problems(), [] as Array[String])
	assert_true(huge_box.shape().matches(CellShape.from_text("XXX\nXXX\nXXX")))


func test_the_tutorial_stack_is_four_crates_two_beams_the_huge_box_and_two_crates() -> void:
	var launch: ScheduledLaunch = load(TUTORIAL) as ScheduledLaunch
	assert_eq(launch.problems(), [] as Array[String])
	assert_eq(_stack_ids(launch), [
		&"example_crate", &"example_crate", &"example_crate", &"example_crate",
		&"example_beam", &"example_beam", &"huge_box", &"example_crate", &"example_crate",
	] as Array[StringName])
	assert_eq(launch.move_limit, 16)
	assert_eq(launch.spare_spots_in(load(R0_KET) as ShipType), 2)


func test_the_p0_int_level_leaves_room_to_spare() -> void:
	var launch: ScheduledLaunch = load(P0_INT_LEVEL) as ScheduledLaunch
	assert_eq(launch.problems(), [] as Array[String])
	assert_eq(launch.cargo_spots_needed(), 17)
	assert_true(launch.spare_spots_in(load(P0_INT) as ShipType) > 0)


# Crates deep in rows 1 and 2, beams turned upright at the back of rows 6
# and 7, the Huge Box in rows 3 to 5, the last crates in front of the beams.
func test_the_tutorial_packs_whole_into_r0_ket_with_beams_turned_upright() -> void:
	var session: PackingSession = _start(TUTORIAL, R0_KET)
	for row: int in [1, 1, 1, 2]:
		_load_top(session, row, Vector2i.LEFT, 0)
	_load_top(session, 6, Vector2i.LEFT, 1)
	_load_top(session, 6, Vector2i.LEFT, 1)
	_load_top(session, 3, Vector2i.LEFT, 0)
	_load_top(session, 2, Vector2i.LEFT, 0)
	_load_top(session, 2, Vector2i.LEFT, 0)
	assert_eq(session.required_items_left(), 0)
	assert_true(session.moves_left() >= 0, "within 16 moves")


# Four crates along the bottom row, the fifth at the far left of the top
# wide row, the two L-shapes locked together beside it from the right (the
# second turned half round), and a beam flat in each narrow row.
func test_the_p0_int_level_packs_whole_into_p0_int() -> void:
	var session: PackingSession = _start(P0_INT_LEVEL, P0_INT)
	for row: int in [6, 6, 6, 6]:
		_load_top(session, row, Vector2i.LEFT, 0)
	_load_top(session, 4, Vector2i.RIGHT, 0)
	_load_top(session, 4, Vector2i.RIGHT, 0)
	_load_top(session, 4, Vector2i.RIGHT, 2)
	for row: int in [1, 2, 3]:
		_load_top(session, row, Vector2i.LEFT, 0)
	assert_eq(session.required_items_left(), 0)
	assert_true(session.moves_left() >= 0, "within 16 moves")


func _start(launch_path: String, ship_path: String) -> PackingSession:
	var launch: ScheduledLaunch = load(launch_path) as ScheduledLaunch
	return launch.round_in(load(ship_path) as ShipType).start(Tuning.packing)


# Takes the top piece, turns it clockwise on the crane, and slides it in
# from one side along the lane whose top row is given, as deep as it goes.
func _load_top(session: PackingSession, row: int, side: Vector2i, clockwise_turns: int) -> void:
	assert_true(session.pick_from_stack(0), "the top piece can be taken")
	for turn: int in clockwise_turns:
		assert_true(session.turn_held(true), "turned on the crane")
	for lane: EntryLane in session.entry_lanes():
		if lane.row == row and lane.side == side and not lane.stops.is_empty():
			assert_true(session.push_in(lane, lane.stops.size() - 1), "loaded at row %d" % row)
			return
	fail("%s could not enter row %d" % [session.held().type.display_name, row])
	session.put_back()


func _stack_ids(launch: ScheduledLaunch) -> Array[StringName]:
	var ids: Array[StringName] = []
	for batch: Batch in launch.manifest:
		for count: int in batch.count:
			ids.append(batch.item_type.id)
	return ids
