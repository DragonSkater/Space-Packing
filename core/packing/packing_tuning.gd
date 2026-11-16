## The numbers that price a round of packing: how many moves a round gets
## and what each loader action costs. PackingSession reads these at the
## moment it uses them, so a change takes effect on the next action. This
## file holds values only; no rule is decided here.
class_name PackingTuning
extends Resource

# Where to look
#   Values:     data/tuning/packing_tuning.tres
#   Read by:    core/packing/packing_session.gd -> pick_from_stack(), turn_held(), push_in(), shift(), turn(), unload(),
#               cost_of()
#               core/packing/packing_scenario.gd -> move_limit_with()
#   Tests:      tests/core/test_packing_session.gd

## Moves in a round when its scenario does not set its own. Placeholder.
@export_range(1, 99) var default_move_limit: int = 12
## Moves to bring an item from the stack to rest in the container.
@export_range(0, 10) var push_in_cost: int = 1
## Moves to slide an item already in the container to other cells of its
## row, whatever the distance.
@export_range(0, 10) var shift_cost: int = 1
## Moves for a quarter turn of an item inside the container.
@export_range(0, 10) var turn_cost: int = 1
## Moves for a quarter turn while the item is on the loader, outside.
@export_range(0, 10) var held_turn_cost: int = 1
## When on, a turn that leaves an item covering exactly the cells it did
## before costs nothing: a single-cell item, or a square one on the loader.
## Turning it still turns its picture. Off, every turn costs its full price.
@export var free_turn_when_unchanged: bool = true
## Moves to slide an item out through a door, back to the stack.
@export_range(0, 10) var unload_cost: int = 1
## How many items, counted from the top of the stack, can be taken.
@export_range(1, 8) var stack_pick_depth: int = 1
