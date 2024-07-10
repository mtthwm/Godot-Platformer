extends RigidBody2D

@export var positionParent: Node2D;
@export var tilesize: int = 16;
@export var tilesPerSecondSpeed: int = 3;

var _lerp_positions: Array[Node] = [];
var _index: int = 0;

func _ready():
	_lerp_positions = positionParent.get_children();

func _physics_process(_delta):
	var dist = global_position.distance_to(_lerp_positions[_index].global_position);
	if dist < 1:
		_index = (_index + 1) % _lerp_positions.size();

	linear_velocity = (_lerp_positions[_index].global_position - global_position).normalized() * tilesPerSecondSpeed * tilesize;
