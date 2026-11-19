class_name SeekerShotgun
extends Node
## The jet's main weapon (see docs/mechanics/jet.md): each press of `fire` sends `pellet_count` pellets in a cone at
## what the crosshair points at. No cooldown. Each pellet is given one of the tracked enemies (Tracking), newest pickup
## first and round again, so with fewer tracks than pellets the newest get the extra ones. Pellets (its child) flies
## them. Owned by JetLoadout, which calls `tick` at the start of each frame.

## A shot left the muzzle. `targets` holds each pellet's enemy, in pellet order (empty without tracks).
signal fired(targets: Array[Enemy])

const AIM_MASK: int = 1 | 4 # World, Enemy

var stats: SeekerShotgunStats

var _camera: Camera3D
var _tracking: Tracking
var _active: bool = true
var _shot_player: AudioStreamPlayer

@onready var _pellets: Pellets = $Pellets


func _ready() -> void:
	# A short, hard crack of noise over a falling thud.
	_shot_player = AudioStreamPlayer.new()
	_shot_player.stream = Synth.make_sound(0.18, 260.0, 70.0, 0.8, 0.8, 0.002, 3.0)
	add_child(_shot_player)


func setup(camera: Camera3D, tracking: Tracking, shotgun_stats: SeekerShotgunStats) -> void:
	_camera = camera
	_tracking = tracking
	stats = shotgun_stats
	stats.changed.connect(_apply_volume)
	_apply_volume()
	_pellets.setup(stats)


## `can_fire` is false while the loadout's abilities are locked (the afterburner).
func tick(delta: float, can_fire: bool) -> void:
	if _active and can_fire and Input.is_action_just_pressed("fire"):
		_fire()
	_pellets.tick(delta)


## Input off (dead, waiting for the rewind).
func set_active(enabled: bool) -> void:
	_active = enabled


## Pellets in flight are gone (a death, a rewind): they aren't saved.
func clear() -> void:
	_pellets.clear()


func _fire() -> void:
	var muzzle: Vector3 = _camera.global_transform * stats.muzzle_offset
	var aim_dir: Vector3 = muzzle.direction_to(_aim_point())
	var targets: Array[Enemy] = _tracking.get_targets()
	targets.reverse() # Newest pickup first.
	var assigned: Array[Enemy] = []
	for i: int in stats.pellet_count:
		var target: Enemy = targets[i % targets.size()] if not targets.is_empty() else null
		assigned.append(target)
		_pellets.spawn(muzzle, _spread(aim_dir) * stats.speed, target)
	_shot_player.play()
	fired.emit(assigned)


## What the crosshair points at within `aim_range`, or the point that far along the view.
func _aim_point() -> Vector3:
	var eye: Vector3 = _camera.global_position
	var far: Vector3 = eye - _camera.global_basis.z * stats.aim_range
	var query := PhysicsRayQueryParameters3D.create(eye, far, AIM_MASK)
	var hit: Dictionary = _camera.get_world_3d().direct_space_state.intersect_ray(query)
	return hit.position if not hit.is_empty() else far


## A direction within `spread_degrees` of `forward`, spread evenly over the cone's disc.
func _spread(forward: Vector3) -> Vector3:
	var side: Vector3 = forward.cross(Vector3.UP if absf(forward.y) < 0.99 else Vector3.RIGHT).normalized()
	var up: Vector3 = side.cross(forward)
	var radius: float = tan(deg_to_rad(stats.spread_degrees)) * sqrt(randf())
	var angle: float = randf() * TAU
	return (forward + (side * cos(angle) + up * sin(angle)) * radius).normalized()


func _apply_volume() -> void:
	_shot_player.volume_db = stats.shot_db
