extends Area2D


var isGrounded: bool;

func _trigger_entered(_body: Node) -> void:
	print_debug("ENTER")
	isGrounded = true

func _trigger_exited(_body: Node) -> void:
	print_debug("EXIT")
	isGrounded = false