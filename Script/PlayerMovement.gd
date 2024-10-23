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
@export var extraJumps = 0;
@export var wallJumpTilePerSec = 6;

@export_group("Grappling")
@export var grappleLengthTiles = 12;
@export var crosshair: Node2D;
@export var grappleSpeed = 16;
@export var minGrappleTileLength = 2
@export var maxGrappleAngle = 70;

@export_group("Diving")
@export var verticalTiles = 1;
@export var horizontalTilesPerSec = 4;

enum MOVE_LOCK_TYPE {
	BOTH,
	LEFT,
	RIGHT
}
var _locked_movement_right: int = 0;
var _locked_movement_left: int = 0;


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
var _hasGrappledThisButtonPress = false;
var _hasWallJumped = false;
var _wallTimer = CooldownTimer.new(0.4);

var _remainingDives: int;

var _wasJustGrappling = false;

# Called when the node enters the scene tree for the first time.
func _ready():
	_maxSpeed = tilesPerSecondSpeed * tilesize;
	_gravity_magnitude = ProjectSettings.get_setting("physics/2d/default_gravity");
	_weight = _gravity_magnitude * mass * gravity_scale;
	_normalForceMagnitude = _weight;  # TODO: MAKE THIS WORK WITH SLANTS
	_jumpHeight = (tilesPerJump * tilesize);
	_maxHorizontalForce = _maxSpeed * mass;

func _can_wall_jump ():
	return _wallTimer.is_available() && !_hasWallJumped && (leftWallChecker.isGrounded  || rightWallChecker.isGrounded) && !groundCheck.isGrounded;

func _can_jump ():
	var canDoubleJump = (_remainingJumps > 0) && Input.is_action_pressed("move_jump");
	return (groundCheck.isGrounded || canDoubleJump) && linear_velocity.y >= 0;

func _should_jump ():
	var justReleased = Input.is_action_just_released("move_jump");
	var heldLongEnough = Input.is_action_pressed("move_jump") && (_timeSincePress > inputMaxFullHoldTime);
	return (justReleased or heldLongEnough) and not _hasJumpedThisButtonPress;

func _do_wall_jump ():
	_remainingJumps += 1;
	_do_jump();
	_hasWallJumped = true;
	var wallJumpVelocity = (tilesize * wallJumpTilePerSec);
	_wallTimer.use();
	if leftWallChecker.isGrounded:
		linear_velocity.x = wallJumpVelocity;
		_lock_movement(2, MOVE_LOCK_TYPE.LEFT);
	elif rightWallChecker.isGrounded:
		linear_velocity.x = -wallJumpVelocity;
		_lock_movement(2, MOVE_LOCK_TYPE.RIGHT);

func _distance_to_velocity (distance, weight):
	return sqrt(2 * weight * distance);

func _do_jump ():
	_remainingJumps -= 1;
	var holdTimeModifier = min(_timeSincePress / inputMaxFullHoldTime, 1);
	var jumpVelocity = _distance_to_velocity(_jumpHeight, _weight) * holdTimeModifier;
	if linear_velocity.y > 0:
		jumpVelocity += linear_velocity.y;
	linear_velocity.y -= jumpVelocity;
	_hasJumpedThisButtonPress = true;

func _handle_jump (delta):
	_timeSincePress += delta;

	if !(rightWallChecker.isGrounded || leftWallChecker.isGrounded):
		_hasWallJumped = false;

	if _wallTimer.is_available():
		_unlock_movement(2, MOVE_LOCK_TYPE.BOTH);
	
	if groundCheck.isGrounded:
		_remainingJumps = extraJumps;

	if Input.is_action_just_pressed("move_jump"):
		_timeSincePress = 0;

	if _can_wall_jump() and _should_jump():
		_do_wall_jump();
	elif  _can_jump() and _should_jump():
		_do_jump();

	if Input.is_action_just_released("move_jump"):
		_hasJumpedThisButtonPress = false;

func _cast_grapple_ray ():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, _grapplePoint);
	var result = space_state.intersect_ray(query);
	return result;

func _is_within_grapple_range (grapplePoint):
	return position.distance_to(grapplePoint) > minGrappleTileLength * tilesize

func _handle_crosshair (grappleRayResult: Dictionary):
	
	if !_grappling:
		if grappleRayResult && _is_within_grapple_range(grappleRayResult.position):
			crosshair.set_global_position(grappleRayResult.position);
			crosshair.show();
		else:
			crosshair.hide();
	else:
		crosshair.set_global_position(_grapplePoint);
	

func _handle_grappling (_delta):
	if Input.is_action_pressed("move_right"):
		_grappleDir = Vector2(0.5, -1).normalized()

	if Input.is_action_pressed("move_left"):
		_grappleDir = Vector2(-0.5, -1).normalized()

	if !_grappling:
		_grappleDir = _grappleDir.normalized();
		_grapplePoint = global_position + _grappleDir * grappleLengthTiles * tilesize;

	if groundCheck.isGrounded:
		_wasJustGrappling = false;

	var grappleRayResult = _cast_grapple_ray();
	_handle_crosshair(grappleRayResult);

	if Input.is_action_pressed("move_grapple"):
		_lock_movement(3, MOVE_LOCK_TYPE.BOTH);
		
		if !_grappling:
			if !_hasGrappledThisButtonPress && grappleRayResult && _is_within_grapple_range(grappleRayResult.position):
				_grapplePoint = grappleRayResult.position;
				_grappling = true;
				_wasJustGrappling = true;
				_hasGrappledThisButtonPress = true;
				_remainingJumps = extraJumps;
				_lock_movement(5, MOVE_LOCK_TYPE.BOTH);
	else:
		_unlock_movement(3, MOVE_LOCK_TYPE.BOTH);
		_hasGrappledThisButtonPress = false;

	if _grappling:
		var touchingAnything: bool = (groundCheck.isGrounded || leftWallChecker.isGrounded || rightWallChecker.isGrounded || ceilingChecker.isGrounded);
		var grappleAngle = abs(Vector2.UP.angle_to((_grapplePoint - global_position).normalized()));
		var maxAngleExceeded = grappleAngle > deg_to_rad(maxGrappleAngle);
		if maxAngleExceeded || touchingAnything || !Input.is_action_pressed("move_grapple") || Input.is_action_pressed("move_jump"):
			_grappling = false;
			_unlock_movement(5, MOVE_LOCK_TYPE.BOTH);
			_grappling = false;
			
func _grappling_velocity ():
	var toGrapplePoint = (_grapplePoint - global_position).normalized();
	var rotateAngle = PI/2;
	if _grappleDir.x < 0:
		rotateAngle = -rotateAngle;
	var tangent = toGrapplePoint.rotated(rotateAngle);
	return grappleSpeed * tilesize * tangent;

func _locked_both_movement():
	return _locked_movement_left && _locked_movement_right;

func _locked_either_movement():
	return _locked_movement_left || _locked_movement_right;

func _handle_movement (_delta):
	var movement_force_magnitude = (_maxSpeed / timeToMaxSpeed) * mass + _normalForceMagnitude;
	var frictional_force_magnitude = _normalForceMagnitude * physics_material_override.friction;
	var horizontalForce = movement_force_magnitude + frictional_force_magnitude;
	var forceToApply = Vector2(0, 0);

	if Input.is_action_pressed("move_right") && !_locked_movement_right:
		if linear_velocity.x < _maxSpeed:
			forceToApply.x += horizontalForce;

	elif Input.is_action_pressed("move_left") && !_locked_movement_left:
		if linear_velocity.x > -_maxSpeed:
			forceToApply.x -= horizontalForce;

	if forceToApply.length() > 0:
		apply_force(forceToApply);

	print_debug(_wasJustGrappling);

	if !_wasJustGrappling && !_locked_either_movement() && !(Input.is_action_pressed("move_right") or Input.is_action_pressed("move_left")):
		linear_velocity.x = 0;

func _lock_movement (index, type):
	if type == MOVE_LOCK_TYPE.BOTH || type == MOVE_LOCK_TYPE.LEFT:
		_locked_movement_left |= (1 << index);
	if type == MOVE_LOCK_TYPE.BOTH || type == MOVE_LOCK_TYPE.RIGHT:
		_locked_movement_right |= (1 << index);

func _unlock_movement (index, type):
	if type == MOVE_LOCK_TYPE.BOTH || type == MOVE_LOCK_TYPE.LEFT:
		_locked_movement_left &= ~(1 << index);
	if type == MOVE_LOCK_TYPE.BOTH || type == MOVE_LOCK_TYPE.RIGHT:
		_locked_movement_right &= ~(1 << index);
	

func _handle_swing (_delta):
	if _grappling:
		gravity_scale = 0;
		linear_velocity = _grappling_velocity();
	else:
		gravity_scale = 1;

func _can_dive ():
	return Input.is_action_just_pressed("move_dive") && _remainingDives > 0 && !groundCheck.isGrounded;

func _do_dive ():
	if Input.is_action_pressed("move_left"):
		linear_velocity.x -= horizontalTilesPerSec * tilesize;
	elif Input.is_action_pressed("move_right"):
		linear_velocity.x += horizontalTilesPerSec * tilesize;

	if Input.is_action_pressed("move_left") || Input.is_action_pressed("move_right"):
		linear_velocity.y = -_distance_to_velocity(verticalTiles * tilesize, _weight);
		_remainingDives -= 1;


func _handle_diving(_delta):
	if _can_dive():
		_do_dive();

	if groundCheck.isGrounded:
		_remainingDives = 1;

func _physics_process(delta):
	_wallTimer.run_timer(delta);

	_handle_movement(delta);
	_handle_jump(delta);
	_handle_grappling(delta);
	_handle_swing(delta);
	_handle_diving(delta);

