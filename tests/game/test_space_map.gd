## Tests for the map of space and the placeholder launches that fly across
## it: the map in data/maps/ is sound, every upcoming launch goes to a body
## on it and has a round to pack, and a map's own check catches a missing
## home or a link to a body that is not on the map.
extends TestCase


func test_the_example_map_has_a_home_and_no_problems() -> void:
	var maps: Array[SpaceMap] = Catalog.space_maps()
	assert_true(not maps.is_empty(), "a map in data/maps/")
	if maps.is_empty():
		return
	assert_eq(maps[0].problems(), [] as Array[String])
	assert_true(maps[0].home.pads > 0, "home has pads to launch from")


func test_every_upcoming_launch_has_a_round_and_a_destination_on_the_map() -> void:
	var map: SpaceMap = Catalog.space_maps()[0]
	var scheduled_launches: Array[ScheduledLaunch] = Catalog.scheduled_launches()
	assert_true(not scheduled_launches.is_empty(), "launches in data/launches/")
	for scheduled: ScheduledLaunch in scheduled_launches:
		assert_true(scheduled.scenario != null, "%s has a scenario" % scheduled.display_name)
		assert_true(map.bodies.has(scheduled.destination), "%s goes to a body on the map" % scheduled.display_name)


func test_only_the_first_upcoming_launch_is_open_from_the_start() -> void:
	var scheduled_launches: Array[ScheduledLaunch] = Catalog.scheduled_launches()
	assert_true(scheduled_launches[0].requires == null, "the first needs nothing")
	for index: int in range(1, scheduled_launches.size()):
		assert_true(scheduled_launches[index].requires == scheduled_launches[index - 1], "each needs the one before (D36)")


func test_a_map_reports_a_missing_home_and_a_stray_link() -> void:
	var near: Body = Body.new()
	var stray: Body = Body.new()
	var map: SpaceMap = SpaceMap.new()
	map.bodies = [near] as Array[Body]
	var link: SpaceLink = SpaceLink.new()
	link.from_body = near
	link.to_body = stray
	map.links = [link] as Array[SpaceLink]
	assert_eq(map.problems().size(), 2, "no home, and a link off the map")
	map.home = near
	map.bodies.append(stray)
	assert_eq(map.problems(), [] as Array[String])
