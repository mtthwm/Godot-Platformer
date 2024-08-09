extends Area2D

func _on_body_entered(_body: Node2D):
	var cm = _body.get_node("CheckpointManager")as CheckpointManager;
	if cm != null:
		cm.go_back();

func _on_body_exited(_body: Node2D):
	pass
