extends Node2D

class_name CheckpointManager;

@export var root: Node2D;
@export var lives: int = 3;

@export var _remaining_lives: int;
@export var _last_checkpoint: Checkpoint;

const PHYSICS_PAUSE_TIME = 0.01;

var _is_teleporting: bool;
var _timer: float;
var _done_first_wait: bool;

# Called when the node enters the scene tree for the first time.
func _ready():
	_remaining_lives = lives;


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	_handle_teleportation(_delta)

func _handle_teleportation (_delta):
	if _is_teleporting:
		_timer += _delta;

		if _timer < PHYSICS_PAUSE_TIME:
				return

		if _done_first_wait:
			_is_teleporting = false;
			_done_first_wait = false;
			root.set_physics_process(true);
			return;

		root.set_physics_process(false);

		root.global_position = _last_checkpoint.global_position;
		(root as RigidBody2D).linear_velocity = Vector2(0,0);
		(root as RigidBody2D).angular_velocity = 0;
		_done_first_wait = true;


func _teleport_player ():
	if _last_checkpoint != null:
		_done_first_wait = false;
		_timer = 0;
		_is_teleporting = true;
	else:
		_restart();

func _restart ():
	get_tree().reload_current_scene();

func go_back ():
	if lives > 0:
		_remaining_lives -= 1;
		if _remaining_lives == 0:
			_restart();
	
	_teleport_player();

		
