# data/launches

Upcoming launches shown on the overview: each is a packing round (a scenario) and the body the packed ship flies to. They are placeholders for the three contracts of milestone 6, which will replace this folder.

A launch either plays a ready-made scenario (`scenario`, hull included), or carries its own cargo stack (`manifest`, top first) and moves (`move_limit`) and is flown in a ship. If it names a `ship`, that ship is used, and only then may it draw `designation_text` over that ship's hull (PLAN.md D43). Otherwise the player picks a ship on the overview; every ship can be picked, and the picker warns when the stack's spots and the hull's spots differ. `example_launch_04_full_hold` (28 spots) and `example_launch_05_small_load` (12 spots) work this way and are open from the start.

A launch opens when the one named in its `requires` field has been flown with no required cargo left behind. The overview lists them in file-name order.

Owner: the designer. Every file here is an agent's placeholder named `example_*`.
