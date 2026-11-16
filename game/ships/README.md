# game/ships

ShipType: the data class for a craft and its switches. Game code asks what a ship can do, never which ship it is.

- `ship_type.gd`: a greybox ShipType: name, description and the hull drawn as text with its legend. It counts its cargo spots and checks its hull. Costs, flight numbers and switches join it in milestone 5.

Owner: agents (code).
