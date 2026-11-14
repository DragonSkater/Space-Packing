## Tests for AccessSolver. Each test name is a statement about the loading
## rule or the turning rule (PLAN.md sections 3.3 and 3.4), and each layout
## is drawn in the test: '#' wall, '.' storable cell, 'D' door, '|' bulkhead.
## Moves and the stack are not tested here; see test_packing_session.gd.
extends TestCase

const ONE_ROW: Array[String] = [
	"######",
	"D....#",
	"######",
]
const TWO_ROWS: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"######",
]
const TWO_DOORS_AND_A_ROW_WITHOUT: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"#....#",
	"######",
]
const SINGLE: String = "X"
const FLAT_PAIR: String = "XX"
const UPRIGHT_PAIR: String = "X\nX"
const L_SHAPE: String = "X.\nXX"


# --- Entering -------------------------------------------------------------

func test_a_single_cell_item_can_stop_on_every_cell_of_an_empty_row_nearest_the_door_first() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(SINGLE))
	assert_eq(lanes.size(), 1, "one door, one lane")
	assert_eq(lanes[0].stops, [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(4, 1)] as Array[Vector2i])
	assert_eq(lanes[0].side, Vector2i.LEFT)
	assert_eq(lanes[0].door_cells, [Vector2i(0, 1)] as Array[Vector2i])
	assert_eq(lanes[0].hold_origin, Vector2i(-1, 1), "the loader holds it just outside the door")


func test_the_stops_end_in_front_of_an_item_at_the_far_wall() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	CoreFixtures.put(state, SINGLE, Vector2i(4, 1))
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(SINGLE))
	assert_eq(lanes[0].stops, [Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)] as Array[Vector2i])


func test_an_item_cannot_be_pushed_past_an_item_stopped_short() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	CoreFixtures.put(state, SINGLE, Vector2i(2, 1))
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(SINGLE))
	assert_eq(lanes[0].stops, [Vector2i(1, 1)] as Array[Vector2i], "the gap behind it is out of reach")


func test_a_full_row_offers_no_lane() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	CoreFixtures.put(state, FLAT_PAIR, Vector2i(1, 1))
	CoreFixtures.put(state, FLAT_PAIR, Vector2i(3, 1))
	assert_eq(AccessSolver.entry_lanes(state, CellShape.from_text(SINGLE)).size(), 0)


func test_a_row_split_by_a_bulkhead_offers_one_lane_from_each_side() -> void:
	var state: PackState = CoreFixtures.state([
		"#######",
		"D..|..D",
		"#######",
	])
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(SINGLE))
	assert_eq(lanes.size(), 2)
	assert_eq(lanes[0].side, Vector2i.LEFT)
	assert_eq(lanes[0].stops, [Vector2i(1, 1), Vector2i(2, 1)] as Array[Vector2i])
	assert_eq(lanes[1].side, Vector2i.RIGHT)
	assert_eq(lanes[1].stops, [Vector2i(5, 1), Vector2i(4, 1)] as Array[Vector2i], "nearest its own door first")


func test_a_row_without_a_door_offers_no_lane() -> void:
	var state: PackState = CoreFixtures.state(TWO_DOORS_AND_A_ROW_WITHOUT)
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(SINGLE))
	assert_eq(lanes.size(), 2, "the two rows with doors")
	assert_eq(lanes[0].row, 1)
	assert_eq(lanes[1].row, 2)


func test_a_two_row_item_enters_only_where_two_doors_sit_together() -> void:
	var state: PackState = CoreFixtures.state(TWO_DOORS_AND_A_ROW_WITHOUT)
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(UPRIGHT_PAIR))
	assert_eq(lanes.size(), 1)
	assert_eq(lanes[0].row, 1)
	assert_eq(CoreFixtures.sorted(lanes[0].door_cells), [Vector2i(0, 1), Vector2i(0, 2)] as Array[Vector2i])
	assert_eq(lanes[0].stops.size(), 4)


func test_a_two_row_item_stops_where_either_of_its_rows_is_blocked() -> void:
	var state: PackState = CoreFixtures.state(TWO_DOORS_AND_A_ROW_WITHOUT)
	CoreFixtures.put(state, SINGLE, Vector2i(3, 2))
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(state, CellShape.from_text(UPRIGHT_PAIR))
	assert_eq(lanes[0].stops, [Vector2i(1, 1), Vector2i(2, 1)] as Array[Vector2i])


# --- Shifting and leaving -------------------------------------------------

func test_an_item_with_free_cells_on_both_sides_can_shift_both_ways() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	var item: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(2, 1))
	var reach: ShiftRange = AccessSolver.shift_range(state, item.id)
	assert_eq(reach.stops, [Vector2i(1, 1), Vector2i(3, 1), Vector2i(4, 1)] as Array[Vector2i])
	assert_true(not reach.has_stop(Vector2i(2, 1)), "where it already is is not a stop")


func test_the_item_nearest_the_door_can_leave() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	var front: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(1, 1))
	CoreFixtures.put(state, SINGLE, Vector2i(2, 1))
	var reach: ShiftRange = AccessSolver.shift_range(state, front.id)
	assert_true(reach.can_leave(Vector2i.LEFT))
	assert_true(not reach.can_leave(Vector2i.RIGHT), "there is a wall on the right")


func test_an_item_behind_another_cannot_leave_and_the_one_in_front_is_named() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	var front: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(1, 1))
	var behind: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(3, 1))
	var reach: ShiftRange = AccessSolver.shift_range(state, behind.id)
	assert_true(not reach.can_leave(Vector2i.LEFT))
	assert_eq(reach.stops, [Vector2i(2, 1), Vector2i(4, 1)] as Array[Vector2i], "it can still shift in the gaps")
	assert_eq(AccessSolver.blockers(state, behind.id, Vector2i.LEFT), [front.id] as Array[int])


func test_every_item_between_a_buried_item_and_the_door_is_named() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	var first: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(1, 1))
	var second: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(2, 1))
	var buried: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(4, 1))
	assert_eq(AccessSolver.blockers(state, buried.id, Vector2i.LEFT), [second.id, first.id] as Array[int], "nearest first")


func test_a_two_row_item_is_blocked_by_an_item_in_either_of_its_rows() -> void:
	for blocked_row: int in [1, 2]:
		var state: PackState = CoreFixtures.state(TWO_ROWS)
		var tall: PackItem = CoreFixtures.put(state, UPRIGHT_PAIR, Vector2i(3, 1))
		var in_the_way: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(1, blocked_row))
		var reach: ShiftRange = AccessSolver.shift_range(state, tall.id)
		assert_true(not reach.can_leave(Vector2i.LEFT), "blocked in row %d" % blocked_row)
		assert_eq(reach.stops, [Vector2i(2, 1), Vector2i(4, 1)] as Array[Vector2i])
		assert_eq(AccessSolver.blockers(state, tall.id, Vector2i.LEFT), [in_the_way.id] as Array[int])


func test_a_wall_in_the_way_names_no_blocker() -> void:
	var state: PackState = CoreFixtures.state(TWO_DOORS_AND_A_ROW_WITHOUT)
	var item: PackItem = CoreFixtures.put(state, SINGLE, Vector2i(2, 3))
	var reach: ShiftRange = AccessSolver.shift_range(state, item.id)
	assert_true(not reach.can_leave(Vector2i.LEFT))
	assert_eq(AccessSolver.blockers(state, item.id, Vector2i.LEFT), [] as Array[int])


# --- Turning --------------------------------------------------------------

# The drawing in PLAN.md section 3.4:
#   D . L . . #        D . . L L #
#   D . L * B #   ->   D . . * B #
func test_an_l_stopped_short_of_a_block_turns_about_its_grip_to_hook_over_the_block() -> void:
	var state: PackState = CoreFixtures.state(TWO_ROWS)
	var l_item: PackItem = CoreFixtures.put(state, L_SHAPE, Vector2i(2, 1))
	CoreFixtures.put(state, SINGLE, Vector2i(4, 2))
	var grip: Vector2i = Vector2i(3, 2)
	var option: TurnOption = AccessSolver.turn_option(state, l_item.id, grip, true)
	assert_true(option != null, "the turn is offered")
	var cells_after: Array[Vector2i] = CoreFixtures.sorted(option.shape.cells_at(option.origin))
	assert_eq(cells_after, [Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 1)] as Array[Vector2i])
	assert_true(cells_after.has(grip), "the gripped cell stays where it is")


func test_an_item_cannot_turn_into_a_wall() -> void:
	var state: PackState = CoreFixtures.state(ONE_ROW)
	var item: PackItem = CoreFixtures.put(state, FLAT_PAIR, Vector2i(2, 1))
	assert_true(AccessSolver.turn_option(state, item.id, Vector2i(2, 1), true) == null, "clockwise")
	assert_true(AccessSolver.turn_option(state, item.id, Vector2i(2, 1), false) == null, "anticlockwise")


func test_an_item_cannot_turn_onto_a_door() -> void:
	var state: PackState = CoreFixtures.state(TWO_ROWS)
	var item: PackItem = CoreFixtures.put(state, UPRIGHT_PAIR, Vector2i(1, 1))
	assert_true(AccessSolver.turn_option(state, item.id, Vector2i(1, 1), true) == null)


func test_an_item_cannot_turn_onto_an_occupied_cell() -> void:
	var state: PackState = CoreFixtures.state(TWO_ROWS)
	var item: PackItem = CoreFixtures.put(state, FLAT_PAIR, Vector2i(2, 1))
	CoreFixtures.put(state, SINGLE, Vector2i(2, 2))
	assert_true(AccessSolver.turn_option(state, item.id, Vector2i(2, 1), true) == null)


func test_the_same_item_turns_differently_about_each_cell_it_is_gripped_by() -> void:
	var state: PackState = CoreFixtures.state(TWO_ROWS)
	var item: PackItem = CoreFixtures.put(state, FLAT_PAIR, Vector2i(2, 1))
	var about_left: TurnOption = AccessSolver.turn_option(state, item.id, Vector2i(2, 1), true)
	var about_right: TurnOption = AccessSolver.turn_option(state, item.id, Vector2i(3, 1), false)
	assert_eq(about_left.origin, Vector2i(2, 1), "it stands up in column 3")
	assert_eq(about_right.origin, Vector2i(3, 1), "it stands up in column 4")


func test_a_turn_about_a_cell_that_is_not_part_of_the_item_is_refused() -> void:
	var state: PackState = CoreFixtures.state(TWO_ROWS)
	var item: PackItem = CoreFixtures.put(state, FLAT_PAIR, Vector2i(2, 1))
	assert_true(AccessSolver.turn_option(state, item.id, Vector2i(4, 1), true) == null)


func test_an_item_whose_type_cannot_rotate_is_refused() -> void:
	var state: PackState = CoreFixtures.state(TWO_ROWS)
	var item: PackItem = CoreFixtures.put(state, FLAT_PAIR, Vector2i(2, 1), false)
	assert_true(AccessSolver.turn_option(state, item.id, Vector2i(2, 1), true) == null)


func test_an_item_turned_across_a_row_with_no_door_cannot_leave_until_turned_back() -> void:
	var state: PackState = CoreFixtures.state([
		"#####",
		"D...#",
		"#...#",
		"#####",
	])
	var item: PackItem = CoreFixtures.put(state, FLAT_PAIR, Vector2i(2, 1))
	var grip: Vector2i = Vector2i(2, 1)
	assert_true(AccessSolver.shift_range(state, item.id).can_leave(Vector2i.LEFT), "lying flat it can leave")
	var upright: TurnOption = AccessSolver.turn_option(state, item.id, grip, true)
	state.move(item.id, upright.shape, upright.origin)
	assert_true(not AccessSolver.shift_range(state, item.id).can_leave(Vector2i.LEFT), "upright it cannot")
	assert_eq(AccessSolver.blockers(state, item.id, Vector2i.LEFT), [] as Array[int], "a wall is in the way, not an item")
	var flat: TurnOption = AccessSolver.turn_option(state, item.id, grip, false)
	state.move(item.id, flat.shape, flat.origin)
	assert_true(AccessSolver.shift_range(state, item.id).can_leave(Vector2i.LEFT), "turned back it can leave again")
