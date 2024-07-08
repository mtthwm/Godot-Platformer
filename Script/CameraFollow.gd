extends Node2D

@export var positionToFollow: Node2D;
@export var lerpSpeed: float = 2;

func _physics_process(delta):
	position = lerp(position, positionToFollow.global_position, delta * lerpSpeed);
