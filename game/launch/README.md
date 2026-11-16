# game/launch

Launch resolution and the scorecard: applying findings to the packed hull and building the bill.

- `launch_record.gd`: one launch as `GameState` keeps it: its number, the round's name, the scheduled launch it flew, and the load exactly as committed (`core/packing/commit_record.gd`). The ship, bill and position in flight join it in milestones 5 to 7.
- `scheduled_launch.gd`: a placeholder upcoming launch, listed on the overview: a destination and either a ready-made scenario or a cargo stack flown in a named or player-picked ship. It builds the packing round for the chosen ship and compares its cargo with a hull. The contracts of milestone 6 replace it.

Owner: agents (code).
