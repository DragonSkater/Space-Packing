## Collects the errors the engine logs while a test runs, so that a script
## error inside a test fails that test instead of passing unnoticed. GDScript
## has no exceptions: a method that hits an error simply stops, and without
## this the runner could not tell. It collects errors only; warnings and
## ordinary printed messages are ignored.
class_name ErrorCatcher
extends Logger

var _errors: Array[String] = []
# The engine may log from a worker thread, for example while loading a scene.
var _lock: Mutex = Mutex.new()


## Returns the errors logged since the last call, and forgets them.
func take_errors() -> Array[String]:
	_lock.lock()
	var taken: Array[String] = _errors.duplicate()
	_errors.clear()
	_lock.unlock()
	return taken


func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
	if error_type == ERROR_TYPE_WARNING:
		return
	var text: String = code
	if not rationale.is_empty():
		text = rationale
	var entry: String = "engine error: %s (%s, %s:%d)" % [text, function, file, line]
	_lock.lock()
	_errors.append(entry)
	_lock.unlock()
