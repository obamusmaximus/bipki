class_name ModeLabel
extends Label
## Shows which grapple function is active (hook, launch or swing). Empty when idle.

var _hook: GrappleHook


func setup(hook: GrappleHook) -> void:
	_hook = hook


func _process(_delta: float) -> void:
	if _hook == null:
		return
	var shown: String = _text_for(_hook.get_state(), _hook.get_mode())
	if shown != text:
		text = shown


func _text_for(state: GrappleHook.State, mode: GrappleHook.Mode) -> String:
	if state == GrappleHook.State.IDLE:
		return ""
	match mode:
		GrappleHook.Mode.LAUNCH:
			return "LAUNCH"
		GrappleHook.Mode.SWING:
			return "SWING  (hold Shift to reel)"
	return "HOOK"
