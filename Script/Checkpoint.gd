extends Area2D

class_name Checkpoint;

func _on_body_entered(_body: Node2D):
	var cm = _body.get_node("CheckpointManager");
	if cm != null:
		cm._last_checkpoint = self;

func _on_body_exited(_body: Node2D):
	pass
