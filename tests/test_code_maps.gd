## Keeps the navigation comments honest (CLAUDE.md, Code style). Every script
## under core/, game/, ui/ and debug/ must carry a "# Where to look" block,
## every file and function that block names must exist, and every function
## must have a comment above it. It cannot tell whether a comment is true.
extends TestCase

const CHECKED_ROOTS: Array[String] = ["res://core", "res://game", "res://ui", "res://debug"]
const SCRIPT_SUFFIX: String = ".gd"
const MAP_HEADING: String = "# Where to look"
const MAP_LINE_PREFIX: String = "#   "
const COMMENT_PREFIX: String = "#"
# A project file, such as ui/common/grid_view.gd, or a function, such as draw().
const NAMED_THING: String = "(?<file>[a-z_]+(?:/[a-z_0-9]+)+\\.(?:gd|tscn|tres|md))|(?<function>\\w+)\\(\\)"
const FUNCTION_LINE: String = "^(?:static )?func (\\w+)\\("


func test_every_script_has_a_map_that_names_only_real_files_and_functions() -> void:
	var named: RegEx = RegEx.create_from_string(NAMED_THING)
	for path: String in _scripts():
		var map_lines: Array[String] = _map_lines(path)
		assert_true(not map_lines.is_empty(), "%s has a \"%s\" block" % [path, MAP_HEADING])
		# A function belongs to the file named most recently before it.
		var current_file: String = ""
		for line: String in map_lines:
			for found: RegExMatch in named.search_all(line):
				if not found.get_string("file").is_empty():
					current_file = "res://" + found.get_string("file")
					assert_true(FileAccess.file_exists(current_file), "%s names %s, which exists" % [path, current_file])
				else:
					_check_function(path, current_file, found.get_string("function"))


func test_every_function_has_a_comment_saying_what_it_does() -> void:
	var function_line: RegEx = RegEx.create_from_string(FUNCTION_LINE)
	for path: String in _scripts():
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for index: int in range(1, lines.size()):
			var found: RegExMatch = function_line.search(lines[index])
			if found != null and not lines[index - 1].strip_edges().begins_with(COMMENT_PREFIX):
				fail("%s: %s() has no comment above it" % [path, found.get_string(1)])


func _check_function(path: String, in_file: String, function_name: String) -> void:
	if in_file.is_empty() or not FileAccess.file_exists(in_file):
		fail("%s names %s() before naming the file it is in" % [path, function_name])
		return
	var source: String = FileAccess.get_file_as_string(in_file)
	var declared: bool = source.contains("func %s(" % function_name)
	assert_true(declared, "%s names %s() in %s, which declares it" % [path, function_name, in_file])


# The lines of a script's map: those after the heading that are indented
# under it.
func _map_lines(path: String) -> Array[String]:
	var found: Array[String] = []
	var inside: bool = false
	for line: String in FileAccess.get_file_as_string(path).split("\n"):
		if line == MAP_HEADING:
			inside = true
		elif inside and line.begins_with(MAP_LINE_PREFIX):
			found.append(line)
		elif inside:
			break
	return found


func _scripts() -> Array[String]:
	var found: Array[String] = []
	for folder: String in CHECKED_ROOTS:
		found.append_array(_scripts_in(folder))
	return found


func _scripts_in(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(folder):
		if file_name.ends_with(SCRIPT_SUFFIX):
			found.append(folder.path_join(file_name))
	for subfolder: String in DirAccess.get_directories_at(folder):
		found.append_array(_scripts_in(folder.path_join(subfolder)))
	return found
