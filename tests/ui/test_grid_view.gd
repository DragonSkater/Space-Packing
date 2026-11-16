## Tests for GridView's arithmetic: how large it draws a spot in the space
## it is given, and the conversion between positions and cells. What it
## paints is for the designer's eye and is not tested here.
extends TestCase

const ROWS: Array[String] = [
	"######",
	"D....#",
	"D....#",
	"D....#",
	"#EEEE#",
]


func test_the_spot_is_the_largest_that_fits_the_space() -> void:
	var view: GridView = _view(Vector2(200, 300), 2, 0)
	assert_almost_eq(view.spot_size(), 25.0, DEFAULT_TOLERANCE, "eight columns across 200 units")
	view.free()


func test_the_spot_is_capped_by_the_tuning() -> void:
	var view: GridView = _view(Vector2(1000, 1000), 0, 0)
	assert_almost_eq(view.spot_size(), 40.0)
	assert_true(not view.is_cramped())
	view.free()


func test_a_grid_squeezed_below_the_minimum_is_cramped() -> void:
	var view: GridView = _view(Vector2(100, 300), 2, 2)
	assert_almost_eq(view.spot_size(), 10.0)
	assert_true(view.is_cramped())
	view.free()


func test_positions_and_cells_convert_both_ways_with_the_grid_centred() -> void:
	var view: GridView = _view(Vector2(200, 300), 2, 0)
	# Eight columns of 25 fill the width; five rows of 25 leave 87.5 above.
	assert_eq(view.point_of(Vector2.ZERO), Vector2(50, 87.5))
	assert_eq(view.cell_rect(Vector2i(1, 1)), Rect2(75, 112.5, 25, 25))
	assert_eq(view.cell_at(Vector2(51, 88)), Vector2i(0, 0))
	assert_eq(view.cell_at(Vector2(49, 88)), Vector2i(-1, 0), "the apron is column -1 and beyond")
	assert_eq(view.grid_point_at(view.point_of(Vector2(2.5, 3.25))), Vector2(2.5, 3.25))
	view.free()


func _view(space: Vector2, apron_left: int, apron_right: int) -> GridView:
	var tuning: PresentationTuning = PresentationTuning.new()
	tuning.spot_size = 40.0
	tuning.spot_size_min = 24.0
	var view: GridView = GridView.new()
	view.size = space
	view.show_layout(CoreFixtures.layout(ROWS), tuning, apron_left, apron_right)
	return view
