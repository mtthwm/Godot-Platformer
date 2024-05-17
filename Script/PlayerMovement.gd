extends RigidBody2D

@export_group("Movement")
@export var tilesize: int = 16;
@export var tilesPerSecondSpeed: int = 8;
@export var timeToMaxSpeed: float = 0.1;
@export var tilesPerJump: int = 3;
@export var inputMaxFullHoldTime = 0.01;
@export var groundCheck: GroundChecker;
@export var leftWallChecker: GroundChecker;
@export var rightWallChecker: GroundChecker;
@export var extraJumps = 1;

@export_group("Grappling")
@export var grappleLength = 200;
@export var crosshair: Node2D;


var _grapplePoint: Vector2;
var _grappling: bool = false;
var _grappleDir: Vector2;
var _canGrapple: bool = false;

var _maxSpeed;
var _gravity_magnitude;
var _weight;
var _normalForceMagnitude;  # TODO: MAKE THIS WORK WITH SLANTS
var _jumpHeight;
var _maxHorizontalForce;
var _remainingJumps: int;
var _timeSincePress = 0;
var _hasJumpedThisButtonPress = false;


# Called when the node enters the scene tree for the first time.
func _ready():
	_maxSpeed = tilesPerSecondSpeed * tilesize;
	_gravity_magnitude = ProjectSettings.get_setting("physics/2d/default_gravity");
	_weight = _gravity_magnitude * mass * gravity_scale;
	_normalForceMagnitude = _weight;  # TODO: MAKE THIS WORK WITH SLANTS
	_jumpHeight = (tilesPerJump * tilesize);
	_maxHorizontalForce = _maxSpeed * mass;

func _can_jump ():
	var canDoubleJump = (_remainingJumps > 0) && Input.is_action_pressed("move_jump");
	return (groundCheck.isGrounded || canDoubleJump) && linear_velocity.y >= 0;

func _should_jump ():
	var justReleased = Input.is_action_just_released("move_jump");
	var heldLongEnough = Input.is_action_pressed("move_jump") && (_timeSincePress > inputMaxFullHoldTime);
	return justReleased or (heldLongEnough and not _hasJumpedThisButtonPress);

func _doJump ():
	_remainingJumps -= 1;
	var holdTimeModifier = min(_timeSincePress / inputMaxFullHoldTime, 1);
	var jumpVelocity = sqrt(2 * _weight * _jumpHeight * holdTimeModifier);
	if linear_velocity.y > 0:
		jumpVelocity += linear_velocity.y;
	linear_velocity.y -= jumpVelocity;
	_hasJumpedThisButtonPress = true;

func _handle_jumping (delta):
	_timeSincePress += delta;
	
	if groundCheck.isGrounded:
		_remainingJumps = extraJumps;

	if Input.is_action_just_pressed("move_jump"):
		_timeSincePress = 0;

	if _can_jump() and _should_jump():
		_doJump();

	if Input.is_action_just_released("move_jump"):
		_hasJumpedThisButtonPress = false;

func _handle_grappling (_delta):
	if Input.is_action_pressed("move_right"):
		_grappleDir.x = 1;	

	if Input.is_action_pressed("move_left"):
		_grappleDir.x = -1;

	if Input.is_action_pressed("move_up"):
		_grappleDir.y = -1;

	if Input.is_action_pressed("move_down"):
		_grappleDir.y = 1;

	_grappleDir = _grappleDir.normalized();

	_grapplePoint = global_position + _grappleDir * grappleLength;

	if Input.is_action_pressed("move_grapple"):
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, _grapplePoint);
		var result = space_state.intersect_ray(query);

		if result:
			_canGrapple = true;
			crosshair.modulate = Color(1, 1, 1);
			_grapplePoint = result.position;
		else:
			crosshair.modulate = Color(1, 0, 0);
			_canGrapple = false;

		crosshair.show();
		crosshair.set_global_position(_grapplePoint);
			
	else:
		crosshair.hide();

	if Input.is_action_just_pressed("move_grapple") && _canGrapple:
		_grappling = true;
		_canGrapple = false;

	if _grappling:
		if groundCheck.isGrounded:
			_grappling = false;
		

func _handle_movement (_delta):
	var movement_force_magnitude = (_maxSpeed / timeToMaxSpeed) * mass + _normalForceMagnitude;
	var frictional_force_magnitude = _normalForceMagnitude * physics_material_override.friction;
	var horizontalForce = movement_force_magnitude+ frictional_force_magnitude;

	if !_grappling && Input.is_action_pressed("move_right"):
		if !rightWallChecker.isGrounded:
			if linear_velocity.x < _maxSpeed:
				apply_force(Vector2(horizontalForce, 0));

	if !_grappling && Input.is_action_pressed("move_left"):
		if !leftWallChecker.isGrounded:
			print_debug("LEFT WALL NOT GROUNDED");
			if linear_velocity.x > -_maxSpeed:
				apply_force(Vector2(-horizontalForce, 0));


func _physics_process(delta):
	_handle_movement(delta);
	_handle_jumping(delta);
	_handle_grappling(delta);
