# Space Packing — standing instructions for agents

A Godot 4.7.2 demo of a cargo-packing game: the player pushes cargo into the rows of a ship's hull through side doors, where loading order matters, then launches and directs the ship through space. It is an interview piece, so the code will be read by a stranger and must explain itself.

Read `docs/PLAN.md` before any task. It is the specification. `docs/MILESTONES.md` holds the brief for each milestone. Work on one milestone at a time and only on what its brief lists.

## Ownership

The user owns the game design, the art, and all progression content and balance numbers. You own the code.

- Never edit anything in `art/` or `screens/`.
- Never change the value of an existing field in `data/`. If a value looks wrong, say so in your report.
- You may add new files to `data/`. Name placeholder content `example_*` so the user knows it is theirs to replace. The exception is content the user has named: the six craft, the three contracts and the bodies in `docs/PLAN.md` are filed under the user's names (`r0_ket.tres`), with a description saying which of their values are starter values.
- Never touch `addons/dialogue_manager/`.
- If a rule in `docs/PLAN.md` is ambiguous, contradictory, or seems wrong, stop and ask. Do not fill the gap with your own design.

## Local only

Everything stays on this PC until the user says otherwise. The git repository has no remote: do not add one and do not push. Do not upload a build anywhere. When you serve the browser build to test it, serve it to this machine only.

## Layers

```
ui/, debug/  ->  game/  ->  core/        data/ is read by all three
```

- Dependencies point in the direction of the arrows only.
- `core/` is the portable packing engine. It must not contain the words ship, rocket, cargo, hull, launch or planet, as whole words or as parts of identifiers, in code or comments. Use container, item, zone, door, loader, rule, finding, commit, dispatch, delivery. Classes in `core/` extend `RefCounted` or `Resource`, never `Node`.
- A screen never changes game state itself. It calls its controller (for example `PackingSession`) and redraws on that controller's signals.
- Autoloads are `Catalog`, `Tuning` and `GameState` only. Do not add another without asking. `core/` does not use autoloads.

## Code style

- GDScript with static types everywhere: every variable, parameter and return type.
- Every script starts with a `##` doc comment of two to five lines that says, in plain English, what the class is for and what it is not responsible for.
- One class per file, named after the class in snake_case. Aim for under 200 lines; split by responsibility when a file grows past that.
- No balance, timing or layout literals in code. Put them in a tuning resource script (a `*_tuning.gd` file beside the code that uses it) with `@export_range` and a `##` description, so the debug panel can show them.
- Tags (`engine`, `vibration_sensitive`) are `StringName` values that live in data. Never hard-code a tag name in a script.
- Prefer a plain loop and a named helper over a clever expression. No reflection or metaprogramming outside `debug/tuning_panel`.
- Signals travel up, calls travel down. Name signals in the past tense (`piece_placed`).
- Mark the two progression systems so they can be found by search. Put this banner above the relevant class or folder entry point, and nowhere else:

  ```gdscript
  # ============================================================
  # EXTENSION POINT: <interactions | ships>
  # To add one: <the recipe from docs/PLAN.md section 7>
  # ============================================================
  ```

- Comments explain why, or state a rule from the plan with its section number. Do not narrate what the next line does.

## Scenes and resources

- Scenes hold layout; scripts hold behaviour. Keep `.tscn` files small and flat.
- Everything the user might restyle goes through the theme, `presentation.tres`, or a texture slot on a resource. When a texture slot is empty, draw a coloured labelled placeholder.
- After writing or editing any `.tscn` or `.tres` by hand, prove it loads by running the import and test commands below.

## Godot 4.7.2

Your memory of the Godot API may be older than this engine. When you are unsure of a class, method or annotation, check the installed engine before writing code that depends on it, for example by dumping the class reference with `--doctool` into the scratch directory and searching it.

The engine is not on PATH. On this machine it is:

```
C:\Users\sahai\Downloads\Godot_v4.7.2-stable_win64.exe\Godot_v4.7.2-stable_win64_console.exe
```

Commands, run from the project root (`$GODOT` stands for the path above):

```
$GODOT --headless --path . --import                         # refresh the class cache; run after adding scripts or resources
$GODOT --headless --path . res://tests/test_runner.tscn     # run all tests; exit code 0 means pass
$GODOT --path .                                             # launch the game
```

Milestone 0 creates the test runner. If one of these commands does not behave as described on 4.7.2, fix the command in this file as part of your work and say so.

## Definition of done

A milestone is done when all of these are true:

1. Everything listed under "Build" in its brief exists, and nothing outside its scope was changed.
2. The import command prints no errors and no script warnings from files you wrote.
3. The test command exits 0, and the tests listed in the brief exist.
4. You launched the game and performed the brief's sanity checks yourself as far as a non-interactive run allows.
5. The recipes in `docs/PLAN.md` section 7 still hold.

## Report

End every milestone with a report in this shape:

- **Built:** the files added or changed, one line each.
- **Verified:** the commands you ran and their real output, including failures.
- **Not verified:** anything you could not check, such as touch feel, and why.
- **Deviations:** anywhere you departed from the brief or the plan, and the reason.
- **Questions:** design questions that came up. Do not answer them yourself.
- **Tunables added:** name, default, and what it does.

If a test fails or a check could not be run, say so plainly. Do not describe work as complete when it is partly complete.
