extends Area2D

class_name GroundChecker;


var isGrounded: bool;

func _on_body_exited(_body: Node2D):
	isGrounded = false

func _on_body_entered(_body:Node2D):
	isGrounded = true
