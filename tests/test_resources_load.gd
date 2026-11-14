## Loads every scene, resource and script in the project, so that a broken
## hand-written .tscn or .tres, or a script no test happens to use, fails
## here and not in front of the designer. The addon and the engine's own
## folders are skipped. It checks only that a file loads; whether its
## contents make sense is for other tests.
extends TestCase

const PROJECT_ROOT: String = "res://"
const CHECKED_SUFFIXES: Array[String] = [".tscn", ".tres", ".gd"]
# Third-party code, and export output that is not part of the project.
const SKIPPED_FOLDERS: Array[String] = ["res://addons", "res://Builds", "res://build"]


func test_every_scene_resource_and_script_loads() -> void:
	var paths: Array[String] = _find_files(PROJECT_ROOT)
	assert_true(not paths.is_empty(), "the project has files to load")
	for path: String in paths:
		var loaded: Resource = ResourceLoader.load(path)
		assert_true(loaded != null, "%s loads" % path)


func _find_files(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(folder):
		if _has_checked_suffix(file_name):
			found.append(folder.path_join(file_name))
	for subfolder: String in DirAccess.get_directories_at(folder):
		var path: String = folder.path_join(subfolder)
		# Folders starting with a dot, such as .godot, belong to tools.
		if subfolder.begins_with(".") or SKIPPED_FOLDERS.has(path):
			continue
		found.append_array(_find_files(path))
	return found


func _has_checked_suffix(file_name: String) -> bool:
	for suffix: String in CHECKED_SUFFIXES:
		if file_name.ends_with(suffix):
			return true
	return false
