## Base class for a headless test file. A test file extends this class and
## declares methods whose names start with "test_"; the runner calls each one
## on a fresh instance. This class only records failures. It does not find or
## run tests, and it prints nothing.
class_name TestCase
extends RefCounted

const DEFAULT_TOLERANCE: float = 0.0001

var _failures: Array[String] = []


## The messages recorded so far, in the order they were recorded.
func failures() -> Array[String]:
	return _failures


## Records a failure. The test carries on, so one run can report several.
func fail(message: String) -> void:
	_failures.append(message)


func assert_true(condition: bool, message: String = "") -> void:
	if not condition:
		fail(_with_context("expected true, got false", message))


func assert_eq(actual: Variant, expected: Variant, message: String = "") -> void:
	if not _same_value(actual, expected):
		var found: String = "expected %s, got %s" % [_show(expected), _show(actual)]
		fail(_with_context(found, message))


func assert_almost_eq(actual: float, expected: float, tolerance: float = DEFAULT_TOLERANCE, message: String = "") -> void:
	if absf(actual - expected) > tolerance:
		var found: String = "expected %s within %s, got %s" % [expected, tolerance, actual]
		fail(_with_context(found, message))


# Values of different types are never equal here. Comparing them with ==
# is a script error for some pairs of types, and a test that asks for 1 and
# is given 1.0 should be told so.
func _same_value(a: Variant, b: Variant) -> bool:
	if typeof(a) != typeof(b):
		return false
	return a == b


func _show(value: Variant) -> String:
	return "%s (%s)" % [var_to_str(value), type_string(typeof(value))]


func _with_context(found: String, message: String) -> String:
	if message.is_empty():
		return found
	return "%s: %s" % [message, found]
