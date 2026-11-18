class_name LoadoutHud
extends Node
## A loadout's part of the HUD (GrappleHud), mounted into the shared Hud by `Hud.mount`. Each direct child is a
## plain holder named after one of the Hud's slots (`Hud.SLOTS`), and the elements inside it are moved into that
## slot, so they get the slot's anchor, edge margin, HUD scale and (for the edge groups) the visor bend. The holders
## are then freed. The elements stay this module's: they are freed with it. Reference elements with `@onready`
## (resolved before the move) and set them up in the subclass's own `setup`, after mounting.

var _elements: Array[Node] = []


## Called by Hud.mount for each element it moved out of this module's holders.
func adopt(element: Node) -> void:
	_elements.append(element)


func _exit_tree() -> void:
	for element: Node in _elements:
		if is_instance_valid(element):
			element.queue_free()
	_elements.clear()
