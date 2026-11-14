## One trivial test, kept to prove that the runner finds a file, calls its
## test methods and reports the result. It tests nothing about the game.
extends TestCase


func test_the_runner_runs_a_test() -> void:
	assert_true(true, "true is true")
	assert_eq(1 + 1, 2, "integer addition")
	assert_almost_eq(0.1 + 0.2, 0.3, DEFAULT_TOLERANCE, "float addition")
