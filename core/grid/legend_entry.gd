## What one character in a layout text means: whether an item can pass
## through the cell, whether it can rest there, and which zone tags the cell
## carries. The label, colour and pattern are read only by screens. An entry
## holds no rules; rules match on its tags.
class_name LegendEntry
extends Resource

## The single character that stands for this kind of cell in a layout text.
@export var symbol: String = ""
## An item can slide through this cell.
@export var passable: bool = false
## An item can come to rest on this cell.
@export var storable: bool = false
## Zone tags. Rules match on these names; invent new ones freely.
@export var tags: Array[StringName] = []
## A short name shown on the placeholder drawing of the cell.
@export var label: String = ""
## The flat colour drawn when no pattern is assigned.
@export var colour: Color = Color.DIM_GRAY
## A tile that repeats once per cell. Empty means draw the colour and label.
@export var pattern: Texture2D
