class_name VelocityLedger
extends RefCounted
## Debug: splits one physics frame's velocity change into named parts ("gravity", "steering", "collision"...), so the
## playtest log shows which force took the speed. The owner calls begin() at the start of the frame and mark() after
## each step that touches velocity. Whatever changed velocity between frames (launch impulses, hits) lands in "events".
## The parts always sum to the frame's whole velocity change.

## Part name to its velocity change this frame (m/s).
var parts: Dictionary = {}
var _last: Vector3 = Vector3.ZERO
var _started: bool = false


## Starts a frame. Any change since the previous frame's last mark is filed under "events".
func begin(velocity: Vector3) -> void:
	parts = {}
	if _started:
		_add(&"events", velocity - _last)
	_started = true
	_last = velocity


## Files the change since the last mark under `part`. Marking the same part twice adds up.
func mark(part: StringName, velocity: Vector3) -> void:
	_add(part, velocity - _last)
	_last = velocity


func _add(part: StringName, change: Vector3) -> void:
	if change.is_zero_approx():
		return
	parts[part] = parts.get(part, Vector3.ZERO) + change
