class_name SpeedReadout
extends Label
## Shows the player's speed in m/s. Handy for tuning momentum.

var _body: CharacterBody3D


func setup(body: CharacterBody3D) -> void:
	_body = body


func _process(_delta: float) -> void:
	if _body == null:
		return
	var shown: String = "%d m/s" % roundi(_body.velocity.length())
	if shown != text:
		text = shown
