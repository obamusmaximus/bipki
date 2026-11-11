@tool
class_name Tower
extends StaticBody3D
## A building the player can grapple to, made from the Kenney City Kit. `size.y` is the target
## height; the model is scaled uniformly to it, but the footprint is capped at `max_footprint`
## (so neighbours 11 m apart never overlap), which can make very tall towers a bit shorter.
## The collision box wraps the scaled model. Sits on collision layer 1 (World).

## Target size. The x and z values are ignored; the model's own proportions decide the footprint.
@export var size: Vector3 = Vector3(4.0, 14.0, 6.0):
	set(value):
		size = value
		_rebuild()
## Index into `BuildingCatalog`. -1 picks one from the tower's position, so it's stable.
@export var variant: int = -1:
	set(value):
		variant = value
		_rebuild()
## Rotation around Y, in quarter turns.
@export_range(0, 3) var quarter_turns: int = 0:
	set(value):
		quarter_turns = value
		_rebuild()
@export var max_footprint: float = 7.7:
	set(value):
		max_footprint = value
		_rebuild()

@onready var _model_holder: Node3D = $Model
@onready var _collision: CollisionShape3D = $Collision


func _ready() -> void:
	_rebuild()


func _rebuild() -> void:
	if not is_node_ready():
		return
	for child: Node in _model_holder.get_children():
		child.free()
	var seed_value: int = hash(Vector3i(position.round()))
	var index: int = variant if variant >= 0 else BuildingCatalog.pick(size.y, max_footprint, seed_value)
	index = clampi(index, 0, BuildingCatalog.count() - 1)
	var box: AABB = BuildingCatalog.bounds(index)
	var factor: float = BuildingCatalog.fit_scale(index, size.y, max_footprint)
	var model: Node3D = BuildingCatalog.instantiate(index)
	# Centre the footprint on the origin, base on the ground (y = -size.y / 2).
	var centre: Vector3 = box.position + Vector3(box.size.x, 0.0, box.size.z) * 0.5
	model.position = -centre
	_model_holder.add_child(model)
	_model_holder.scale = Vector3.ONE * factor
	_model_holder.rotation.y = quarter_turns * PI * 0.5
	_model_holder.position.y = -size.y * 0.5
	var scaled: Vector3 = box.size * factor
	if quarter_turns % 2 == 1:
		scaled = Vector3(scaled.z, scaled.y, scaled.x)
	var shape := BoxShape3D.new()
	shape.size = scaled
	_collision.shape = shape
	_collision.position.y = scaled.y * 0.5 - size.y * 0.5
