## Catalog loads every content file under data/ by scanning its folders, so
## that adding content means dropping a file in (PLAN.md section 4.4). There
## is no registry to update. It offers the content back by kind. It never
## holds progress or tuning values; those belong to GameState and Tuning.
extends Node

# Where to look
#   Reads:      every .tres in the folders of data/, except data/tuning/
#   Kinds:      core/packing/packing_scenario.gd, core/packing/pack_item_type.gd, core/grid/layout_legend.gd,
#               game/space/space_map.gd, game/launch/scheduled_launch.gd, game/ships/ship_type.gd
#   Used by:    ui/overview/overview_screen.gd -> _redraw(), _on_upcoming_chosen()
#   Registered: project.godot, under [autoload]
#   Tests:      tests/game/test_catalog.gd, tests/data/test_example_data.gd

const DATA_ROOT: String = "res://data"
const SCENARIOS_FOLDER: String = "scenarios"
const ITEM_TYPES_FOLDER: String = "cargo"
const LEGENDS_FOLDER: String = "legends"
const MAPS_FOLDER: String = "maps"
const LAUNCHES_FOLDER: String = "launches"
const SHIPS_FOLDER: String = "ships"
# The Tuning autoload loads this folder itself.
const SKIPPED_FOLDERS: Array[String] = ["tuning"]
const FOLDER_SUFFIX: String = "/"
const RESOURCE_SUFFIX: String = ".tres"

# Folder name to the resources in it, in file-name order.
var _by_folder: Dictionary[String, Array] = {}


# Loads everything once, when the game starts.
func _ready() -> void:
	reload()


## Scans data/ again. Called once at start-up.
func reload() -> void:
	_by_folder.clear()
	for entry: String in ResourceLoader.list_directory(DATA_ROOT):
		if not entry.ends_with(FOLDER_SUFFIX):
			continue
		var folder: String = entry.trim_suffix(FOLDER_SUFFIX)
		if not SKIPPED_FOLDERS.has(folder):
			_by_folder[folder] = _load_folder(DATA_ROOT.path_join(folder))


## Every resource in one folder of data/, in file-name order.
func in_folder(folder: String) -> Array[Resource]:
	var found: Array[Resource] = []
	if _by_folder.has(folder):
		found.assign(_by_folder[folder])
	return found


## The rounds in data/scenarios/, in file-name order.
func scenarios() -> Array[PackingScenario]:
	var found: Array[PackingScenario] = []
	for resource: Resource in in_folder(SCENARIOS_FOLDER):
		if resource is PackingScenario:
			found.append(resource)
	return found


## The item types in data/cargo/.
func item_types() -> Array[PackItemType]:
	var found: Array[PackItemType] = []
	for resource: Resource in in_folder(ITEM_TYPES_FOLDER):
		if resource is PackItemType:
			found.append(resource)
	return found


## The legends in data/legends/.
func legends() -> Array[LayoutLegend]:
	var found: Array[LayoutLegend] = []
	for resource: Resource in in_folder(LEGENDS_FOLDER):
		if resource is LayoutLegend:
			found.append(resource)
	return found


## The maps in data/maps/. The overview draws the first.
func space_maps() -> Array[SpaceMap]:
	var found: Array[SpaceMap] = []
	for resource: Resource in in_folder(MAPS_FOLDER):
		if resource is SpaceMap:
			found.append(resource)
	return found


## The upcoming launches in data/launches/, in file-name order, which is the
## order the overview lists them in.
func scheduled_launches() -> Array[ScheduledLaunch]:
	var found: Array[ScheduledLaunch] = []
	for resource: Resource in in_folder(LAUNCHES_FOLDER):
		if resource is ScheduledLaunch:
			found.append(resource)
	return found


## The ship types in data/ships/, in file-name order, which is the order
## the overview offers them in.
func ships() -> Array[ShipType]:
	var found: Array[ShipType] = []
	for resource: Resource in in_folder(SHIPS_FOLDER):
		if resource is ShipType:
			found.append(resource)
	return found


# ResourceLoader.list_directory is used, not DirAccess, because in an
# exported build a resource is stored under another name with ".remap"
# added. This call still reports the names the project has in the editor.
func _load_folder(path: String) -> Array[Resource]:
	var names: Array[String] = []
	for entry: String in ResourceLoader.list_directory(path):
		if entry.ends_with(RESOURCE_SUFFIX):
			names.append(entry)
	names.sort()
	var loaded: Array[Resource] = []
	for file_name: String in names:
		var resource: Resource = ResourceLoader.load(path.path_join(file_name))
		if resource == null:
			push_error("Catalog: %s did not load." % path.path_join(file_name))
		else:
			loaded.append(resource)
	return loaded
