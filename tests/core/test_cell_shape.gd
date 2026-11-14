## Tests for CellShape: reading a drawing, turning, and telling whether a
## shape is one connected piece. It does not test where a shape may go.
extends TestCase


func test_a_drawing_becomes_cells_with_x_as_filled() -> void:
	var shape: CellShape = CellShape.from_text("XX")
	assert_eq(shape.cells, [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i])
	assert_eq(CellShape.from_text("X").cells.size(), 1, "a single cell")
	assert_eq(CellShape.from_text("..\n..").cells.size(), 0, "a drawing with no X is empty")


func test_a_shape_is_normalised_to_its_top_left_corner() -> void:
	var shape: CellShape = CellShape.from_text("...\n.XX")
	assert_eq(shape.bounds(), Rect2i(0, 0, 2, 1))
	assert_eq(shape.cells, [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i])


func test_an_l_is_read_as_three_cells() -> void:
	var shape: CellShape = CellShape.from_text("X.\nXX")
	assert_eq(CoreFixtures.sorted(shape.cells), [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1)] as Array[Vector2i])
	assert_eq(shape.bounds().size, Vector2i(2, 2))


func test_a_clockwise_turn_takes_a_flat_piece_upright() -> void:
	var turned: CellShape = CellShape.from_text("XX").rotated_clockwise()
	assert_eq(turned.cells, [Vector2i(0, 0), Vector2i(0, 1)] as Array[Vector2i])


func test_an_l_turned_clockwise_matches_its_drawing_turned_by_hand() -> void:
	var turned: CellShape = CellShape.from_text("X.\nXX").rotated_clockwise()
	assert_true(turned.matches(CellShape.from_text("XX\nX.")))


func test_four_quarter_turns_return_the_original() -> void:
	var original: CellShape = CellShape.from_text("X.\nXX\nX.")
	var turned: CellShape = original
	for _turn: int in 4:
		turned = turned.rotated_clockwise()
	assert_eq(turned.cells, original.cells)


func test_a_clockwise_turn_then_an_anticlockwise_turn_cancel_out() -> void:
	var original: CellShape = CellShape.from_text("X.\nXX")
	var back: CellShape = original.rotated_clockwise().rotated_anticlockwise()
	assert_eq(back.cells, original.cells)


func test_cells_joined_by_their_sides_are_one_piece() -> void:
	assert_true(CellShape.from_text("X.\nXX").is_one_piece(), "an L")
	assert_true(CellShape.from_text("XX\nXX").is_one_piece(), "a two-by-two block")


func test_cells_touching_only_at_a_corner_are_not_one_piece() -> void:
	assert_true(not CellShape.from_text("X.\n.X").is_one_piece(), "a diagonal pair")
	assert_true(not CellShape.from_text("X.X").is_one_piece(), "a pair with a gap")
	assert_true(not CellShape.from_text("...").is_one_piece(), "an empty shape")
