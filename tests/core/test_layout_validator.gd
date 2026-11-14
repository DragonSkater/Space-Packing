## Tests for LayoutValidator: each problem and each warning, triggered by
## the smallest layout that shows it, and a well-made layout that triggers
## none. It does not test how a screen reports them.
extends TestCase

const WELL_MADE: Array[String] = [
	"#####",
	"D...#",
	"D...#",
	"#####",
]


func test_a_well_made_layout_has_no_problems_and_no_warnings() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(WELL_MADE)
	assert_eq(LayoutValidator.problems(layout), [] as Array[String])
	assert_eq(LayoutValidator.warnings(layout), [] as Array[String])


func test_an_unknown_character_is_a_problem_that_names_its_column_and_row() -> void:
	var layout: ContainerLayout = CoreFixtures.layout([
		"#####",
		"D.Q.#",
		"#####",
	])
	var problems: Array[String] = LayoutValidator.problems(layout)
	assert_eq(problems.size(), 1)
	assert_true(problems[0].contains("'Q'"), problems[0])
	assert_true(problems[0].contains("column 3, row 2"), problems[0])


func test_a_layout_with_nowhere_to_rest_an_item_is_a_problem() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(["#D#"])
	var problems: Array[String] = LayoutValidator.problems(layout)
	assert_eq(problems.size(), 1)
	assert_true(problems[0].contains("no cell where an item can rest"), problems[0])


func test_a_layout_with_no_door_is_a_problem() -> void:
	var layout: ContainerLayout = CoreFixtures.layout([
		"###",
		"#.#",
		"###",
	])
	var problems: Array[String] = LayoutValidator.problems(layout)
	assert_eq(problems.size(), 1)
	assert_true(problems[0].contains("no door"), problems[0])


func test_a_storable_cell_beside_the_outside_is_a_warning() -> void:
	var layout: ContainerLayout = CoreFixtures.layout([
		"#####",
		"D... ",
		"#####",
	])
	var warnings: Array[String] = LayoutValidator.warnings(layout)
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("column 4, row 2"), warnings[0])
	assert_true(warnings[0].contains("open to the outside"), warnings[0])
	assert_eq(LayoutValidator.problems(layout), [] as Array[String], "it can still be played")


func test_a_row_that_no_item_could_enter_is_a_warning() -> void:
	var layout: ContainerLayout = CoreFixtures.layout([
		"#####",
		"D...#",
		"#...#",
		"#####",
	])
	var warnings: Array[String] = LayoutValidator.warnings(layout)
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("columns 2 to 4 of row 3"), warnings[0])


func test_cells_cut_off_from_the_door_by_a_bulkhead_are_a_warning() -> void:
	var layout: ContainerLayout = CoreFixtures.layout([
		"######",
		"D.|..#",
		"######",
	])
	var warnings: Array[String] = LayoutValidator.warnings(layout)
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("columns 4 to 5 of row 2"), warnings[0])


func test_an_overlay_of_the_wrong_size_is_a_warning() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(WELL_MADE, [
		"....",
		".G..",
	])
	var warnings: Array[String] = LayoutValidator.warnings(layout)
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("4 columns by 2 rows"), warnings[0])


func test_an_overlay_that_marks_a_cell_where_nothing_can_rest_is_a_warning() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(WELL_MADE, [
		".....",
		"G....",
		".....",
		".....",
	])
	var warnings: Array[String] = LayoutValidator.warnings(layout)
	assert_eq(warnings.size(), 1)
	assert_true(warnings[0].contains("column 1, row 2"), warnings[0])


func test_an_unknown_character_in_an_overlay_is_a_problem() -> void:
	var layout: ContainerLayout = CoreFixtures.layout(WELL_MADE, [
		".....",
		".Q...",
		".....",
		".....",
	])
	var problems: Array[String] = LayoutValidator.problems(layout)
	assert_eq(problems.size(), 1)
	assert_true(problems[0].contains("overlay character 'Q'"), problems[0])
