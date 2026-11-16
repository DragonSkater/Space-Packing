## Tests ShipType with hulls built in code: it counts its cargo spots from
## the hull drawing, knows when it has no hull, and reports a hull it cannot
## read. The example ships in data/ships/ are checked in tests/data/.
extends TestCase


func test_cargo_spots_are_counted_from_the_hull_drawing() -> void:
	var ship: ShipType = _ship(["######", "D....#", "D....#", "#EEEE#"])
	assert_true(ship.has_hull())
	assert_eq(ship.cargo_spot_count(), 8, "doors, walls and engines hold no cargo")
	assert_eq(ship.problems(), [] as Array[String])


func test_a_ship_with_an_empty_drawing_has_no_hull_and_no_spots() -> void:
	var ship: ShipType = _ship([])
	assert_true(not ship.has_hull())
	assert_eq(ship.cargo_spot_count(), 0)
	assert_eq(ship.problems(), [] as Array[String], "a craft with no hold is allowed")


func test_a_hull_without_a_legend_is_a_problem() -> void:
	var ship: ShipType = _ship(["####", "D..#", "####"])
	ship.legend = null
	assert_true(not ship.problems().is_empty())


# A named ship read with the core test legend.
func _ship(rows: Array[String]) -> ShipType:
	var ship: ShipType = ShipType.new()
	ship.display_name = "Test ship"
	ship.hull_layout_text = "\n".join(rows)
	ship.legend = CoreFixtures.legend()
	return ship
