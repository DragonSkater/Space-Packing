## Tests that the Catalog autoload finds content by scanning data/, with no
## registry, and that the Tuning autoload has its two resources. Whether the
## example content makes sense is checked in tests/data/. That the scan also
## works in an exported build has to be proved by running the export.
extends TestCase

const EXAMPLE_ITEM_IDS: Array[StringName] = [
	&"example_beam", &"example_block", &"example_crate", &"example_elbow", &"example_rail",
]


func test_the_catalog_finds_the_example_scenarios_in_file_name_order() -> void:
	var scenarios: Array[PackingScenario] = Catalog.scenarios()
	assert_true(scenarios.size() >= 2, "both example scenarios")
	assert_eq(scenarios[0].resource_path.get_file(), "example_01_side_doors.tres")
	assert_eq(scenarios[1].resource_path.get_file(), "example_02_both_sides.tres")


func test_the_catalog_finds_the_five_example_item_types() -> void:
	var found: Array[StringName] = []
	for item_type: PackItemType in Catalog.item_types():
		found.append(item_type.id)
	for id: StringName in EXAMPLE_ITEM_IDS:
		assert_true(found.has(id), "%s is in the catalog" % id)


func test_the_catalog_finds_the_example_legend() -> void:
	var legends: Array[LayoutLegend] = Catalog.legends()
	assert_true(not legends.is_empty(), "a legend")
	assert_true(legends[0].entry_for("D") != null, "with an entry for a door")


func test_a_folder_holds_only_resources_and_an_unknown_folder_is_empty() -> void:
	assert_eq(Catalog.in_folder("scenarios").size(), Catalog.scenarios().size(), "the README is not content")
	assert_eq(Catalog.in_folder("no_such_folder"), [] as Array[Resource])
	assert_eq(Catalog.in_folder("tuning"), [] as Array[Resource], "tuning belongs to the Tuning autoload")


func test_tuning_holds_the_packing_and_presentation_resources() -> void:
	assert_true(Tuning.packing != null, "packing tuning")
	assert_eq(Tuning.packing.resource_path, "res://data/tuning/packing_tuning.tres")
	assert_true(Tuning.presentation is PresentationTuning, "presentation tuning")
	assert_true(PresentationTuning.current() == Tuning.presentation, "screens read the same object")
