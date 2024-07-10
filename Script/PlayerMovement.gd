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
@export var ceilingChecker: GroundChecker;
@export var extraJumps = 1;

@export_group("Grappling")
@export var grappleLengthTiles = 12;
@export var crosshair: Node2D;
@export var grappleSpeed = 16;
@export var minGrappleTileLength = 2

var _locked_movement: int = 0;

var _grapplePoint: Vector2;
var _grappling: bool = false;
var _grappleDir: Vector2;

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

func _do_jump ():
	_remainingJumps -= 1;
	var holdTimeModifier = min(_timeSincePress / inputMaxFullHoldTime, 1);
	var jumpVelocity = sqrt(2 * _weight * _jumpHeight * holdTimeModifier);
	if linear_velocity.y > 0:
		jumpVelocity += linear_velocity.y;
	linear_velocity.y -= jumpVelocity;
	_hasJumpedThisButtonPress = true;

func _handle_jump (delta):
	_timeSincePress += delta;
	
	if groundCheck.isGrounded:
		_remainingJumps = extraJumps;

	if Input.is_action_just_pressed("move_jump"):
		_timeSincePress = 0;

	if _can_jump() and _should_jump():
		_do_jump();

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

	if !_grappling:
		_grappleDir = _grappleDir.normalized();
		_grapplePoint = global_position + _grappleDir * grappleLengthTiles * tilesize;

	if Input.is_action_pressed("move_grapple"):
		_lock_movement(3);
		
		if !_grappling:
			var space_state = get_world_2d().direct_space_state
			var query = PhysicsRayQueryParameters2D.create(global_position, _grapplePoint);
			var result = space_state.intersect_ray(query);

			if result && position.distance_to(result.position) > minGrappleTileLength * tilesize:
				crosshair.modulate = Color(1, 1, 1);
				_grapplePoint = result.position;
				_grappling = true;
				_remainingJumps = extraJumps;
				_lock_movement(5);

			else:
				crosshair.modulate = Color(1, 0, 0);

			crosshair.show();
			crosshair.set_global_position(_grapplePoint);
	else:
		crosshair.hide();
		_unlock_movement(3);

	if _grappling:
		var touchingAnything: bool = (groundCheck.isGrounded || leftWallChecker.isGrounded || rightWallChecker.isGrounded || ceilingChecker.isGrounded);
		if touchingAnything || !Input.is_action_pressed("move_grapple"):
			_grappling = false;
			_unlock_movement(5);
			_grappling = false;
			
func _grappling_velocity ():
	var toGrapplePoint = (_grapplePoint - global_position).normalized();
	var rotateAngle = PI/2;
	if _grappleDir.x < 0:
		rotateAngle = -rotateAngle;
	print_debug(_grapplePoint);
	var tangent = toGrapplePoint.rotated(rotateAngle);
	return grappleSpeed * tilesize * tangent;

func _handle_movement (_delta):
	var movement_force_magnitude = (_maxSpeed / timeToMaxSpeed) * mass + _normalForceMagnitude;
	var frictional_force_magnitude = _normalForceMagnitude * physics_material_override.friction;
	var horizontalForce = movement_force_magnitude + frictional_force_magnitude;
	var forceToApply = Vector2(0, 0);

	if Input.is_action_pressed("move_right") && !_locked_movement:
		if !rightWallChecker.isGrounded:
			if linear_velocity.x < (_maxSpeed + groundCheck.measuredVelocity.x):
				forceToApply.x += horizontalForce;

	elif Input.is_action_pressed("move_left") && !_locked_movement:
		if !leftWallChecker.isGrounded:
			if linear_velocity.x > -_maxSpeed + groundCheck.measuredVelocity.x:
				forceToApply.x -= horizontalForce;
	else:
		if groundCheck.isGrounded && groundCheck.measuredVelocity != Vector2(0, 0):
			linear_velocity = groundCheck.measuredVelocity;

	if forceToApply.length() > 0:
		apply_force(forceToApply);

func _lock_movement (index):
	_locked_movement |= (1 << index);

func _unlock_movement (index):
	_locked_movement &= ~(1 << index);

func _handle_swing (_delta):
	if _grappling:
		gravity_scale = 0;
		linear_velocity = _grappling_velocity();
	else:
		gravity_scale = 1;


func _physics_process(delta):
	_handle_movement(delta);
	_handle_jump(delta);
	_handle_grappling(delta);
	_handle_swing(delta);
