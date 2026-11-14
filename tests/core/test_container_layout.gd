## Tests for ContainerLayout: reading a layout text with a legend, the
## meaning of each kind of cell, and the overlay that marks cells for one
## round. It does not test what may slide where; that is AccessSolver.
extends TestCase

const ROWS: Array[String] = [
	"#####",
	"D..|#",
	"#EEE#",
]


func test_a_layout_is_as_wide_as_its_longest_row_and_as_tall_as_its_rows() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS)
	assert_eq(layout.size(), Vector2i(5, 3))
	assert_true(layout.in_bounds(Vector2i(4, 2)))
	assert_true(not layout.in_bounds(Vector2i(5, 2)))


func test_an_item_can_rest_only_on_a_storable_cell() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS)
	assert_eq(layout.storable_cells(), [Vector2i(1, 1), Vector2i(2, 1)] as Array[Vector2i])
	assert_true(not layout.is_storable(Vector2i(0, 1)), "a door")
	assert_true(not layout.is_storable(Vector2i(3, 1)), "a bulkhead")


func test_a_door_can_be_passed_but_not_rested_on() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS)
	assert_true(layout.is_door(Vector2i(0, 1)))
	assert_true(layout.is_passable(Vector2i(0, 1)))
	assert_true(not layout.is_door(Vector2i(1, 1)), "a storable cell is not a door")
	assert_true(not layout.is_door(Vector2i(0, 0)), "a wall is not a door")


func test_walls_and_bulkheads_cannot_be_passed() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS)
	assert_true(not layout.is_passable(Vector2i(0, 0)), "a wall")
	assert_true(not layout.is_passable(Vector2i(3, 1)), "a bulkhead")
	assert_true(not layout.is_passable(Vector2i(2, 2)), "a motor")


func test_cells_carry_the_zone_tags_of_their_legend_entry() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS)
	assert_eq(layout.tags_at(Vector2i(1, 2)), [CoreFixtures.MOTOR_TAG] as Array[StringName])
	assert_eq(layout.tags_at(Vector2i(3, 1)), [] as Array[StringName], "a bulkhead has no tag")
	assert_eq(layout.cells_with_tag(CoreFixtures.MOTOR_TAG), [Vector2i(1, 2), Vector2i(2, 2), Vector2i(3, 2)] as Array[Vector2i])
	assert_eq(layout.entry_at(Vector2i(0, 1)).symbol, "D")


func test_beyond_the_edges_is_outside_and_passable() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS)
	var beyond: Vector2i = Vector2i(-1, 1)
	assert_true(layout.is_outside(beyond))
	assert_true(layout.is_passable(beyond))
	assert_true(not layout.is_storable(beyond))
	assert_true(not layout.is_door(beyond), "outside is not a door")
	assert_eq(layout.tags_at(beyond), [] as Array[StringName])


func test_a_layout_need_not_be_a_rectangle() -> void:
	var layout: ContainerLayout = CoreFixtures.layout([
		"  ###",
		" ##.#",
		"D...#",
		"#####",
	])
	var gap: Vector2i = Vector2i(0, 0)
	assert_true(layout.in_bounds(gap), "the gap is inside the bounding rectangle")
	assert_true(layout.is_outside(gap), "and is still outside the container")
	assert_true(layout.is_passable(gap))
	assert_true(not layout.is_outside(Vector2i(2, 0)), "a wall is part of the container")
	assert_eq(layout.storable_cells().size(), 4)


func test_an_overlay_adds_its_tag_to_exactly_the_cells_it_marks() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS, [
		".....",
		"..G..",
		".....",
	])
	assert_eq(layout.cells_with_tag(CoreFixtures.MARKED_TAG), [Vector2i(2, 1)] as Array[Vector2i])
	assert_eq(layout.tags_at(Vector2i(1, 1)), [] as Array[StringName], "the cell beside it is untouched")
	assert_eq(layout.overlay_entry_at(Vector2i(2, 1)).symbol, "G")
	assert_true(layout.overlay_entry_at(Vector2i(1, 1)) == null)


func test_an_overlay_changes_nothing_else_about_a_cell() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(ROWS, [
		".....",
		"G.G..",
		".....",
	])
	assert_true(layout.is_storable(Vector2i(2, 1)), "a marked storable cell stays storable")
	assert_true(layout.is_door(Vector2i(0, 1)), "a marked door stays a door")
	assert_eq(layout.entry_at(Vector2i(2, 1)).symbol, ".")


func test_blank_lines_around_a_layout_text_are_ignored() -> void:
	var layout: ContainerLayout = ContainerLayout.parse("\nD.#\r\nD.#\n\n", CoreFixtures.legend())
	assert_eq(layout.size(), Vector2i(3, 2))
	assert_true(layout.is_door(Vector2i(0, 0)))
