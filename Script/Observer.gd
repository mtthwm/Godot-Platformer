extends MeshInstance2D

@export var resolution: int = 64;
@export var polygonCollider: CollisionPolygon2D;
@export var radius: float = 128;
@export var minAngle: float = 0;
@export var maxAngle: float = 360;

var _points: Array[Vector2] = [];

func _ready():
	_generate_collider(_deg2rad(minAngle), _deg2rad(maxAngle));

func _generate_mesh ():
	mesh.clear_surfaces();
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES);

	for i in range(_points.size() - 1):
		mesh.surface_add_vertex(Vector3(0, 0, 0));
		mesh.surface_add_vertex(Vector3(_points[i].x, _points[i].y, 0));
		mesh.surface_add_vertex(Vector3(_points[i + 1].x, _points[i + 1].y, 0));

	mesh.surface_end();	

func _generate_collider (minRads: float, maxRads: float):
	var polygonPoints = [Vector2.ZERO];

	var innerAngle = maxRads - minRads;
	for i in range(resolution + 1):
		var angle = minRads + i * (innerAngle / resolution);
		var localPoint = Vector2.RIGHT.rotated(-angle) * radius;
		polygonPoints.append(localPoint);
	
	polygonCollider.polygon = polygonPoints;

func _deg2rad (degrees: float) -> float:
	return degrees * PI / 180;

func _physics_process(_delta):
	_calc_FOV(_deg2rad(minAngle), _deg2rad(maxAngle));
	_generate_mesh();

func _calc_FOV (minRads: float, maxRads: float) -> void:
	var innerAngle = maxRads - minRads;
	var space_state = get_world_2d().direct_space_state
	_points.clear()
	for i in range(resolution + 1):
		var angle = minRads + i * (innerAngle / resolution);
		var globalPoint = global_position + Vector2.RIGHT.rotated(-angle) * radius;

		var query = PhysicsRayQueryParameters2D.create(global_position, globalPoint);
		var result = space_state.intersect_ray(query);

		if result:
			_points.append(result.position - global_position);
		else:
			_points.append(globalPoint - global_position);
