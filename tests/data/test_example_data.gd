## Checks the example content of milestone 2 against what its brief asks
## for: playable scenarios with the door layouts described (and a third,
## added at the designer's request, whose stack can be taken from either end), and five
## item types. It guards the hand-written files under data/; it does not
## test the engine, which tests/core/ does with layouts built in code.
extends TestCase

const DESIGNATED_TAG: StringName = &"example_bay"


func test_every_example_scenario_is_playable() -> void:
	for scenario: PackingScenario in Catalog.scenarios():
		assert_eq(scenario.problems(), [] as Array[String], scenario.display_name)
		assert_true(not scenario.display_name.is_empty(), "%s has a name" % scenario.resource_path)
		assert_true(not scenario.manifest.is_empty(), "%s has a stack" % scenario.display_name)


func test_the_first_scenario_has_doors_on_one_side_only_and_no_warnings() -> void:
	var scenario: PackingScenario = Catalog.scenarios()[0]
	var layout: ContainerLayout = scenario.layout()
	assert_eq(_door_columns(layout), [0] as Array[int])
	assert_eq(scenario.warnings(), [] as Array[String])


func test_the_second_scenario_has_a_bulkhead_and_doors_on_both_sides() -> void:
	var layout: ContainerLayout = Catalog.scenarios()[1].layout()
	assert_eq(_door_columns(layout), [0, layout.size().x - 1] as Array[int])
	assert_true(_count_symbol(layout, "|") > 0, "a bulkhead")


func test_the_second_scenario_has_exactly_one_row_without_a_door() -> void:
	var warnings: Array[String] = Catalog.scenarios()[1].warnings()
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("row 3"), warnings[0])


func test_the_second_scenario_offers_a_two_row_piece_exactly_one_opening() -> void:
	var scenario: PackingScenario = Catalog.scenarios()[1]
	var empty: PackState = PackState.new(scenario.layout())
	var lanes: Array[EntryLane] = AccessSolver.entry_lanes(empty, CellShape.from_text("XX\nXX"))
	assert_eq(lanes.size(), 1)
	assert_eq(lanes[0].door_cells.size(), 2, "two doors that sit together")


func test_the_second_scenario_marks_four_designated_spots() -> void:
	var layout: ContainerLayout = Catalog.scenarios()[1].layout()
	var marked: Array[Vector2i] = layout.cells_with_tag(DESIGNATED_TAG)
	assert_eq(marked.size(), 4)
	for cell: Vector2i in marked:
		assert_true(layout.is_storable(cell), "%s can hold a piece" % cell)


func test_the_third_scenario_lets_the_block_at_the_bottom_be_taken_first() -> void:
	var scenario: PackingScenario = Catalog.scenarios()[2]
	assert_true(scenario.stack_bottom_reachable)
	var session: PackingSession = scenario.start(PackingTuning.new())
	var stack: Array[PackItem] = session.stack()
	assert_eq(stack.back().type.id, &"example_block")
	assert_true(session.can_pick(stack.size() - 1))
	assert_eq(scenario.warnings(), [] as Array[String])


func test_the_example_item_types_are_the_five_shapes_the_brief_lists() -> void:
	var sizes: Dictionary[StringName, int] = {}
	var fixed: Array[StringName] = []
	for item_type: PackItemType in Catalog.item_types():
		assert_eq(item_type.problems(), [] as Array[String], String(item_type.id))
		sizes[item_type.id] = item_type.shape().cells.size()
		if not item_type.can_rotate:
			fixed.append(item_type.id)
	assert_eq(sizes[&"example_crate"], 1)
	assert_eq(sizes[&"example_beam"], 2)
	assert_eq(sizes[&"example_elbow"], 3)
	assert_eq(sizes[&"example_block"], 4)
	assert_eq(sizes[&"example_rail"], 2)
	assert_eq(fixed, [&"example_rail"] as Array[StringName], "only the rail may not be turned")


func _door_columns(layout: ContainerLayout) -> Array[int]:
	var columns: Array[int] = []
	for row: int in layout.size().y:
		for column: int in layout.size().x:
			if layout.is_door(Vector2i(column, row)) and not columns.has(column):
				columns.append(column)
	columns.sort()
	return columns


func _count_symbol(layout: ContainerLayout, symbol: String) -> int:
	var count: int = 0
	for row: int in layout.size().y:
		for column: int in layout.size().x:
			if layout.entry_at(Vector2i(column, row)).symbol == symbol:
				count += 1
	return count
