class_name CitySettings
extends Resource
## Parameters for the procedural city. `CityLayout` turns them into a plan; this holds no nodes.

## Same seed, same city.
@export var seed_value: int = 1
## Width of the built-up area in metres. The grid covers at least this much.
@export_range(100.0, 1000.0, 10.0) var extent: float = 400.0
## Roads against buildings. 0 = small lots, so the roads are wide compared with the buildings.
## 1 = large lots, so the roads recede and the buildings fill the blocks.
@export_range(0.0, 1.0, 0.01) var density: float = 0.5
## Lots along each side of a block.
@export_range(1, 4) var lots_per_block: int = 2
## Share of lots left empty (parks, plazas).
@export_range(0.0, 1.0, 0.01) var empty_lot_chance: float = 0.1
## Building heights run from min to max, tallest near the centre.
@export_range(3.0, 200.0, 0.5) var min_height: float = 10.0
@export_range(3.0, 200.0, 0.5) var max_height: float = 90.0
## Share of buildings that are landmarks at max height.
@export_range(0.0, 1.0, 0.01) var landmark_chance: float = 0.04
