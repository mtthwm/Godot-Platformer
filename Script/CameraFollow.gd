extends Node2D

@export var positionToFollow: Node2D;
@export var lerpSpeed: float = 2;

func _physics_process(_delta):
	position = positionToFollow.position;
