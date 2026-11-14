# Space Packing — Implementation Plan

**Status:** draft v5, 14 November 2026. Includes the designer's answers from five clarification rounds. The third ("Plan Clarifications") changed the controls, the timer, the stats, the roster, the screen orientation and the delivery target; the fourth settled the bonus, running out of moves, the launch screen, and keeping everything on this PC; the fifth put designated spots on the contract and made the launch screen the bill. Nothing is built yet.
**Companion files:** [MILESTONES.md](MILESTONES.md) (build order, agent briefs, sanity checks) and [../CLAUDE.md](../CLAUDE.md) (standing rules for every agent working in this repo).

Items marked **[DECIDE Dn]** are still yours to settle. Each has a default that the plan assumes, so the plan is complete as written. Section 10 lists every decision, settled and open, and says which open ones block which milestone.

---

## 1. What the demo has to prove

In priority order:

1. **Packing is the game.** One mechanic, the loading crane, does everything: tap a cargo piece to select it, swipe left or right to move it along its row, swipe up or down to turn it. Where a piece goes, and what order pieces go in, is readable and satisfying on a phone.
2. **Complexity is data.** A new cargo type, a new cargo interaction, or a new ship is added by creating a resource file, not by editing game code.
3. **Ships are easy to edit, and feel distinct.** Each of the six named craft is one data file whose role, cost and hull grid can be changed without code.
4. **Every number is a lever.** Move costs, bonuses, penalties, grade boundaries, distances and speeds can be changed live inside the running demo, and every score explains itself line by line.
5. **A small loop closes.** Three contracts, to Planet A, Asteroid B and Satellite C. Each delivery unlocks the next kind of craft.
6. **It runs in a browser.** A browser build is made and loaded on this PC from the first milestone and refreshed at every gate, so it is ready to go online the day you say. Working, tested systems come first; nothing is uploaded until part of it works and you choose where.

### In scope and deferred

| In the demo | Deferred (designed for, not built) |
|---|---|
| Touch packing with the crane: select, slide, turn | A separate holding area (for Tower-of-Hanoi style contracts) |
| A cargo stack and a budget of moves | A real-time clock while packing |
| Cargo interactions: vibration, radiation, bad neighbours | The satellite release-depth rule |
| Designated spots that pay a bonus, in value or in extra moves | Cargo that may not be turned (the field exists; no demo cargo uses it) |
| Four stats with grades: weight, stability, cost, efficiency | The exact maths behind the stats, and how grades pay out |
| The six named craft, each one editable data file | Ship upgrades; buying ships with money |
| Exactly three contracts, shown on the overview screen | Contract deadlines, optional cargo, risk; the DEST / SUPPLY / RISK tabs |
| A basic map: home, Planet A, Asteroid B, Satellite C, a station | Launching from the station; free-floating targets in space |
| Re-routing, towing and deploying, as greybox | Slingshots, gravity as time, cargo ageing, mining, building in space |
| Tuning panel, explain overlay, report card and invoice | Saving between sessions |
| Launching or restarting when the moves run out | Bad launches crowding out space |
| Contracts with requirements: fit this cargo, place that cargo here | Contracts spread over several launches; collecting cargo already in space |
| A browser build that looks right on an iPhone held upright | Native iOS and Android apps; uploading, until you say |
| Your art, icons and zone patterns, dropped into slots as you draw them | |

Section 3.9 says where each deferred system would attach, so that leaving it out now does not mean rewriting later.

### Who owns what

| You own | Agents own |
|---|---|
| Art and graphics (`art/`, textures, the UI theme, tag icons, zone patterns) | Code in `core/`, `game/`, `ui/`, `debug/`, `tests/` |
| Overarching game logic: the rules in section 3 of this document | Implementing those rules exactly as written here |
| Progression content: cargo types, the six craft and their hull grids, bodies, routes, the three contracts (`data/`) | Starter files for the content you have named, and placeholder content named `example_*` for the rest |
| All balance numbers and stat maths (`data/tuning/`, `game/stats/`) | Starter values and placeholder formulas only, never silently changing one you have tuned |

The six craft, the three contracts and the bodies are yours by name, so their files carry your names (`r0_ket.tres`, not `example_rocket.tres`). You have approved this exception to the `example_*` rule, and `CLAUDE.md` records it. Every number and grid inside them is a starter value and says so in the file's description. Cargo types, rules and test scenarios that agents invent are named `example_*`.

If an agent thinks a rule in this document is wrong or incomplete, it stops and asks. It does not redesign.

---

## 2. How I read your mockups

The three mockups are drawn landscape. The game is now portrait (section 4.5), so each screen keeps the mockup's parts and stacks them top to bottom. **[DECIDE D40]** The stacking below is my proposal; it is judged at the milestone 2 gate.

**`screens/cargo-loading-screen.png` — the packing screen**
- **CARGO**: the cargo stack. Only the top piece can be taken. Unloaded pieces come back to the top.
- Centre: the pad, with a gantry beside the hull. The crane arms on the gantry are the **crane**; one arm is drawn at each door, and the active one holds the selected piece.
- **STATS**: four readouts, **Weight, Stability, Cost, Efficiency**, each a number and a grade (great, good, bad, terrible). The moves left are shown separately, next to the crane.
- Portrait stacking: a top strip with the contract name, the moves left and the four stats; the hull, gantry and stack in the middle; the CHECKS list and the Done button, which leads to the launch screen, at the bottom, in thumb reach.

**`screens/routing-screen.png` — the launch screen**
- **FIXED CARGO**: the ship exactly as you packed it. The load is now fixed; this is a picture of what is about to launch, not a list of requirements.
- The fan-shaped panel is a **star chart**. It is decoration: a picture slot, with no information in it and nothing to tap.
- The circle with an L in it, underneath, is the **launch button**. Pressing it commits the launch.
- **CHECKS** (the rule results) and **TIME** (moves used and travel time).
- **APPROVAL** is the bill: the report card and the invoice of section 3.7, read before the button is pressed. There is no separate results screen after launch.
- The DEST / SUPPLY / RISK tabs are deferred.

**`screens/overview-screen.png` — the overview, which is also the contract screen**
- One screen, not two. The map shows home with its numbered pads, dashed routes with distances in light-seconds, Planet A, Asteroid B, Satellite C and the station. I take the station with a launch pad to be the disc on a stalk at the top of this mockup; it is on the map with one pad, and launching from it is deferred.
- The three contracts are shown here from the start, each attached to its destination.
- Launched ships appear on the map and can be given orders here.

**`art/rockets.png` — the roster**

| Craft | Your description | Sketch I take it to be |
|---|---|---|
| **R0-KET** | single launch | the red rocket |
| **P0-INT** | post-launch steering | the blue triangle |
| **T0-WER** | towing machine | the grey craft with the hook |
| **T0-URIST** | the loaded cargo mechanism | one of the two teal hulls **[DECIDE D38]** |
| **L0-ADER** | the disposable launcher | the booster under the small teal hull **[DECIDE D38]** |
| **I0-N** | the ion launcher | the green craft |

Only these six are built. Nothing is derived from the sketches: each craft gets a simple starter outline (a rectangle, a stepped triangle, a square) and a starter cargo grid for you to tune. The windows and the `s / m / L / T` labels remain art.

---

## 3. The rules of the game

This section is the specification. Code implements it; it is the part you own.

### 3.1 Vocabulary

| Term | Meaning |
|---|---|
| **Hull** | The grid of spots inside a ship where cargo can rest. |
| **Spot** | One cell of the hull grid. |
| **Zone tag** | A label on a hull cell, such as `engine`, `hull` (outer wall) or `door`. Tags are plain names defined in data, so new ones need no code. Each zone is drawn with its own colour and pattern. |
| **Door** | An opening in the side of the hull. Each door serves the row of spots behind it. |
| **Crane** | The loading arm on the gantry. It is the only thing that touches cargo: it loads, slides, turns and unloads. |
| **Piece** | One unit of cargo. Its shape is any connected group of spots: one, two in a line, an L, a 2 by 2 block. |
| **Stack** | The pile of pieces waiting to be loaded. Only the top piece can be taken. |
| **Move** | One crane action. A round has a limited number of moves; this is the launch window. |
| **Batch** | Several pieces of one cargo type, listed together in a contract. |
| **Designated spot** | Cargo spots that a contract marks, on a ship's grid, for a particular kind of cargo. |
| **Requirement** | Something a contract insists on: this cargo aboard, or that cargo in its designated spots. |
| **Finding** | One result of one interaction rule: which cargo, what happens to it, and why. |
| **Grade** | Great, good, bad or terrible: the bucket a stat's number falls into. |

### 3.2 A packing round

1. A round starts with a ship on the pad, a cargo stack, and a number of moves.
2. The player **taps a piece** to select it: the top piece of the stack, or any piece already in the hull. The crane takes hold of it.
3. A piece taken from the stack is held outside a door. Tapping another door holds it there instead. **[DECIDE D27]**
4. **Swipe left or right** to slide the selected piece along its row. It follows the finger and stays on the spots where it is released. It cannot pass through a wall or another piece.
5. **Swipe up or down** to turn the selected piece a quarter turn.
6. Sliding a loaded piece back out through a door unloads it. It returns to the top of the stack.
7. Each crane action costs a move (section 3.5). When no moves are left the crane stops.
8. Throughout, the **CHECKS** list shows every rule in force, satisfied or not, and the **STATS** update. The player can always see what the packing is being judged on.
9. When the player is done loading, the launch screen shows the packed ship and the bill: a report card and an invoice (section 3.7). The launch button commits it.

There is no separate re-packing mode and no unload button. Changing your mind is done with the same crane, and it costs moves.

### 3.3 The loading rule: why order matters

> **Cargo goes in and comes out in a straight line through a door.** The crane slides a piece along its row. The piece may stop on any free spots along the way. It cannot pass through a wall or through other cargo, and it can leave only by sliding straight back out of a door, so everything between it and the door has to move first.

What follows from this rule:

- **Last in, first out, per row.** A piece deep in a row is buried by everything loaded after it.
- **Re-packing is a hassle by construction.** Reaching a buried piece means unloading each piece in front of it. Every one of those is a move, and every unloaded piece lands on top of the stack, in the way of whatever you meant to load next.
- **Stopping short is a choice.** A piece does not have to slide to the back. Leaving a gap behind it is sometimes a mistake and sometimes the plan: the gap is room to turn a piece, or a place a later rule wants kept clear.
- **A piece that spans two rows needs both rows clear**, and needs two doors that sit together to get in or out at all.
- **Doors are a ship stat.** Which rows have doors, whether the ship has doors on both sides, and where two doors sit together are all part of a hull's design.

Pieces move along rows only. There is no gravity inside the hull, and nothing moves unless the crane moves it.

### 3.4 Pieces: shapes and turning

A piece's shape is drawn as text in its cargo type: `X` for one spot, `XX` for two, or a larger drawing such as an L or a 2 by 2 block.

**Turning.** The crane can turn any piece a quarter turn, on the stack side of the door or inside the hull, at any depth.

- Outside the hull a turn always fits.
- Inside the hull the piece turns about the spot the crane is gripping, which is the spot the player tapped. The turn is allowed when every spot the piece would cover afterwards is a free cargo spot. The piece stays whole and never overlaps a wall or other cargo. **[DECIDE D29]**
- A turn costs a move.
- A turned piece that no longer lines up with a door has to be turned back before it can leave. Getting it out is its own hassle.

```
Before: an L stopped short of a block B.     After one turn about the gripped spot (*):
                                             the L hooks over the block.
  D . L . . #                                  D . . L L #
  D . L * B #                                  D . . * B #
```

A cargo type has a `can_rotate` switch for special cargo that may not be turned. It is on for all demo cargo; no-turn cargo is deferred.

### 3.5 The cargo stack and moves

**The stack.** A contract lists its cargo from the top of the stack down. The player takes the top piece, places it, and the next one becomes available. An unloaded piece goes back on top, still turned the way it was. The stack and the ship are all the space the player gets; there is no holding area. **[DECIDE D28]** A tunable, `stack_pick_depth`, says how many pieces from the top can be taken. It is 1.

**Moves.** The launch window is a number of moves, set per contract. **[DECIDE D26]** By default one completed crane action is one move, and each cost is a tunable:

| Action | Moves |
|---|---|
| Load: a piece from the stack comes to rest in the hull | 1 |
| Shift: a loaded piece slides to different spots in its row, any distance | 1 |
| Turn: a quarter turn, in the hull or on the crane | 1 |
| Unload: a loaded piece slides out of a door, back to the stack | 1 |
| Selecting a piece, choosing a door, putting an untouched piece back | 0 |

An action the player cannot afford is refused. When the moves run out the crane stops, and the player either launches with what is aboard or restarts the round. Launching is never refused. If the launch does not meet the contract's requirements, the ship still flies and its cargo is still scored, but the bill and the contract screen both say which requirement was missed, the contract is not fulfilled, and the level does not advance. Spreading one contract over several launches, and bad launches crowding out space, are deferred.

**Requirements and designated spots.** A ship's grid is only a grid: each ship has its own outline, some wider at the bottom, and nothing in it is reserved. It is the contract that asks for things, and a special contract asks in one of two ways:

- **Fit cargo Y.** The cargo is marked as required. It has to be aboard, anywhere.
- **Place cargo X in this location.** The contract marks designated spots on the ship's grid. The placement counts when that cargo is secured in the designated spots exactly: every marked spot is filled by it, and none of it hangs outside.

A placement can be a requirement, or it can be optional and pay a bonus. The bonus is a rule like any other (section 3.6), so it can be extra value, or extra moves: "the reactor core in its cradle, after at least three other pieces are aboard: +2 moves". **[DECIDE D32]** By default a bonus of moves is granted once per designated area and is not taken back if the cargo moves again.

**[DECIDE D43]** Because every ship's grid is different, a location has to be drawn over one particular ship. By default a contract that designates spots also names the ship they are drawn for, and is flown with that ship.

### 3.6 Interactions between cargo and ship

Every interaction is a **rule**. A rule looks at the packed hull and returns findings. The demo uses three reusable rule kinds:

| Interaction | Rule kind | What is tunable |
|---|---|---|
| Vibration-sensitive cargo next to the engines is ruined at launch | **Zone proximity**: cargo with tag A within N spots of a cell tagged B | the two tags, the distance, the effect and its size |
| Computerised cargo next to the outer hull is damaged by radiation | **Zone proximity** again, with different tags and a partial-damage effect | same |
| Some cargo must not sit next to other cargo | **Item pairing**: cargo with tag A and cargo with tag B, touching | the two tags, whether they must touch, the effect and its size |
| Different kinds of cargo on one ship share its cost | **Item pairing** again, not required to touch, with a cost effect **[DECIDE D34]** | same |
| Cargo secured in the spots a contract designates | **Designated spot**: cargo with tag A filling a group of marked cells exactly | the two tags, whether the contract requires it, how many other pieces must already be aboard, the bonus (value or moves) and its size |

The satellite release-depth rule is deferred. When it returns it will be a score penalty, not a wait.

A finding carries: the rule, the cargo involved, the cells involved (so the screen can highlight them), an **effect** (destroy, damage by a fraction, value bonus by a fraction, cost change by an amount, extra moves), and a sentence for the player ("Seismometer ruined: stowed next to the engines").

**The goal is never hidden.** CHECKS lists every rule in force from the first second of the round, each as a plain sentence with a tick or a warning. Selecting a piece highlights the rules that concern it and the cells that threaten it. Zone patterns are always drawn on the hull. There is no switch to hide a rule until launch.

**Exactly.** A designated area is a group of marked cells that touch. It is satisfied when every one of its cells is covered by cargo carrying the rule's tag, and each of those pieces lies wholly inside it. A 2 by 2 area is satisfied by four single crates, by two two-spot pieces lying either way, or by one 2 by 2 piece. This replaces the earlier formation bonus, and with it the question of turned or mirrored formations.

```
  # # # # # #        G  a cargo spot this contract has marked for grain
  D . . G G #
  D . . G G #        four grain crates on the four G spots: bonus
  # E E E E #        three there and one elsewhere, or a different crate on a G: no bonus
```

Adding an interaction is one of two things:

- **A new use of an existing kind** (most cases): create one resource file in `data/rules/` and fill in the tags and numbers. No code.
- **A new kind of interaction**: add one small script in `core/rules/kinds/` that answers one question ("given this packed hull, what are the findings?"), then create its resource file. Nothing else in the game changes.

### 3.7 Stats and the scorecard

**Four stats**, shown while packing and on the scorecard. Each is a number and, where it has a direction, a grade.

| Stat | What it means (your words) | Placeholder maths until you write the real one |
|---|---|---|
| **Weight** | how heavy the load is | the sum of the `weight` of every loaded piece **[DECIDE D33]** |
| **Stability** | how stably and tightly the cargo is packed | the share of the sides of loaded pieces that rest against a wall or another piece |
| **Cost** | a plus and minus system; packing disparate cargo together offsets costs | the ship's launch cost, plus and minus every cost finding |
| **Efficiency** | cargo to spacecraft weight ratio | cargo weight divided by the ship's `dry_weight` |

- Each stat's maths lives in its own small script under `game/stats/`, marked as placeholder and as yours. Replacing a formula touches one file.
- Grade boundaries are tunables: three thresholds and a "higher is better" switch per stat. Weight ships with no grade until D33 is answered, because a heavy load is good for Efficiency and it is not yet clear whether it is good in itself.
- **[DECIDE D35]** For now the grades are shown and do not change the money. Unused moves do not score. Both are yours to wire up once it plays.

**The bill** is the APPROVAL panel of the launch screen, read before the launch button is pressed. It is a report card beside an invoice:

```
  REPORT CARD                          INVOICE

  Weight        14 t      -            Cargo
  Stability     82 %      GOOD           Grain x4                                  +400
  Cost          260       GREAT          Seismometer                               +100
  Efficiency    0.7       BAD              ruined: next to the engines     -100%   -100
                                         Flight computer                           +150
  Moves used    11 of 14                   radiation damage                 -30%    -45
                                       Cost
                                         R0-KET launch                             -300
                                         Grain and instruments share the ride       +40
                                       Contract
                                         Planet A delivery (paid on arrival)       +500
                                       ------------------------------------------------
                                       Net                                         +745
```

Every line has a label, an amount and a source. The same breakdown object feeds the scorecard, the STATS readouts and the debug overlay, so there is never a number on screen that cannot be traced to a rule and a tunable. On a phone the report card sits above the invoice. A requirement that was missed is printed at the head of the bill, and the Contract line reads "not fulfilled" in place of the reward.

Earnings accumulate as a running total. In this demo they are a score; ships are unlocked by deliveries, not bought.

### 3.8 Ships

A ship type is a data file. The aim is that each of the six craft is easy to edit, because upgrading one may later change its role, its cost, and which contracts it suits. So there are no ship classes in code and no fixed families: a craft is a set of switches and numbers, and game code asks "can this ship take orders?", never "is this P0-INT?".

Starter settings for the six. Every cell of this table is a field you can change in the Inspector:

| | R0-KET | P0-INT | T0-URIST | L0-ADER | T0-WER | I0-N |
|---|---|---|---|---|---|---|
| Your description | single launch | post-launch steering | the loaded cargo mechanism | the disposable launcher | towing machine | the ion launcher |
| Has a hull the player packs | yes | yes | yes | no | no | small **[D38]** |
| Takes new orders once in space | no | yes | no | no | yes | yes |
| How it reaches space | launches itself | launches itself | on L0-ADER | launches itself, then discarded | carried as cargo **[D38]** | carried as cargo |
| Needs a tow to move | no | no | yes | — | no | no |
| Can tow | no | no | no | no | yes | yes |
| Range | one trip | limited | none of its own | sets where T0-URIST is left | per its data | unlimited |
| Speed | fast | fast | set by its tow | fast | per its data | slow |
| Starter outline | tall rectangle | stepped triangle | small rectangle | none | none | small square |

How each one plays, settled with you:

- **R0-KET.** Its destination is fixed at launch. It flies there, delivers, and stays.
- **P0-INT.** After it arrives it can be sent somewhere else from the overview, as long as its remaining range allows.
- **T0-URIST on L0-ADER.** The launcher decides where the hull goes: on the launch screen the player picks any body within the launcher's range, and the hull is left in orbit there. The launcher is spent. The parked hull is then a destination in its own right, which a towing craft can be sent to. Leaving a hull at a free point in space, rather than in orbit of a body, is deferred. This does not have to be perfect in the demo.
- **T0-WER.** Tows one hull at a time, at its own speed multiplied by a tunable `tow_speed_factor`.
- **I0-N.** A special piece of cargo. Packed into another ship, it is released as a ship of its own as soon as its carrier reaches orbit at the destination. There is no release delay.
- Cargo is delivered only at a ship's final stop.

Each ship type carries: its hull grid (section 5), launch cost, dry weight, cruise speed, range, the switches above, and art.

### 3.9 Space, contracts and progression

- Space is a **graph**. Nodes are bodies: home, Planet A, Asteroid B, Satellite C and the station. Links have a hand-set distance in light-seconds. Positions on the map are for drawing only. A ship at a body is either in orbit there or delivered; orbits are not separate places.
- **Travel time** for a leg is distance divided by speed. A ship's route is the shortest chain of links to its destination.
- A **contract** names a destination, the cargo stack, the number of moves, its requirements (section 3.5), a reward, and what it unlocks. It is fulfilled when a ship that met every requirement at launch arrives.
- The demo has **exactly three contracts**, all shown on the overview from the start. They are the demo's levels:

  | # | Deliver to | Unlocks |
  |---|---|---|
  | 1 | Planet A | P0-INT, the steerable craft |
  | 2 | Asteroid B | I0-N, the ion craft |
  | 3 | Satellite C | the detachable system: T0-URIST, L0-ADER and T0-WER |

- **[DECIDE D36]** You wrote that when requirements are missed "the level does not advance", so the default is now that the three are played in order: all three are visible from the start, the second opens when the first is fulfilled, and the third when the second is. Any unlocked ship that has a hull may be used, and a fulfilled contract can be flown again. The craft that are carried as cargo (I0-N, T0-WER) and the detachable system have no contract of their own, so in the demo they are shown through prepared scenarios in the debug panel rather than inside the three-contract loop.
- Launched ships stay on the map as the **fleet**. Ships that take orders can be re-routed from the overview.

Where the deferred systems attach later:

| Deferred system | Attaches at |
|---|---|
| A holding area | A second stack in `PackingSession` with its own pick depth; the crane already moves pieces between named places |
| Release-depth rule | One new script in `core/rules/kinds/`, with a value-penalty effect |
| No-turn cargo | The `can_rotate` switch on the cargo type, which the crane already obeys |
| A real-time clock | `PackingSession` gains a time budget beside the move budget; the screen feeds it time |
| Bad launches crowding out space | Launched ships already stay on the map; a body gains a capacity that ships left there count against |
| A contract spread over several launches ("get all of this to space in ten launches") | The contract gains a launch limit and keeps its stack between launches; each launch's bill already lists what went and what was left |
| Collecting cargo already in space, for example with P0-INT | A ship in the fleet keeps its packed hull; a pick-up order in `orders.gd` moves cargo between two hulls at the same body |
| Stat maths and payout | The four scripts in `game/stats/`, and one line per stat in the invoice |
| Ship upgrades | An upgrade is a second resource that overrides fields of a ship type; nothing in code depends on a ship's identity |
| Free-floating targets, launching from the station | A parked hull is already a destination; a body's `pads` field already exists |
| Slingshots, gravity as time, cargo ageing | `TravelCalculator`, the one place travel time is computed |
| Buying ships | A price field on ship types and a shop panel that calls the same unlock function contracts use |
| Deadlines, optional cargo, risk | More fields on the contract resource and more lines in the invoice |

---

## 4. Architecture

### 4.1 Layers

```
ui/ and debug/     screens, widgets, the tuning panel            (draws and forwards input)
	  |  calls down, listens to signals coming up
game/              ships, stats, launch, space, contracts, fleet (Space Packing specific)
	  |
core/              grid, pieces, loading, rules, scoring         (theme-neutral, no engine nodes)
	  |
data/              resource files: content and numbers           (yours)
```

Rules that keep this readable:

- **Dependencies point down only.** `core/` never mentions ships, rockets or space. `game/` never reaches into `ui/`.
- **`core/` is plain logic.** Its classes extend `RefCounted` or `Resource`, never `Node`, so they run in a headless test without a scene.
- **The screen never changes game state directly.** It turns a tap or a swipe into one call on its controller (for example `PackingSession`) and redraws when that controller emits a signal.
- **No numbers in code.** A literal that affects balance, timing, touch feel or layout belongs in a tuning resource.

### 4.2 Porting to another theme

`core/` uses neutral words: container, item, zone, door, loader, stack, move, rule, finding. Zone tags and item tags are names stored in data. For a bakery game the port is: keep `core/`, `debug/` and most of `ui/`; write new data (a delivery van layout with `heater` cells, pastries with a `frosted` tag, a proximity rule joining the two); replace `game/` with the bakery's own outer loop. `tests/` includes a small bakery-flavoured fixture precisely to prove that `core/` carries no space vocabulary.

### 4.3 Folder layout

```
res://
  art/                 yours: images
  screens/             yours: mockups (reference only)
  data/                yours: every content and balance file
    cargo/  ships/  rules/  tags/  bodies/  maps/  contracts/  scenarios/  tuning/
  core/                portable packing engine
    grid/              CellShape, ContainerLayout, LayoutLegend, LayoutValidator
    packing/           PackItemType, PackItem, Batch, PackState, AccessSolver, PackingSession
    rules/             PackingRule, Finding, RuleEngine
      kinds/           >>> EXTENSION POINT: one script per kind of interaction
    scoring/           Breakdown, GradeScale
  game/                Space Packing specific
    ships/             >>> EXTENSION POINT: ShipType and its switches
    cargo/             CargoType
    stats/             the four stat formulas, one file each (placeholder maths, yours)
    launch/            launch resolution and the scorecard
    space/             bodies, links, travel, fleet, orders
    contracts/         contracts and unlocks
    app/               autoloads: Catalog, Tuning, GameState
  ui/                  screens and reusable widgets
    packing/  overview/  reports/  common/
  debug/               tuning panel, explain overlay, scenario picker
  tests/               headless tests and fixtures
  docs/                this plan
```

### 4.4 Autoloads

Three, each small:

- **`Catalog`** loads everything under `data/` by scanning folders. Adding content means dropping a file in; there is no registry to update.
- **`Tuning`** holds the tuning resources and announces when a value changes.
- **`GameState`** holds earnings, unlocked ships, completed contracts, the fleet and the game clock.

### 4.5 Technology choices

- **Godot 4.7.2, GDScript with static types.** The installed editor is the standard build without .NET, and GDScript is the more readable choice for an interviewer skimming code.
- **2D presentation** (decided). `core/` has no drawing code. The empty `node_3d.tscn` in the project is not used; it is left in place for you to delete.
- **Portrait, base resolution 402 x 874** (decided, D12). This is your 1206 x 2622 iPhone divided by exactly three, so the ratio is identical and one unit on screen is one iOS point. With the stretch settings already in `project.godot` the game still renders at the device's full pixel count, so text and art stay sharp. Touch targets are at least 44 units. Touch is primary; mouse input is treated as touch on desktop.
  - On a wider window, such as a desktop browser, the game stays a centred upright column with background either side.
  - Margins for the notch and the home bar are tunables in `presentation.tres`, because a browser cannot always report them.
  - At this width a hull of seven columns gets spots of about 40 units. `Catalog` warns when a hull would need spots smaller than a tunable minimum.
- **Browser build, kept local for now** (decided). The delivery target is a web export, opened on a phone or a desktop. Until you say otherwise it is exported to a folder on this PC and loaded from this PC only.
  - The web export templates are not installed on this machine (checked 14 November 2026: the export templates folder is empty). Installing them is the first step of milestone 0.
  - The web build uses Godot's Compatibility renderer; the desktop editor keeps the current Mobile renderer. The export is made without thread support so that it runs on an ordinary static host. Agents confirm both points on the installed engine.
  - Nothing in the plan needs what a browser lacks: no threads, no writing to the project's files. The tuning panel's Save is editor-only; in the browser it offers "copy differences" instead.
  - **Uploading is deferred** (decided, D39) until some part of the game works and is tested. No agent uploads the build, adds a git remote, or pushes, until you ask. The export is a folder of ordinary static files, so all three of your options stay open and none needs deciding now:
    - *itch.io*: zip the folder and upload it; a page can be restricted to people with the link. The quickest route to a link that works on a phone.
    - *breath-mint.com*: copy the folder to a path or subdomain on whatever serves that site. Any static host will do.
    - *GitHub*: push the source and let an automated job export and publish it on each push, optionally under your own domain. This only makes sense once the repository itself goes up.
  - The cost of waiting is that the game is not tried on a real phone until then. Until an upload, phone checks are done in a desktop browser window sized like a phone.
  - Native phone apps are deferred. A build for an iPhone needs a Mac; the browser build is how it reaches an iPhone for now.
- **Git, local only** (decided, D15). The repository lives on this PC. It has no remote.
- **Tests** run headless through a small in-house runner, with no third-party test addon to explain.
- The **Dialogue Manager** addon that is already in `addons/` is not enabled and not used by this plan. **[DECIDE D13]** Tell me if you have a role in mind for it, such as contract briefings.

---

## 5. Data you will edit

Everything below is a Godot resource file, edited in the Inspector. They are text files underneath, and the grids inside them are plain multi-line text. Field lists are the starting set, not a ceiling.

### Cargo type — `data/cargo/*.tres`

| Field | Example | Notes |
|---|---|---|
| `id`, `display_name` | `seismometer` | |
| `tags` | `vibration_sensitive`, `computerised` | Rules match on these. Free text; invent new ones at will. |
| `shape_text` | `X`, `XX`, or a larger drawing | Any connected shape |
| `can_rotate` | on | Off for cargo that may not be turned (deferred; on everywhere in the demo) |
| `weight` | 2.0 | Per piece; feeds Weight and Efficiency |
| `base_value` | 100 | Per piece |
| `deploys_ship` | empty, or a ship type | Set for I0-N and T0-WER |
| `colour`, `texture` | | Placeholder colour until art exists |

### Tag style — `data/tags/*.tres`

One small file per tag you want drawn: the tag name, a display name ("Sensitive to vibration"), a one- or two-letter glyph, a colour, and an icon slot. See "From text to art" below.

### Batch — inside a contract or scenario

A cargo type, a count, and whether the contract requires it. Batches are listed from the top of the stack down. To interleave types, list batches of one.

### Ship type — `data/ships/*.tres`

The switches and numbers from section 3.8, plus the hull grid, drawn as text:

```
#######       #  outer hull wall   (blocked, tagged "hull")
D.....#       .  cargo spot
D.....#       D  door              (cargo passes through, cannot rest; tagged "door")
D..|..D       |  bulkhead          (blocked, no tag)
D..|..D       E  engine            (blocked, tagged "engine")
#EEEEE#
```

This example has two full-width rows loaded from the left, and two rows split by a bulkhead into a left half and a right half, each loaded from its own side. A hull need not be a rectangle: leave spaces outside the outline to draw a triangle or any other shape.

The character-to-meaning table (the legend) is itself a data file. Each entry has the character, whether cargo can pass through and rest there, its zone tags, and how it is drawn: a colour and a pattern slot. So you can add `S` for a radiation-shielded spot with its own tag and its own look, with no code.

The game checks every hull when it loads and reports in plain words. Because hulls are meant to be easy to experiment with, it refuses only a hull that cannot be played at all (an unknown character, no cargo spots, no door). Everything else is a warning you may ignore, such as "the cargo spot at column 3, row 2 is open to the outside" or "row 4 has no door".

### Interaction rule — `data/rules/*.tres`

One file per interaction, of one of the kinds in section 3.6, with `enabled`, the tags, distances, effect, and two sentences: the rule as the player reads it in CHECKS, and the message when it fires.

### Body and map — `data/bodies/*.tres`, `data/maps/*.tres`

Body: name, kind, pads, position on the map (visual only), art. Map: the list of bodies and the list of links with `distance_ls`.

### Contract — `data/contracts/*.tres`

Destination, the cargo stack (batches, top first, each marked required or not), the number of moves, reward, which ship types it unlocks, and which contracts must be fulfilled first.

A special contract also carries its designated spots: the ship they are drawn for, and a drawing the same size as that ship's grid with a letter on each designated spot and dots elsewhere.

```
.......
....GG.       G  place the grain here
....GG.
.......
.......
.......
```

The letters are looked up in the same legend file as hull characters, which gives each one its tag and its look. Beside the drawing the contract lists its placement rules: which cargo goes on which letter, and whether that is required or pays a bonus.

### Scenario — `data/scenarios/*.tres`

A ready-made packing round: ship, cargo stack, moves. Scenarios are how you set up a specific situation to test or to show in the interview, and they are selectable from the debug panel.

### Tuning — `data/tuning/*.tres`

| File | Holds |
|---|---|
| `packing_tuning.tres` | the cost in moves of each crane action, the default number of moves, `stack_pick_depth` |
| `stats_tuning.tres` | grade boundaries and direction for each stat; the coefficients of the placeholder formulas |
| `space_tuning.tres` | seconds per game hour, tow speed factor |
| `presentation.tres` | spot size, colours, animation durations, swipe distances, screen margins |

### From text to art

You asked how feasible it is to keep levels, hull grids and cargo combinations as text and turn them into finished assets as the game runs. It is the way the plan already works, and it costs nothing at run time:

- **Text is the truth.** A hull is a grid of characters, a piece is a small drawing, a rule is two tag names and a number.
- **Drawing is a lookup, done when a screen opens.** A character in a hull grid looks up its legend entry and draws that entry's pattern (your orange zig-zag for engine spaces) or, with no pattern assigned, a flat colour. A cargo piece draws its texture or a coloured block. A tag such as `vibration_sensitive` looks up its tag style and draws its icon or, with no icon assigned, its glyph ("V").
- **So art arrives in any order.** You can iterate with letters and colours now and assign icons one at a time later. No level, hull or rule file changes when you do.

Two things to know when you draw:

- A piece's texture is stretched over the piece's bounding box and turns with the piece. Draw each cargo piece once, unturned, on a square-per-spot grid.
- Zone patterns tile per spot. Draw them to repeat on a square.

---

## 6. Levers and readability inside the demo

**Tuning panel.** A debug overlay opened with a corner button or the F1 key. It is generated automatically from the tuning resources: a number with a range becomes a slider, a switch becomes a checkbox. Adding a lever is adding one annotated line to a tuning script; the panel needs no change. It also offers: enable or disable each interaction rule and edit its fields, pick a scenario, restart the round, reset to saved values, show what differs from the saved values, copy those differences as text (useful when tuning on a phone), and save back to the data files when running from the editor.

**Explain overlay.** Switchable layers drawn over the hull: the zone tags on each cell, every stop the selected piece could reach, the cells each finding refers to, and the pieces blocking a way out.

**Breakdown everywhere.** Section 3.7: every total is a list of traceable lines.

**Presentation.** One Godot theme for fonts and panel styles, one `presentation.tres` for sizes, colours and timings, a texture slot on every cargo, ship and body resource, a pattern slot on every legend entry, and an icon slot on every tag style. With nothing assigned the game draws a coloured, labelled placeholder, so your art can arrive in any order from milestone 2 onward.

---

## 7. How to extend it (the recipes agents must keep true)

| To add | Do this | Code changes |
|---|---|---|
| A cargo type | New file in `data/cargo/` | None |
| An interaction of an existing kind | New file in `data/rules/` | None |
| A new kind of interaction | New script in `core/rules/kinds/`, then a file in `data/rules/` | One new file |
| A zone on a hull | New entry in the legend file, use its character in a hull grid | None |
| An icon or name for a tag | New file in `data/tags/` | None |
| A ship | New file in `data/ships/` | None |
| A ship switch | New field on `ShipType`, read it in the one place that cares | Two small edits |
| A body or a link | Edit files in `data/bodies/` and `data/maps/` | None |
| A contract or an unlock | New file in `data/contracts/` | None |
| A tunable number | One annotated line in a tuning script | One line |
| New maths for a stat | Edit that stat's one script in `game/stats/` | One file |

Each milestone's sanity check includes adding one of these by hand, to confirm the recipe still works.

---

## 8. Testing and verification

- `core/` and the calculation parts of `game/` have headless tests: shapes, hull parsing and validation, entering, stopping short, shifting, turning, leaving, the stack, move costs, each rule kind, designated spots, the stats, the scorecard, travel time, orders.
- One command runs all tests and exits non-zero on failure. Agents run it before reporting a milestone done and paste the output.
- Screens are verified by you, using the short hands-on checklist in each milestone. Agents cannot judge feel.
- Every milestone ends in a state that launches and is playable, and from milestone 0 onward, in a browser build that loads on this PC.

---

## 9. Risks

| Risk | Why it matters | Mitigation |
|---|---|---|
| Row loading is too easy to be interesting | It is the core of the demo | The depth comes from the fixed stack order, the move budget, burial, interactions across rows, turning in gaps and door layouts. All are levers; milestone 4's check is where you judge it. |
| Swipes are misread on a small screen | The whole game is three gestures | Swipe distances are tunables. A swipe's direction locks early and the piece follows the finger, so the player sees what will happen before letting go. Judged at milestone 2, on a phone. |
| The gripped spot is too subtle a way to choose how a piece turns | Turning inside the hull is the cleverest move in the game | The grip is drawn as a pin on the piece; a refused turn shakes and costs nothing. D29 is the place to change it. |
| A browser on a phone claims gestures for itself | Edge swipes go back a page; long presses select text | The play area keeps clear of the screen edges; the panel opens from a button, not a multi-finger tap. This can only be tested on a real phone once a build is uploaded, so the first upload is followed at once by a phone check, and the touch values are tunables so that fixes are quick. |
| The web build behaves differently from the desktop build | Different renderer, slower start-up | The web build is made and loaded locally at every milestone from 0, so differences show up one at a time. |
| The detachable system and carried craft have no place in a three-contract loop | They are half the roster | D36. By default they are shown through debug scenarios; milestone 7 is greybox and you have said it need not be perfect. |
| Placeholder stat maths is mistaken for design | The numbers will look authoritative | Each formula file says it is a placeholder and yours; grades do not touch money until you say so. |
| Agent memory of the Godot API is older than 4.7 | Code that looks right and does not run | CLAUDE.md requires checking the installed engine and running the project before reporting. |
| Hand-written scene files break quietly | A scene that will not open in the editor | Scenes stay small; a load check runs with the tests. |
| Tuning drifts between the panel and the files | You lose values you liked | The panel shows the difference from saved values, copies it as text, and saves back explicitly. |

---

## 10. Decisions

### Settled

| # | Question | Decision |
|---|---|---|
| D1 | How does loading order constrain the player? | Rows loaded from the side through doors; a piece moves in a straight line along its row and leaves only through a door. |
| D2 | How is cargo organised before loading? | It is not. There is a stack and the ship; all organising is done with the crane. *(Revised in round 3.)* |
| D3 | 2D or 3D? | 2D |
| D4 | Scope | Exactly three contracts and six named craft; packing, interactions and editable ships first. Deferred list in section 1. *(Revised in round 3.)* |
| D5 | Gravity inside the hull? | No |
| D6 | Is packing timed? | By moves, not by the clock. The launch window is a number of moves. |
| D7 | What do the sketch labels mean? | Art for now. Nothing is derived from the sketches. |
| D9 | Are the rules visible while packing? | Always. There is no way to hide a rule. |
| D10 | Rotation | The crane turns any piece a quarter turn, outside or inside the hull. A turn costs a move. *(Revised in round 3.)* |
| D11 | Is the ion craft carried as cargo? | Yes, as a special large piece |
| D12 | Orientation and base resolution? | Portrait, 402 x 874: the iPhone's 1206 x 2622 divided by three. |
| D14 | Distances | Typed per link |
| D15 | Git? | Yes, on this PC only. No remote and no push until the designer asks. |
| D17 | Can the player stop a piece short? | Yes |
| D18 | Can any loaded piece turn, and what does it cost? | Any piece, at any depth, as long as it stays whole and fits. One move. No pivot time. |
| D19 | Does a turned or mirrored formation still earn the bonus? | Superseded by D31: there are no formations. Cargo may sit any way round in its designated spots. |
| D20 | Where does a towed hull wait? | Wherever its launcher leaves it: in orbit of a body within the launcher's range. It is then a destination for a tow. Free points in space are deferred. |
| D21 | How many hulls does a tug tow, and at what speed? | One, at its own speed times `tow_speed_factor` |
| D22 | Where and when is an ion craft deployed? | Where its carrier reaches orbit, at once. No release delay; any future delay is a score penalty. |
| D23 | Where is cargo delivered? | Only at the final stop |
| D24 | Piece sizes | Any connected shape drawn in text. *(Revised in round 3: an L was your own example.)* |
| D25 | What does the bonus reward? | Cargo secured in its designated spots exactly. *(Revised in round 4.)* |
| D37 | The star chart and APPROVAL | The star chart is decoration. APPROVAL is the bill: the report card and invoice, on the launch screen. The station is taken to be the disc on a stalk on the overview mockup. |
| D41 | Who designates spots? | The contract. A ship's grid is only a grid. |
| D42 | What does a launch that misses the contract's requirements do? | It flies and is scored. The bill and the contract screen say what was missed, and the level does not advance. |
| D30 | What happens when the moves run out? | The crane stops. The player launches or restarts. Launching is never refused. |
| D31 | Is there a formation bonus? | No. The bonus is for cargo stored in its designated spots exactly. |
| D39 | Where is the browser build hosted? | Nowhere yet. It is built and loaded on this PC; uploading waits until part of the game works. itch.io, breath-mint.com and GitHub all remain possible. |
| — | Holding area | None. Unloaded cargo returns to the top of the stack. |
| — | Re-handling | No button and no fee. It costs moves. |
| — | Satellite release-depth rule | Deferred |
| — | Stats | Weight, Stability, Cost, Efficiency, as numbers with great / good / bad / terrible grades. Maths is the designer's, later. |
| — | Scorecard | A report card beside an invoice |
| — | FIXED CARGO on the routing mockup | The packed ship as it will launch |
| — | The fan and the circle on the routing mockup | A star chart, and under it the launch button, a circle with an L |
| — | File names for the designer's own content | The designer's names, without `example_` |
| — | Bad launches crowding out space | Deferred |
| — | Contracts over several launches; collecting cargo in space | Deferred |
| — | Contract screen | The same screen as the overview |
| — | Roster | R0-KET, P0-INT, T0-WER, T0-URIST, L0-ADER, I0-N, and no others |
| — | Zone tags on screen | A coloured pattern per zone, drawn by the designer |
| — | Delivery | A browser build, made locally from milestone 0, uploaded when the designer says |

### Open, with the default the plan assumes

The first four change what milestones 1 and 2 build, so those are the ones worth answering before any code is written. Nothing open blocks milestone 0.

| # | Question | Default | Blocks |
|---|---|---|---|
| D26 | What is one move? | One completed crane action: a load, a shift of any distance, a quarter turn anywhere, or an unload. Each cost is a tunable. Selecting and choosing a door are free. | M1 |
| D27 | How does a piece from the stack get to a particular row, now that swiping up and down means turn? | Tap a door (or its crane arm); the held piece moves there. | M2 |
| D28 | Can only the top piece of the stack be taken? | Yes. `stack_pick_depth` is 1. | M1 |
| D29 | How does a piece turn inside the hull? | About the spot that was tapped. Only the end position has to be free; the swing in between is not checked. Swipe down turns clockwise, up anticlockwise. | M1, M2 |
| D40 | Is the portrait stacking in section 2 right? | As described there | M2 |
| D32 | Are bonus moves granted once and kept? | Once per designated area; not taken back | M4 |
| D33 | Is Weight the total load, or how well balanced it is? And is a heavy load good or bad? | The total. No grade until you say which way is good. | M4 |
| D34 | Does "packing disparate cargo together" mean on the same ship, or touching in the hull? | On the same ship. It is one switch on the rule either way. | M4 |
| D35 | Do grades, or unused moves, change the money? | No to both, for now | M5 |
| D38 | Which sketches are T0-URIST and L0-ADER? Is T0-WER carried up as cargo, like I0-N? Does I0-N have a hull of its own? | Either teal hull; yes; a small one | M5, M7 |
| D36 | Are the three contracts played in order, can they be replayed, and where does the player get to use I0-N and the detachable system? | All visible, played in order, replayable. Carried craft and the detachable system are shown through debug scenarios. | M6, M7 |
| D43 | How does a contract point at a location when every ship's grid is different? | It names one ship, draws the spots over that ship's grid, and is flown with that ship. | M4, M6 |
| D13 | Is there a role for the Dialogue Manager addon? | Unused | — |
| D16 | The Godot project is named "LILA-TEST", which is also what a browser tab will show. Rename it to "Space Packing"? | Leave it until you say | M0 |
