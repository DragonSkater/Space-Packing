# game/launch

Launch resolution and the scorecard: applying findings to the packed hull and building the bill.

- `launch_record.gd`: one launch as `GameState` keeps it: its number, the round's name, the scheduled launch it flew, and the load exactly as committed (`core/packing/commit_record.gd`). The ship, bill and position in flight join it in milestones 5 to 7.
- `scheduled_launch.gd`: a placeholder upcoming launch (a scenario and a destination), listed on the overview. The contracts of milestone 6 replace it.

Owner: agents (code).
