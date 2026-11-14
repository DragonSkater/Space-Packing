## Runs the packing core as a bakery would use it: a delivery van with a
## hatch and a heater, loaded with pastries. Nothing here mentions space,
## which is the point: core/ assumes no theme (PLAN.md section 4.2). The
## legend uses its own characters and tags to show that both are only data.
extends TestCase

const HEATER_TAG: StringName = &"heater"
const FROSTED_TAG: StringName = &"frosted"
const VAN_ROWS: Array[String] = [
	"WWWWW",
	"O___W",
	"O___W",
	"WHHHW",
]


func test_a_van_is_loaded_through_its_hatch_with_the_same_rules() -> void:
	var session: PackingSession = _van_session()
	session.pick_from_stack(0)
	var lanes: Array[EntryLane] = session.entry_lanes()
	assert_eq(lanes.size(), 2, "one lane per shelf row behind the hatch")
	assert_true(session.push_in(lanes[1], 1), "the eclair goes to the back of the lower shelf")
	var eclair: PackItem = session.state().items()[0]
	assert_eq(eclair.origin, Vector2i(2, 2))
	assert_eq(session.moves_left(), 5)


func test_a_tray_loaded_in_front_buries_the_one_behind_it() -> void:
	var session: PackingSession = _van_session()
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[1], 1)
	session.pick_from_stack(0)
	session.push_in(session.entry_lanes()[1], 0)
	var eclair: PackItem = session.state().items()[0]
	var bun: PackItem = session.state().items()[1]
	assert_true(not session.unload(eclair.id, Vector2i.LEFT), "the bun is in the way")
	assert_true(session.unload(bun.id, Vector2i.LEFT), "the bun comes out first")
	assert_true(session.unload(eclair.id, Vector2i.LEFT), "then the eclair")


func test_the_van_has_its_own_zone_tags_and_the_pastries_their_own() -> void:
	var session: PackingSession = _van_session()
	var heater_cells: Array[Vector2i] = session.state().layout.cells_with_tag(HEATER_TAG)
	assert_eq(heater_cells.size(), 3)
	assert_true(session.stack()[0].type.tags.has(FROSTED_TAG), "the eclair is frosted")
	assert_true(not session.stack()[1].type.tags.has(FROSTED_TAG), "the bun is not")


func _van_session() -> PackingSession:
	var legend: LayoutLegend = LayoutLegend.new()
	legend.entries = [
		CoreFixtures.entry("W", false, false, []),
		CoreFixtures.entry("_", true, true, []),
		CoreFixtures.entry("O", true, false, []),
		CoreFixtures.entry("H", false, false, [HEATER_TAG]),
	]
	var eclair: PackItemType = CoreFixtures.item_type("XX")
	eclair.tags = [FROSTED_TAG]
	var bun: PackItemType = CoreFixtures.item_type("X")
	var manifest: Array[Batch] = [CoreFixtures.batch(eclair, 1), CoreFixtures.batch(bun, 2)]
	var van: ContainerLayout = ContainerLayout.parse("\n".join(VAN_ROWS), legend)
	return PackingSession.new(van, manifest, PackingTuning.new(), 6)
