extends Area2D

class_name GroundChecker;

var isGrounded: bool;
var measuredVelocity: Vector2 = Vector2(0, 0);

var _tracked_body: RigidBody2D = null;

func _on_body_exited(_body: Node2D):
	_tracked_body = null;
	measuredVelocity = Vector2(0, 0);
	isGrounded = false

func _on_body_entered(_body:Node2D):
	_tracked_body = _body as RigidBody2D;
	isGrounded = true

func _physics_process(_delta):
	if _tracked_body != null:
		measuredVelocity = _tracked_body.linear_velocity;
