## Runs every headless test and quits with exit code 0 when all pass, 1
## otherwise. It finds each tests/**/test_*.gd file and calls every method
## whose name starts with "test_" on a fresh instance. Looking methods up by
## name is reflection outside debug/tuning_panel; MILESTONES.md milestone 0
## asks for it here. Assertions live in TestCase, not in this file.
extends Node

const TESTS_ROOT: String = "res://tests"
const FILE_PREFIX: String = "test_"
const FILE_SUFFIX: String = ".gd"
const METHOD_PREFIX: String = "test_"
# These two match the file pattern and are the test machinery itself.
const NOT_TEST_FILES: Array[String] = ["res://tests/test_case.gd", "res://tests/test_runner.gd"]

var _catcher: ErrorCatcher = ErrorCatcher.new()
var _tests_run: int = 0
var _failure_lines: Array[String] = []


func _ready() -> void:
	OS.add_logger(_catcher)
	var paths: Array[String] = _find_test_files(TESTS_ROOT)
	paths.sort()
	for path: String in paths:
		_run_file(path)
	OS.remove_logger(_catcher)
	_print_summary(paths.size())
	var exit_code: int = 0
	if not _failure_lines.is_empty() or _tests_run == 0:
		exit_code = 1
	get_tree().quit(exit_code)


func _find_test_files(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file_name: String in DirAccess.get_files_at(folder):
		var path: String = folder.path_join(file_name)
		if not file_name.begins_with(FILE_PREFIX) or not file_name.ends_with(FILE_SUFFIX):
			continue
		if NOT_TEST_FILES.has(path):
			continue
		found.append(path)
	for subfolder: String in DirAccess.get_directories_at(folder):
		found.append_array(_find_test_files(folder.path_join(subfolder)))
	return found


func _run_file(path: String) -> void:
	var script: GDScript = load(path) as GDScript
	var load_errors: Array[String] = _catcher.take_errors()
	if script == null or not load_errors.is_empty():
		_record_failure(path, "", "the script did not load")
		for error: String in load_errors:
			_record_failure(path, "", error)
		return
	if not _extends_test_case(script):
		_record_failure(path, "", "the script does not extend TestCase")
		return
	var method_names: Array[String] = _test_method_names(script)
	if method_names.is_empty():
		_record_failure(path, "", "the file has no methods starting with \"%s\"" % METHOD_PREFIX)
		return
	for method_name: String in method_names:
		_run_method(path, script, method_name)


func _run_method(path: String, script: GDScript, method_name: String) -> void:
	# A fresh instance per method, so that no test can lean on another.
	var test: TestCase = script.new() as TestCase
	test.call(method_name)
	_tests_run += 1
	for message: String in test.failures():
		_record_failure(path, method_name, message)
	for error: String in _catcher.take_errors():
		_record_failure(path, method_name, error)


func _extends_test_case(script: GDScript) -> bool:
	var base: Script = script.get_base_script()
	while base != null:
		if base == TestCase:
			return true
		base = base.get_base_script()
	return false


func _test_method_names(script: GDScript) -> Array[String]:
	var names: Array[String] = []
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with(METHOD_PREFIX) and not names.has(method_name):
			names.append(method_name)
	return names


func _record_failure(path: String, method_name: String, message: String) -> void:
	var where: String = path
	if not method_name.is_empty():
		where = "%s :: %s" % [path, method_name]
	_failure_lines.append("FAIL  %s  --  %s" % [where, message])


func _print_summary(file_count: int) -> void:
	for line: String in _failure_lines:
		print(line)
	if _tests_run == 0:
		print("No tests were found under %s." % TESTS_ROOT)
	print("%d tests in %d files, %d failures." % [_tests_run, file_count, _failure_lines.size()])
