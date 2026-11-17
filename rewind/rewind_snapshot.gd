class_name RewindSnapshot
extends RefCounted
## The state of every rewindable node at one moment, taken by `Rewind`.

## Game time (s) on the Rewind clock when it was taken.
var time: float = 0.0
## Rewind id to the state that node's `rewind_capture()` returned.
var states: Dictionary[int, Dictionary] = {}
## Rewind id to how to make the node again if it is gone (see `Rewind.Origin`). Only nodes in RECREATE_GROUP.
## Shared with the node, so a snapshot holds a reference, not a copy.
var origins: Dictionary[int, Rewind.Origin] = {}
