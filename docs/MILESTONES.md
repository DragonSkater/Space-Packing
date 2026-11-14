# Space Packing — Milestones and Agent Briefs

**Status:** draft v5, 14 November 2026. Matches [PLAN.md](PLAN.md) v5. Open decisions there are assumed at their defaults; the last section of this file says which briefs each one touches.

## How to use this file

- One milestone is one agent session. Start it with:

  > Read `CLAUDE.md` and `docs/PLAN.md`. Then carry out milestone N from `docs/MILESTONES.md`. Stop when the definition of done in `CLAUDE.md` is met and give the report.

- Each brief is written to the implementing agent. "You" in a brief means the agent, except under "Your sanity check (designer)".
- After each milestone there is a **gate**: the designer runs the hands-on sanity check, which takes about five minutes, and either signs off or sends back notes. The next milestone does not start before the gate.
- **Every milestone ends with a fresh browser build, on this PC.** Run the web export command that milestone 0 adds to `CLAUDE.md`, load the result once from this machine, and report where the build is. Do not upload it anywhere, add a git remote, or push. The designer has deferred all of that (PLAN.md section 4.5) and will say when.
- Art can be dropped into the texture, pattern and icon slots at any point from milestone 2 onward. No milestone waits for art.
- Sizes are relative: **S** is a short session, **M** a full session, **L** a full session plus a round of fixes after the designer's check.

## Overview

| # | Milestone | Size | What the designer can do when it is finished |
|---|---|---|---|
| 0 | Foundation and browser pipeline | S | Open the project, press Play, run the tests, open a placeholder build in a browser on this PC |
| 1 | Packing core (logic only) | M | Read the rules of packing as tested code |
| 2 | Packing screen, greybox | L | Pack a ship by tap and swipe, in the editor and in the browser build |
| 3 | Levers | M | Change any packing number live; switch scenarios; see where a piece can go and why |
| 4 | Interactions and stats | M | See the interactions fire and the stats move; add an interaction from a data file |
| 5 | Ships and launch | M | Pack the named craft, read the bill on the launch screen, launch |
| | **Checkpoint: the packing demo is complete** | | |
| 6 | Overview and the three contracts | M | Take a contract to A, B or C, deliver, unlock the next craft |
| 7 | Distinct craft, greybox | M | Re-route P0-INT, deploy I0-N, park and tow T0-URIST |
| 8 | Presentation and delivery | M | A build that looks right on an iPhone, and a walkthrough script |

---

## Milestone 0 — Foundation and browser pipeline (S)

**Goal.** A project that opens cleanly, runs a placeholder screen in portrait, has a working test command, and can be exported to a browser build, so every later milestone can prove itself in a browser and the build is ready to upload the day the designer chooses.

**Before you start.** The web export templates are not installed on this machine: the export templates folder under the user's Godot data folder was empty on 14 November 2026. Ask the designer to install them from the editor (Editor, Manage Export Templates), or to let you download the official 4.7.2 template package. Do everything else in this brief while you wait.

**Build.**
1. Put the project under git (local only) with a `.gitignore` that excludes `.godot/`, `build/` and other export output. Make one initial commit of what exists now before changing anything. Do not add a remote and do not push; the repository stays on this PC.
2. Create the folder skeleton from PLAN.md section 4.3. Empty folders get a short `README.md` saying what belongs there and who owns it.
3. In `project.godot`: base viewport 402 x 874, portrait orientation, "emulate touch from mouse" on. Leave the existing stretch, renderer and physics settings alone. Do not delete `node_3d.tscn`.
4. A boot scene, `ui/boot/boot.tscn`, set as the main scene. It shows the game's name and the text "Milestone 0" in a centred column that stays 402 units wide however wide the window is. Nothing else.
5. The three autoloads from PLAN.md section 4.4, registered, each an empty script with its doc comment.
6. The test runner:
   - `tests/test_case.gd`: a base class with `assert_true`, `assert_eq`, `assert_almost_eq`, and a way to record a failure with a message.
   - `tests/test_runner.tscn` and `.gd`: finds every `tests/**/test_*.gd`, runs every method starting with `test_`, prints one line per failure and a final count, then quits with exit code 0 or 1.
7. Three standing tests:
   - `test_resources_load.gd`: every `.tscn` and `.tres` outside `addons/` loads without error.
   - `test_core_vocabulary.gd`: no file under `core/` contains the theme words listed in `CLAUDE.md`, matched case-insensitively, including inside identifiers such as `launch_cost`.
   - `test_sample.gd`: one trivial passing test, to prove the runner works.
8. The browser pipeline:
   - An export preset named `Web` in `export_presets.cfg`, writing to `build/web/index.html`. Check on the installed engine which renderer a web export uses and how thread support is switched off; the build must run from an ordinary static host with no special headers.
   - Add the export command to the commands list in `CLAUDE.md`, in the same style as the others, and say that you did.
   - Export, serve `build/web/` from a static file server that listens on this machine only (localhost), and load it in a desktop browser.

**Out of scope.** Any game logic. Any change to `art/`, `screens/` or `addons/`. Uploading the build anywhere. A git remote.

**Check before you report.** Temporarily make the sample test fail and confirm the exit code is 1 and the failure is printed. Restore it. Report the size of the web build and how long it took to appear in the browser.

**Your sanity check (designer).**
- Open the project in Godot: no errors in the Output panel.
- Press Play: the placeholder screen appears, upright.
- Run the test command from `CLAUDE.md`: it prints a pass count and no failures.
- `git log` shows two commits: the original state, and the foundation.
- Open the local web build in a desktop browser: an upright column in the middle of the window. Narrow the window to phone proportions: the placeholder should fill it with nothing cut off.

---

## Milestone 1 — Packing core, logic only (M)

**Goal.** The rules in PLAN.md sections 3.2 to 3.5 exist as plain, tested logic with no screen. This is the part most likely to be ported to another game, so clarity matters more here than anywhere else.

**Conventions.** A cell is a `Vector2i` with x as the column and y as the row, y increasing downward, (0, 0) at the top-left character of a layout text. A shape's cells are offsets from its origin and are kept normalised: smallest x is 0 and smallest y is 0. Items move along rows only, so a direction is `Vector2i.LEFT` or `Vector2i.RIGHT`. Everything in `core/` uses the neutral vocabulary from `CLAUDE.md`: container, item, door, loader, stack, move.

**Build.** All under `core/`. Signatures are the contract; private helpers are yours to design.

`core/grid/cell_shape.gd` — a set of cells.
```gdscript
class_name CellShape extends Resource
@export var cells: Array[Vector2i]
static func from_text(text: String) -> CellShape      # 'X' is a filled cell, anything else is empty
func normalised() -> CellShape
func rotated_clockwise() -> CellShape                 # result is normalised
func is_connected() -> bool                           # 4-neighbour connectivity
func bounds() -> Rect2i
```

`core/grid/layout_legend.gd` and `legend_entry.gd` — what each character in a layout text means. An entry has `symbol: String`, `passable: bool`, `storable: bool`, `tags: Array[StringName]`, and three fields that only screens read: `label: String`, `colour: Color`, `pattern: Texture2D`. A **door** is any cell that is passable and not storable. A space character, and anything beyond the edges of the text, is **outside**: passable, not storable, no tags.

`core/grid/container_layout.gd` — a parsed layout.
```gdscript
class_name ContainerLayout extends RefCounted
static func parse(text: String, legend: LayoutLegend, overlay_text: String = "") -> ContainerLayout
func size() -> Vector2i
func in_bounds(cell: Vector2i) -> bool
func is_storable(cell: Vector2i) -> bool
func is_passable(cell: Vector2i) -> bool              # true for outside cells
func is_door(cell: Vector2i) -> bool
func is_outside(cell: Vector2i) -> bool
func tags_at(cell: Vector2i) -> Array[StringName]
func entry_at(cell: Vector2i) -> LegendEntry
func cells_with_tag(tag: StringName) -> Array[Vector2i]
func storable_cells() -> Array[Vector2i]
```

The optional overlay is how a round marks designated cells on a container that is otherwise only a grid (PLAN.md section 3.5). It is a second text of the same size. Each of its characters other than `.` and space is looked up in the legend, and that entry's tags are added to the cell beneath. An overlay changes nothing else about a cell.

`core/grid/layout_validator.gd` — catches hand-authoring mistakes without getting in the designer's way. Every message is a plain sentence that names the column and row.
```gdscript
class_name LayoutValidator extends RefCounted
static func problems(layout: ContainerLayout) -> Array[String]    # the layout cannot be played at all
static func warnings(layout: ContainerLayout) -> Array[String]    # playable, but probably not intended
```
Problems, and only these: an unknown character; no storable cells; no door. Warnings: a storable cell with an outside cell directly beside it; a row of storable cells that no single-cell item could enter in an empty container; an overlay that is not the size of the layout, or that marks a cell which is not storable.

`core/packing/pack_item_type.gd` — a kind of item.
```gdscript
class_name PackItemType extends Resource
@export var id: StringName
@export var display_name: String
@export var tags: Array[StringName]
@export_multiline var shape_text: String = "X"        # any connected shape
@export var can_rotate: bool = true
@export var weight: float = 1.0                       # per item
@export var base_value: float                         # per item
@export var colour: Color
@export var texture: Texture2D
func shape() -> CellShape
func problems() -> Array[String]                      # an empty or unconnected shape
```

`core/packing/batch.gd` — several items of one type, listed together.
```gdscript
class_name Batch extends Resource
@export var item_type: PackItemType
@export_range(1, 32) var count: int = 1
@export var required: bool = true
```

`core/packing/pack_item.gd` — one item, whether it is on the stack, on the loader or in the container. It has a unique integer id that it keeps for the whole round, its `PackItemType`, its `CellShape` as it is currently turned, the index of the batch it came from, its origin (meaningful only inside the container), and `others_present_when_placed: int`, the number of other items that were in the container when it last entered.

`core/packing/pack_state.gd` — what is where inside the container. It knows nothing about doors, the stack or moves.
```gdscript
class_name PackState extends RefCounted
signal changed
var layout: ContainerLayout
func fits(shape: CellShape, origin: Vector2i, ignore_item_id: int = -1) -> bool   # all cells in bounds, storable, free
func place(item: PackItem, origin: Vector2i) -> void
func remove(item_id: int) -> PackItem
func move(item_id: int, shape: CellShape, origin: Vector2i) -> void               # used by shifting and turning
func item_at(cell: Vector2i) -> PackItem               # null when empty
func item_by_id(item_id: int) -> PackItem
func items() -> Array[PackItem]
func fill_ratio() -> float
```

`core/packing/access_solver.gd` — the loading rule from PLAN.md section 3.3 and the turning rule from section 3.4. State both in the class doc comment in container terms: "An item goes in and comes out in a straight line through a door. It may stop on any free cells along the way. It cannot pass through a wall or another item, and can leave only by sliding straight back out of a door."
```gdscript
class_name AccessSolver extends RefCounted
static func entry_lanes(state: PackState, shape: CellShape) -> Array[EntryLane]
static func shift_range(state: PackState, item_id: int) -> ShiftRange
static func blockers(state: PackState, item_id: int, direction: Vector2i) -> Array[int]
static func turn_option(state: PackState, item_id: int, grip: Vector2i, clockwise: bool) -> TurnOption
```
`EntryLane`, `ShiftRange` and `TurnOption` are small `RefCounted` classes, one file each. Definitions to implement exactly:
- A shape at an origin is **clear** when each of its cells is either outside, or passable and not occupied by another item.
- It is **at rest** when each of its cells is storable and free. This is `PackState.fits`.
- It is **fully outside** when all of its cells are outside the layout's bounding rectangle.
- A **slide** moves the whole shape one cell left or right. No turning.
- **Entry lanes.** For each side (left, right) and each row offset at which the shape would overlap the bounding rectangle: start fully outside on that side and slide inward one cell at a time while the next position is clear. Every position along the way where the shape is at rest is a **stop**. A lane with no stops is not offered. An `EntryLane` records the side, the row offset, the door cells crossed, the last fully-outside origin (where the loader holds the item) and its stops in order from the door inward.
- **Shift range.** For an item in the container, in each direction: slide it, ignoring itself, one cell at a time while the next position is clear. Each position where it is at rest is a stop. If the slide reaches fully outside, the item can leave on that side. A `ShiftRange` records the stops (not including where the item already is) and the sides it can leave by.
- **Blockers.** For one direction: the ids of the other items the item would overlap on its straight path out, up to the first impassable cell. An empty result with no exit on that side means a wall, not an item, is in the way.
- **Turn.** Refused (returns `null`) when the item's type has `can_rotate` off or when `grip` is not one of the item's cells. Otherwise each cell moves to `grip + R(cell - grip)`, where `R` is a quarter turn: clockwise maps an offset `(dx, dy)` to `(-dy, dx)`, anticlockwise to `(dy, -dx)`. The turn is offered only if the item is at rest in the new position, ignoring itself. Only the end position is tested; the swing between is not. A `TurnOption` records the new shape and origin.

`core/packing/packing_tuning.gd` — a `Resource` with `@export_range` fields and `##` descriptions: `default_move_limit`, `push_in_cost`, `shift_cost`, `turn_cost`, `held_turn_cost` (a turn while the item is on the loader outside the container), `unload_cost`, `stack_pick_depth`. Starter values: the limit is a placeholder for the designer; every cost is 1; the pick depth is 1.

`core/packing/packing_session.gd` — the controller for one round. The screen talks to this class and to nothing else in `core/`.
```gdscript
class_name PackingSession extends RefCounted
signal stack_changed
signal held_changed                                    # an item was taken onto, turned on, or put back from the loader
signal item_pushed_in(item: PackItem, lane: EntryLane)
signal item_shifted(item: PackItem, from_origin: Vector2i)
signal item_turned(item: PackItem)
signal item_unloaded(item: PackItem, direction: Vector2i)
signal action_refused(reason: StringName, item_ids: Array[int])   # &"no_moves", &"blocked", &"no_door", &"cannot_turn", &"not_reachable"
signal moves_changed(moves_left: int)
signal finished(reason: StringName)                    # &"committed"

func _init(layout: ContainerLayout, manifest: Array[Batch], tuning: PackingTuning, move_limit: int) -> void
func state() -> PackState
func stack() -> Array[PackItem]                        # top first
func held() -> PackItem                                # null when the loader is empty
func pick_from_stack(index_from_top: int) -> bool      # refused beyond stack_pick_depth, or when the loader is not empty
func put_back() -> void                                # the held item returns to the top of the stack, turned as it is
func turn_held(clockwise: bool) -> bool
func entry_lanes() -> Array[EntryLane]                 # for the held item, as it is currently turned
func push_in(lane: EntryLane, stop_index: int) -> bool
func shift_range(item_id: int) -> ShiftRange
func shift(item_id: int, origin: Vector2i) -> bool     # the origin must be one of the range's stops
func turn(item_id: int, grip: Vector2i, clockwise: bool) -> bool
func unload(item_id: int, direction: Vector2i) -> bool # on success the item goes to the top of the stack
func moves_left() -> int
func moves_used() -> int
func grant_moves(count: int) -> void
func required_items_left() -> int                      # items of required batches not in the container
func commit() -> void                                  # the player ends the round
```
Rules for the session:
- The stack is built from the manifest: the first batch's items are on top, each in the orientation drawn in its type's `shape_text`.
- Every successful `push_in`, `shift`, `turn`, `turn_held` and `unload` deducts its cost. An action that costs more than the moves left is refused with `&"no_moves"` and changes nothing. Picking, putting back and committing are free.
- A refused action never costs a move.
- `push_in` stamps the item's `others_present_when_placed`. `shift` and `turn` do not change it.
- Running out of moves does not end the round. `finished` is emitted only by `commit()`, and `commit()` is allowed at any time, whatever is left on the stack.
- Read tuning values at the moment they are used, never cached at construction, so that milestone 3 can change them mid-round.

**Out of scope.** Rules and findings, stats, anything visual, autoloads.

**Tests** (`tests/core/`). At least:
- Shapes: parsing; rotating four times returns the original; connectivity; an L shape.
- Layout: parsing with a test legend; tags; an overlay adds its tag to exactly the cells it marks and leaves them storable; a non-rectangular layout with outside cells inside its bounding rectangle; each validator problem and each warning, each triggered by a small layout.
- Batch: the stack holds `count` items per batch, first batch on top.
- Entry: a single-cell item in an empty row is offered every cell of the row as a stop, nearest the door first; with one item at the far wall the stops end in front of it; a full row offers no lane; a row split by a bulkhead offers one lane from each side; a two-row item is offered a lane only where two doors sit together, and its stops end where either row is blocked.
- Shift: an item with free cells on both sides has stops both ways; the item nearest the door can leave; the one behind it cannot, and `blockers` names the one in front; a two-row item is blocked by an item in either of its rows.
- Turn: the L-around-a-block example drawn in PLAN.md section 3.4 gives exactly that result; no turn into a wall, a door or an occupied cell; a turn about a cell that is not part of the item is refused; an item whose type cannot rotate is refused; an item turned across a row with no door cannot leave until turned back.
- Session: each action deducts its cost; a refused action costs nothing; an action is refused at zero moves; `push_in` with a lane or stop that is not currently offered is refused; only the top of the stack can be picked at depth 1, and the top two at depth 2; an unloaded item is on top of the stack and keeps its turn; `grant_moves` raises the moves left; `required_items_left` counts down.
- A fixture that uses van-and-pastry names, to show nothing in `core/` assumes a theme.

**Stop and ask if** a definition above produces a result that contradicts PLAN.md sections 3.3 to 3.5 for some layout.

**Your sanity check (designer).** There is nothing to play yet, so the check is a read-through:
- Open `core/packing/access_solver.gd`. The doc comment should state the loading rule as you understand it, and the code should be followable without running it.
- Open `tests/core/test_access_solver.gd`. Each test name should read as a statement about the game that you agree with.
- Run the tests.

---

## Milestone 2 — Packing screen, greybox (L)

**Goal.** A round of packing is playable with three gestures, in placeholder graphics, upright, in the editor and in the local browser build. The parts are those of `screens/cargo-loading-screen.png`, stacked for portrait as PLAN.md section 2 describes.

**Build.**
1. `core/packing/packing_scenario.gd`: a `Resource` describing a round: `display_name`, `layout_text` (multiline), `designation_text` (multiline, the optional overlay), `legend`, `manifest: Array[Batch]`, `move_limit` (zero means use the tuning default).
2. `Catalog` autoload: loads every resource under `data/` by folder and offers typed getters. Check on the installed engine how to list a `res://` folder so that it also works in an exported build, where resource file names can carry a `.remap` suffix. Prove it in the web build, not only in the editor.
3. `Tuning` autoload: loads `data/tuning/packing_tuning.tres` and `data/tuning/presentation.tres` and exposes them. Live editing comes in milestone 3.
4. `ui/common/presentation_tuning.gd` and its data file: spot size and its minimum, colours, animation durations, the top and bottom screen margins, and a Touch group: the distance a finger may move and still count as a tap, the distance at which a swipe's direction locks, and the minimum touch target.
5. `ui/common/gesture_reader.gd`: turns touch events inside a control into `tapped(position)`, `drag_started(position, axis)`, `drag_moved(offset)`, `drag_ended(offset)` and `swiped(direction)`. The axis locks to horizontal or vertical once the finger has travelled the lock distance. It decides nothing about the game.
6. `ui/common/grid_view.gd`: a reusable control that draws a grid of cells from a `ContainerLayout` and converts between screen positions and cells. Each cell is drawn from its legend entry: the pattern if one is assigned, otherwise the colour and label. The spot size is the largest that fits the space given, capped by `presentation.tres`.
7. `ui/packing/packing_screen.tscn`, a centred upright column:
   - **Top strip:** the scenario name, the moves left as a large number, and four stat slots. Only Weight is live for now, as the sum of loaded item weights; the other three show a dash.
   - **Middle:** the cargo stack on the left, drawn as a pile with the pickable piece raised; the gantry with a crane arm at every door; the container, with walls, doors, bulkheads, engines and designated spots as distinct placeholder colours. If the container has doors on both sides there is a gantry on each side.
   - **Bottom:** a Done button, and room for the CHECKS list that arrives in milestone 4.
8. Controls. This scheme is the designer's; where it left a gap the plan filled it with a default (D26 to D29), and the designer judges the whole at the gate:
   - **Tap the top piece of the stack:** the crane takes it and holds it outside the nearest door that offers a lane. Doors that offer a lane are lit; the rest are dimmed.
   - **Tap a lit door or its crane arm:** the held piece moves there. Free.
   - **Tap a piece in the container:** it is selected, and the spot that was tapped becomes the grip, drawn as a pin.
   - **Drag left or right,** starting anywhere in the middle area: the selected or held piece follows the finger along its row, snapping from stop to stop, and stays where it is released. Releasing where it started costs nothing. Dragging a loaded piece out past its door unloads it to the top of the stack. A drag that cannot begin (a wall, another piece) shakes the piece and briefly lights whatever is in the way.
   - **Swipe up or down:** a quarter turn of the selected or held piece. Down is clockwise. A turn that does not fit shakes the piece and costs nothing.
   - **Tap empty space:** deselect. A held piece goes back on the stack.
   - With no moves left, the moves number flashes on any attempt and nothing else happens.
   - Every touch target is at least the minimum in `presentation.tres` (44 units). Keep the drag area clear of the left and right screen edges, where a phone browser takes swipes for itself.
9. Example data, all named `example_*`: a legend (wall, cargo spot, door, bulkhead and engine, as in PLAN.md section 5, plus one overlay letter for designated spots); five item types: one spot, two spots, an L, a two-by-two, and a two-spot type that cannot rotate (for testing the switch only); two scenarios: a small container with doors on one side, and one with a bulkhead, doors on both sides, one row without a door, and one pair of doors a two-row piece can use. The second scenario marks four designated spots with its overlay, drawn but not yet judged.
10. The boot scene now opens the packing screen with the first scenario. Done and Restart are always available; finishing is never refused (PLAN.md section 3.5). Pressing Done shows a plain panel with the moves used, the number of required items left behind if there are any, and a Restart button. With no moves left the crane stops and the screen draws attention to Done and Restart. The launch screen replaces this panel in milestone 5.

**Out of scope.** Rules, the other three stats, ships, the tuning panel, art, sound.

**Tests.** `Catalog` finds the example data. Both example scenarios have no validator problems and their batches and item types have no problems. `GestureReader`, fed synthetic touch events, reports a tap, a horizontal drag and a vertical swipe correctly, and does not change axis once locked. The standing resource-load test covers the new scenes.

**Stop and ask if** the three gestures cannot be told apart reliably with this scheme, or if choosing a door by tapping cannot be made obvious.

**Your sanity check (designer).** On desktop with the mouse: in the editor, and in the local browser build with the window narrowed to phone proportions. A check on a real phone waits for the first upload.
- Load three pieces into one row, stopping the first one short of the back wall. Watch the moves count down by one each time.
- Tap the deepest piece and drag it toward the door. The pieces in front should light up and nothing should move.
- Drag the front piece out through its door. It should land on top of the stack, and the piece you had been about to load should now be under it.
- Load the L, stop it short of a single block, tap its foot and swipe down. It should hook over the block as in the plan's drawing.
- Turn a piece so that it sits across a row with no door, then try to drag it out. It should refuse until you turn it back.
- Take the two-by-two. Only the tall opening should be lit.
- Spend every move with a piece still on the stack. The crane should stop; the round should offer Done or Restart, not end by itself. Press Done anyway: it should go, and say what was left behind.
- Judge the gestures. **This is the moment to change the control scheme, the door choice (D27), the turning rule (D29) and the portrait layout (D40).**

---

## Milestone 3 — Levers (M)

**Goal.** The designer and the interviewer can change the game while it runs, switch between prepared situations, and see the reasoning behind what the screen allows.

**Build.**
1. `Tuning` autoload gains: a `value_changed(resource, property_name)` signal, `reset()` to the saved files, `differences()` listing each changed value with its saved and current value, and `save()` which writes back to `data/tuning/` and is available only when running from the editor.
2. `debug/tuning_panel/`: an overlay built by reading the exported properties of any `Resource` it is given. This is the one place where reflection is allowed.
   - A ranged number becomes a slider with a numeric field. A boolean becomes a checkbox. An enum becomes a dropdown. A colour becomes a colour button. A `StringName` or `String` becomes a text field.
   - `@export_group` names become collapsible sections. The property's `##` description becomes its caption.
   - A type the panel cannot edit is shown read-only with the note "edit in the Inspector".
   - Buttons: Reset, Show differences, Copy differences (puts them on the clipboard as plain text; check that this works in the web build), Save (editor only).
   - The panel must be usable at 402 units wide with a thumb.
3. A scenario picker and a Restart Round button in the same overlay, and a field that overrides the current round's move limit.
4. `debug/explain_overlay/`: layers that can be switched on over the container view:
   - zone tags, drawn as a small label in each tagged cell;
   - for the held piece, every lane and every stop;
   - for the selected loaded piece, its stops, the sides it can leave by, and the pieces in the way.
5. Two ways to open the overlay: a small corner button that is always visible, and the F1 key.
6. Make live changes take effect: presentation values redraw at once; packing values apply from the next action.

**Out of scope.** Rule editing (milestone 4).

**Tests.** The panel generator, given a small test resource with one field of each supported type, produces one editor of the expected kind per field. `differences()` is empty after `reset()`.

**Your sanity check (designer).**
- Open the panel mid-round and set the cost of a turn to 2. The next turn should take two moves.
- Raise `stack_pick_depth` to 2 and take the second piece from the top.
- Change the spot size. The grids should resize at once.
- Change three values, press Show differences, and confirm exactly those three are listed. Copy them and paste them somewhere. Press Reset.
- In `core/packing/packing_tuning.gd`, add one new exported number with a range. Run the game. It should appear in the panel without any other change.
- Switch scenario from the picker.
- Turn on the zone tag layer and check that the doors and engines are where the layout text says.
- Do the first three again in the local browser build.

---

## Milestone 4 — Interactions and stats (M)

**Goal.** The interactions from PLAN.md section 3.6 work, every rule is readable from the first second of a round, the Weight and Stability stats respond, and a new interaction can be added from a data file.

**Build.**
1. `core/rules/finding.gd`: the rule that produced it, item ids, cells, an effect (`DESTROY`, `DAMAGE`, `VALUE_BONUS`, `COST_CHANGE`, `EXTRA_MOVES`), a magnitude, and a message.
2. `core/rules/packing_rule.gd`: the base class.
   ```gdscript
   class_name PackingRule extends Resource
   @export var id: StringName
   @export var display_name: String
   @export var enabled: bool = true
   @export var effect: Finding.Effect
   @export var magnitude: float
   @export_multiline var summary: String                 # the rule as the player reads it before anything has gone wrong
   @export_multiline var message: String                 # when it fires; may contain {item}, {zone}, {other}, {amount}
   func evaluate(state: PackState) -> Array[Finding]     # overridden by each kind
   func concerns(item_type: PackItemType) -> bool        # true when this rule could ever apply to that type
   func unmet_requirements(state: PackState) -> Array[String]   # sentences for the player; empty unless a kind overrides it
   ```
   There is no switch to hide a rule from the player (PLAN.md section 3.6).
3. `core/rules/kinds/`, one file each. Put the EXTENSION POINT banner from `CLAUDE.md` in `core/rules/kinds/README.md` and above `PackingRule`.
   - `zone_proximity_rule.gd`: fields `item_tag`, `zone_tag`, `max_distance`, `include_diagonals`. One finding for each item carrying the tag that has a cell within the distance of a cell carrying the zone tag.
   - `item_pairing_rule.gd`: fields `item_tag`, `other_tag`, `must_touch`, `include_diagonals`. With `must_touch` on: one finding per touching pair, on any side. With it off: one finding per pair of item types, one carrying each tag, that are both in the container.
   - `designated_spot_rule.gd`: fields `item_tag`, `zone_tag`, `required`, `min_others_present`. A **designated area** is a group of cells carrying the zone tag that are connected to each other by their sides. An area is satisfied when every one of its cells is covered by an item carrying the item tag, each of those items lies wholly inside the area, and each has `others_present_when_placed` of at least the minimum. One finding per satisfied area, naming its items and cells. With `required` on, each area that is not satisfied adds a sentence to `unmet_requirements`. The cells normally get their zone tag from a round's overlay, not from the container's own layout. This is the only rule about placement; there is no formation rule (PLAN.md section 3.6).
4. `core/rules/rule_engine.gd`: runs every enabled rule and returns all findings.
5. `PackingScenario` gains `extra_rules: Array[PackingRule]`, in force for that round only, beside the rules in `data/rules/`. `PackingSession` gains `set_rules(rules: Array[PackingRule])`, `findings() -> Array[Finding]`, a `findings_changed` signal, and `unmet_requirements() -> Array[String]`: one sentence per required item still on the stack, followed by every rule's own. It re-evaluates after every change to the container. It grants the moves of an `EXTRA_MOVES` finding the first time that rule fires for that designated area, and never again for the same rule and area, even if the items are moved away and back.
6. `core/scoring/breakdown.gd`: an ordered list of lines (section, label, detail, amount, source) with a total.
7. `core/scoring/grade_scale.gd`: a `Resource` with `graded`, `higher_is_better` and three thresholds; `grade_for(value)` returns `GREAT`, `GOOD`, `BAD`, `TERRIBLE` or `NONE`.
8. `core/scoring/value_projector.gd`: given a `PackState` and the findings, returns a `Breakdown` of the value of the load as it stands: base values, then each value finding as its own line under the item it applies to. Define and document the order in which effects combine on one item: destroy overrides everything; damage fractions multiply; bonuses apply to what is left.
9. `game/stats/`: `stat_reading.gd` (name, value, unit, grade), and one small script per stat that returns a reading. Build two now: `weight_stat.gd` and `stability_stat.gd`, with the placeholder maths from PLAN.md section 3.7. Start each file's doc comment by saying that the formula is a placeholder and belongs to the designer. `game/stats/stats_tuning.gd` and its data file hold one `GradeScale` per stat and any coefficients. Weight's scale has `graded` off.
10. On the packing screen:
    - **CHECKS:** one row per enabled rule, always, showing its `summary`. Requirements come first and are labelled as required: required cargo not yet aboard, then required placements. A rule with nothing wrong shows a tick; a harmful finding shows a warning and its message; a bonus earned shows a star. Tapping a row highlights the cells of its findings, or, if it has none, the zone cells and item types it is about.
    - Selecting or holding a piece marks the CHECKS rows that concern its type and outlines the zone cells those rules name.
    - **STATS:** Weight and Stability live, each with its number and grade. Cost and Efficiency still show a dash.
    - A findings layer in the explain overlay.
    - The moves number jumps visibly when a bonus is granted.
11. In the debug overlay: a list of all rules, each with its enable switch and its fields editable through the same generated panel; the stats tuning.
12. Example data: tags on the example item types; one rule file each for vibration by the engines, radiation by the outer wall, bad neighbours, shared ride (pairing, not touching, a cost change), and, as `extra_rules` on a third scenario that marks the cells with its overlay, a designated bay of four spots that is required and a designated cradle that is optional and worth two moves once three other pieces are aboard. The third scenario is designed so that all six can be triggered.

**Out of scope.** Money, Cost and Efficiency, applying effects at launch (milestone 5). The release-depth rule (deferred).

**Tests.** For each kind: fires at the boundary, does not fire one step beyond it, ignores items without the tag, respects `enabled`. Pairing fires for a neighbour above and for one beside, and with `must_touch` off fires for two items far apart. The designated spot rule fires only when an area is filled exactly: not with one cell empty, not with an untagged item on one of its cells, not with a tagged item overhanging its edge. It fires for a four-cell area filled by four single items and by two two-cell items. It treats two separate areas separately and respects `min_others_present`. With `required` on it reports an unsatisfied area as unmet and a satisfied one as met; with it off it reports nothing unmet. The session's `unmet_requirements` also counts required items left on the stack. The session grants its moves exactly once across an unload and a reload. The effect-combination order. `GradeScale` at each threshold, both directions, and ungraded. Stability rises when a gap is closed. The van-and-pastry fixture runs a proximity rule with its own tag names.

**Stop and ask if** an interaction in PLAN.md section 3.6 cannot be expressed by these kinds without bending one of them.

**Your sanity check (designer).**
- Before touching anything, read CHECKS. You should be able to say what this round wants from you.
- Select the vibration-sensitive example on the stack. The rule about engines should be marked and the cells near the engines outlined.
- Load it into the bottom row, next to the engines. The check should fail with a readable sentence.
- Shift it away, or unload and reload it higher up. The check should tick.
- Trigger the radiation and bad-neighbour rules.
- Put three crates in the designated bay: CHECKS still shows the requirement as unmet. Add the fourth: it ticks. Swap one for a different kind of crate: unmet again.
- Put the cradle piece in its cradle too early and get nothing; do it after the required number of pieces and gain two moves. Unload and reload it: no second bonus.
- Pack loosely, then tightly, and watch Stability and its grade change.
- In the debug overlay, raise the proximity distance from 1 to 2 and watch a previously safe piece become unsafe.
- **The recipe test:** in the Godot editor, duplicate one rule file in `data/rules/`, change its tags to a new pair, and tag an item type to match. Run. The new interaction should appear in CHECKS with no code edited.
- **Judge whether packing is interesting enough.** If rows feel solved, this is the point to ask for more levers.

---

## Milestone 5 — Ships and launch (M)

**Goal.** The six named craft exist as editable data, and the launch screen shows the packed ship with its bill, a report card and an invoice, before the launch button is pressed.

**Build.**
1. `game/ships/ship_type.gd`, with the EXTENSION POINT banner. Fields, grouped with `@export_group`:
   - Identity: `id`, `display_name`, `role_label` (display only), `description`, `texture`.
   - Hull: `hull_layout_text` (multiline; empty for a craft with no hold), `legend`.
   - Costs and weight: `launch_cost`, `dry_weight`.
   - Flight: `cruise_speed_ls_per_hour`, `range_ls` (negative means unlimited).
   - Switches: `accepts_orders_in_space`, `requires_tow`, `can_tow`, `launched_by: ShipType` (empty means it launches itself), `spent_after_launch`.

   Give each field a `##` description in the designer's terms. Flight fields and switches are stored and shown now and take effect in milestones 6 and 7. No code anywhere may branch on `role_label` or on a ship's id.
2. `game/cargo/cargo_type.gd`: extends `PackItemType`, adding `deploys_ship: ShipType`. Migrate the example item types to it.
3. `game/launch/launch_scenario.gd`: a ship type, a cargo stack and a move limit. It produces the `PackingScenario` the packing screen already understands. The scenario picker lists these from now on.
4. `game/stats/cost_stat.gd` and `efficiency_stat.gd`, with the placeholder maths from PLAN.md section 3.7 and the same doc-comment opening as the other two. All four STATS slots on the packing screen are now live.
5. `game/launch/scorecard.gd`: the four stat readings, the moves used and allowed, a `Breakdown` with the sections Cargo, Cost and Contract, and the list of unmet requirements.
6. `game/launch/launch_resolver.gd`: takes the final `PackState`, the findings, the ship type and the session's move counts, and returns a per-item outcome list and a `Scorecard`. Every finding is applied here. Required items still on the stack are listed under Cargo as left behind, with no value. The Cost section is the launch cost followed by every `COST_CHANGE` finding. Grades and unused moves do not change any amount (PLAN.md section 3.7, D35).
7. The launch screen in `ui/reports/`, with the parts of `screens/routing-screen.png`, stacked for portrait. The packing screen's Done button opens it. There is no separate results screen.
   - the packed ship drawn exactly as it was left, read-only (the mockup's FIXED CARGO);
   - CHECKS, and TIME (the moves used);
   - **APPROVAL, which is the bill:** laid out as in PLAN.md section 3.7 with the report card above the invoice: each stat with its number and grade, each cargo item with its outcome and the sentence explaining it, the cost lines and the net. Unmet requirements are printed at its head;
   - the **star chart**, a fan-shaped panel that is decoration only: a texture slot in `presentation.tres`, with a drawn placeholder when it is empty. It shows no information and takes no input;
   - under it the **launch button**, a circle with an L, which commits the launch. It is never disabled;
   - a Back control that returns to packing with nothing lost.

   In this milestone pressing the launch button plays nothing more than a short acknowledgement and offers Replay and Next Scenario. Do not build the DEST / SUPPLY / RISK tabs.
8. A ship strip on the packing screen for choosing the ship in sandbox play, showing name, role label, launch cost and switch labels.
9. The six craft, as `data/ships/r0_ket.tres`, `p0_int.tres`, `t0_urist.tres`, `l0_ader.tres`, `t0_wer.tres` and `i0_n.tres`, with the switches from the table in PLAN.md section 3.8. Each has a simple starter outline (a rectangle, a stepped triangle, a square) and starter numbers, and its description says that the grid and every number are starter values for the designer to tune. Do not derive anything from `art/rockets.png`. Plus two special cargo types, `example_i0_n_crate` and `example_t0_wer_crate`, whose `deploys_ship` points at the craft.
10. Run `LayoutValidator` on every ship when `Catalog` loads. Show problems and warnings in the debug overlay and the console. Refuse to start a round only on a hull with problems. Warn when a hull would need spots smaller than the minimum in `presentation.tres` at the base resolution.

**Out of scope.** Space, contracts, towing and deployment behaviour.

**Tests.** Resolver arithmetic for each effect. A destroyed item contributes zero and is not also damaged. The Cost stat equals the sum of the invoice's Cost section with its sign reversed. Efficiency is cargo weight over dry weight. The scorecard's net equals the sum of its lines. All six craft load and have no validator problems. A ship added as a file appears in `Catalog`.

**Your sanity check (designer).**
- Pack the same stack into R0-KET and P0-INT and compare how the outline and doors change what you do.
- Finish loading with the vibration-sensitive item by the engines. The bill on the launch screen should show it ruined, with the reason, and the net should match the lines above it when you add them up. Go Back, move it, and see the bill change.
- Finish the scenario that has a required bay without filling it. The bill should say so at its head, and the launch button should still work.
- Pack two different kinds of cargo and find the shared-ride line under Cost.
- Open `game/stats/stability_stat.gd`. It should be short enough that replacing its maths is obviously a one-file job.
- **The recipe test:** duplicate a ship file, redraw its hull text with an extra door, run, and select it from the strip.
- Draw a hull with a gap in its wall. The game should warn, naming the cell, and still let you play it.
- **Start tuning the six cargo grids.**

### Checkpoint — the packing demo is complete

Tap, slide and turn; a stack and a move budget; interactions that are always readable; four stats; six editable craft; live levers; a result that explains itself; all of it online. Everything after this point is the space side.

---

## Milestone 6 — Overview and the three contracts (M)

**Goal.** The whole loop: the overview shows the map and the three contracts; take one, pack, read the bill, launch, watch the ship arrive, and unlock the next craft and the next contract.

**Build.**
1. `game/space/`: `body.gd` (id, name, kind, pad count, map position, texture), `space_link.gd` (two bodies, `distance_ls`), `space_map.gd` (bodies and links, and the shortest path between two bodies by total distance).
2. `game/space/travel_calculator.gd`: pure calculation. Given a ship type, a start body, a destination and the map, it returns the legs with their distances and travel times, or the reason the trip is impossible: no path, or out of range. Put a comment at the top naming this as the place where slingshots and ageing attach later (PLAN.md section 3.9), and build neither.
3. `game/space/space_tuning.gd` and its data file: `seconds_per_game_hour`. Add it to the tuning panel.
4. `game/contracts/contract.gd`: `id`, `display_name`, `destination`, `manifest: Array[Batch]` (top of the stack first), `move_limit`, `reward`, `requires_completed: Array[Contract]`, `unlocks_ships: Array[ShipType]`, and for special contracts `designation_ship: ShipType`, `designation_text` (multiline) and `placement_rules: Array[PackingRule]`. A contract with a `designation_ship` is flown with that ship only (PLAN.md section 3.5, D43). The contract produces the `PackingScenario` for its round, passing the designation text as the overlay and the placement rules as extra rules.
5. `GameState`: earnings, unlocked ship types (R0-KET at the start), completed contracts, the fleet (each launched ship with its type, scorecard, state and position), and the game clock with pause and a fast-forward factor.
6. The overview screen in `ui/overview/`. It is also the contract screen; there is no other. Upright, with the parts of `screens/overview-screen.png`: bodies at their map positions, dashed links labelled with their distance, numbered pads on the home body, fleet markers moving in game time, and a contract card on each destination that has one. A card shows whether its contract is open, locked behind an earlier one, or fulfilled, and after a launch that missed its requirements it says which ones. A strip shows the unlocked craft and the earnings.
7. The flow: on the overview, tap an open contract card; choose an unlocked craft that has a hull, unless the contract names its ship; pack; the launch screen; back to the overview with the ship in transit from the next free pad. The player does not choose a pad.
8. The launch screen from milestone 5 gains the contract: the destination and the travel time under TIME, and the Contract section of the bill, which reads "paid on arrival" with the reward, or "not fulfilled" when a requirement was missed. The star chart stays decoration. The launch button now sends the ship.
9. A contract is fulfilled only by a ship that had no unmet requirements at launch. When such a ship arrives: the contract's reward is paid, its bill's contract line changes from "paid on arrival" to paid, earnings are added, the contract is marked complete, and what it unlocks is announced. A ship that missed a requirement still flies, arrives and stays on the map. Its contract's card says at once which requirements were missed, the contract stays open with its full stack to try again, and nothing that depends on it opens.
10. Data. The bodies and contracts are the designer's by name; every distance, reward, stack and move limit in them is a starter value and says so.
    - A map with home (three pads), Planet A, Asteroid B, Satellite C and a station (one pad, not used by any contract).
    - Exactly three contracts, played in order (D36): to Planet A, unlocking P0-INT; to Asteroid B, which requires the first and unlocks I0-N; to Satellite C, which requires the second and unlocks T0-URIST, L0-ADER and T0-WER. All three are on the overview from the start. As starter content the first is plain, the second requires one awkward piece of cargo to be fitted, and the third designates a location on R0-KET's grid.
    - A completed contract stays on the overview, marked done, and can be flown again. It pays again and unlocks nothing new.
11. The debug overlay gains: unlock everything, complete a contract instantly, and reset progress.

**Out of scope.** Re-routing, towing and deployment (milestone 7). Launching from the station. Everything on the deferred list in PLAN.md section 1.

**Tests.** Travel time is distance over speed, summed over legs. Shortest path. Out-of-range is reported. Completing a contract unlocks its ships exactly once. Flying it again pays and unlocks nothing. A launch with an unmet requirement is allowed, and its arrival neither pays the reward nor fulfils the contract nor opens the next one. A contract's designation text reaches the layout as an overlay, and a contract with a `designation_ship` refuses other ships. `Catalog` holds exactly three contracts, and each unlocks what PLAN.md section 3.9 says.

**Your sanity check (designer).**
- Open the game. The overview should show the map and three contracts, the first open and the other two visibly waiting, and nothing else to choose from.
- Play the Planet A contract start to finish without the debug overlay, and see P0-INT unlock.
- On the launch screen, check that the ship drawn is the one you packed and that the bill names the destination. Go Back, move one piece, and return. Launch with the round L button.
- Launch a contract with a requirement missed. The bill should say which, the ship should still fly, the contract's card should say what was missed, and the next contract should still be waiting.
- Fast-forward a ship in transit.
- Change one link's distance in its data file and see the label and the travel time follow.
- **The recipe test:** duplicate a contract file, point it at a different body, make it unlock a different ship, and redraw its designated spots somewhere else on the grid. Run and complete it. Then delete it, so that there are three again.
- Time yourself from the first tap to the first delivery, and say whether it is too long.

---

## Milestone 7 — Distinct craft, greybox (M)

**Before starting, ask the designer about D36 and D38 in PLAN.md.** The brief below assumes their defaults: the carried craft and the detachable system are shown through debug scenarios, not through new contracts. The designer has said this part does not have to be perfect. Build the plainest version that makes each craft behave differently.

**Goal.** The switches on ship types take effect in space.

**Build.**
1. `game/space/orders.gd`: the single place that decides what a ship may be told to do, from its switches and its state. Every order is refused with a readable reason when it is not allowed.
2. **Re-routing.** On the overview, tapping a ship that has arrived and has `accepts_orders_in_space` offers a Move order: tap a destination, see the travel time and the range that would remain, confirm. A ship's remaining range falls by the distance it travels; a negative `range_ls` never runs out. A ship without the switch shows why it cannot be ordered.
3. **Launchers.** A ship type with `launched_by` set is launched on that launcher: the launch uses the launcher's cost, speed and range, and on the launch screen the player picks where the hull is to be left, from the bodies within the launcher's range. On arrival the hull is in orbit there in a visible "awaiting tow" state, and a launcher with `spent_after_launch` is removed. A contract carried by such a hull is not delivered until the hull reaches the contract's destination.
4. **Towing.** A ship with `can_tow` that takes orders is offered a Tow order: tap a waiting hull, then a destination. The waiting hull is itself the first destination. The tug travels to it, attaches, and carries it at its own speed times `tow_speed_factor` (a new field in `space_tuning`). On arrival the hull's cargo is delivered. One hull at a time.
5. **Deployment.** When a ship arrives carrying cargo whose type has `deploys_ship`, a new ship of that type joins the fleet in orbit at that body at once. A cargo item that was destroyed deploys nothing.
6. A craft with an empty hull layout cannot be chosen for a contract and is never sent to the packing screen.
7. Debug scenarios, selectable from the overlay, that set the fleet up to show each behaviour: a P0-INT already arrived at Planet A; an R0-KET carrying an I0-N crate, about to arrive; a T0-URIST parked at Asteroid B with a T0-WER nearby.
8. The debug overlay gains: spawn any ship type at any body.

**Out of scope.** Tow chains, multiple hulls per tug, refuelling, cargo transfer between ships, hulls left at free points in space, new contracts.

**Tests.** Each order is allowed and refused in the right cases, with the reason. Range is consumed, and never for unlimited ships. A launched hull stops where it was sent and does not deliver until towed to its destination. A spent launcher is gone. Tow speed uses the factor. Deployment creates exactly one ship, at once, and none for destroyed cargo.

**Stop and ask if** an order's rule is not determined by PLAN.md section 3.8.

**Your sanity check (designer).**
- Launch R0-KET and try to re-route it. The game should say why it cannot.
- From the debug scenario, re-route P0-INT twice and run it out of range.
- From the debug scenario, let the R0-KET arrive. I0-N should appear as its own ship at once.
- From the debug scenario, order T0-WER to tow the parked T0-URIST to Satellite C.
- **The recipe test:** in `p0_int.tres`, switch on `can_tow`, and tow a hull with it. No code edited. Switch it back off.

---

## Milestone 8 — Presentation and delivery (M)

**Goal.** The browser build looks right on an iPhone held upright, feels responsive, and there is a script for showing it.

**Build.**
1. Assign any designer textures not yet assigned: cargo, ships, bodies, zone patterns on the legend, icons on the tag styles. Apply the designer's theme. Do not create art.
2. `data/tags/`: a tag style file for every tag used by the example cargo, each with a display name, a glyph and a colour, so that a piece shows what it is sensitive to. Icons stay empty until the designer supplies them.
3. Feedback: the slide, a snap on landing, the turn, a shake on a refused action, the moves number ticking, a short launch sequence, and transitions between screens. Every duration goes in `presentation.tres`.
4. Sound slots on the same events, silent until files are assigned.
5. The web build, checked against this list: nothing under the notch or the home bar, touch targets, the three gestures against the browser's own, start-up time, frame rate. On an iPhone in Safari if the designer has uploaded a build by now (PLAN.md section 4.5); otherwise in a desktop browser at phone proportions, with the phone check reported as outstanding. Fix what the margins and touch tunables can fix; report the rest.
6. `docs/WALKTHROUGH.md`: a five-minute demo script and a ten-minute code tour, pointing at the two EXTENSION POINT banners, the tuning scripts, the four stat scripts, `access_solver.gd`, and one test file.

**Out of scope.** Native iOS and Android builds.

**Your sanity check (designer).** Upload the build where you have chosen, open it on your own phone first, then send the link to someone who has not seen the game, with no explanation, and watch the first two minutes.

---

## If an open decision in PLAN.md changes

| Decision | Briefs affected |
|---|---|
| D13 Dialogue Manager | None until it has a role. |
| D16 project name | Milestone 0, item 3; it is also the browser tab's title. |
| D26 what one move is | Starter values in `packing_tuning` only, unless a move is to be counted per spot travelled; then milestone 1 (`shift` and `push_in` costs). |
| D27 choosing a door | Milestone 2, item 8. |
| D28 stack access | A starter value only. |
| D29 how a piece turns | Milestone 1 (`turn_option`), milestone 2 (the grip pin, swipe directions). |
| D32 bonus moves kept | Milestone 4, item 5. |
| D33 what Weight is | Milestone 4, item 9 (`weight_stat.gd` and its scale). |
| D34 "together" | One switch on one example rule file. |
| D35 grades and money | Milestone 5, item 6. |
| D36 contract order, replay, use of carried craft | Milestone 6, item 10 (`requires_completed` on the second and third contracts); milestone 7 (scenarios, or contracts instead). |
| D38 roster details | Milestone 5, item 9; milestone 7, items 3 to 5. |
| D40 portrait layout | Milestone 2, item 7. |
| D43 how a contract points at a location | Milestone 6, item 4 (`designation_ship`), and item 10. |
