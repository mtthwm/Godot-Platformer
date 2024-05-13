extends RigidBody2D

@export var tilesize: int = 16;
@export var tilesPerSecondSpeed: int = 8;
@export var timeToMaxSpeed: float = 0.1;
@export var tilesPerJump: int = 3;
@export var inputMaxFullHoldTime = 0.01;
@export var groundCheck: GroundChecker;
@export var leftWallChecker: GroundChecker;
@export var rightWallChecker: GroundChecker;
@export var extraJumps = 1;

var _grapplePoint: Vector2;
var _grappling: bool = false;

var _maxSpeed;
var _gravity_magnitude;
var _weight;
var _normalForceMagnitude;  # TODO: MAKE THIS WORK WITH SLANTS
var _jumpHeight;
var _maxHorizontalForce;
var _groundChecker;
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

func _handle_movement (_delta):
	var movement_force_magnitude = (_maxSpeed / timeToMaxSpeed) * mass + _normalForceMagnitude;
	var frictional_force_magnitude = _normalForceMagnitude * physics_material_override.friction;
	var horizontalForce = movement_force_magnitude+ frictional_force_magnitude;

	if Input.is_action_pressed("move_right"):
		if linear_velocity.x < _maxSpeed:
			apply_force(Vector2(horizontalForce, 0));

	if Input.is_action_pressed("move_left"):
		if linear_velocity.x > -_maxSpeed:
			apply_force(Vector2(-horizontalForce, 0));

func _physics_process(delta):
	_handle_movement(delta);
	_handle_jumping(delta);
