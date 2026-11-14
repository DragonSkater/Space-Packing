## Guards the rule that core/ is a portable packing engine: no file under it
## may contain a Space Packing theme word, in code, comments or prose
## (CLAUDE.md, Layers). The match ignores case and looks inside longer words,
## so launch_cost fails and so does "relationship". It does not check that
## core/ avoids engine nodes or autoloads.
extends TestCase

const CORE_ROOT: String = "res://core"
const THEME_WORDS: Array[String] = ["ship", "rocket", "cargo", "hull", "launch", "planet"]
# Written by the engine, one random id per script; nobody reads or edits them.
const SKIPPED_SUFFIX: String = ".uid"


func test_core_contains_no_theme_words() -> void:
	var paths: Array[String] = _find_files(CORE_ROOT)
	assert_true(not paths.is_empty(), "core/ has files to check")
	for path: String in paths:
		_check_file(path)


func _check_file(path: String) -> void:
	var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
	for index: int in lines.size():
		var line: String = lines[index].to_lower()
		for word: String in THEME_WORDS:
			if line.contains(word):
				fail("%s line %d contains the theme word \"%s\"" % [path, index + 1, word])


func _find_files(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(folder):
		if not file_name.ends_with(SKIPPED_SUFFIX):
			found.append(folder.path_join(file_name))
	for subfolder: String in DirAccess.get_directories_at(folder):
		found.append_array(_find_files(folder.path_join(subfolder)))
	return found
