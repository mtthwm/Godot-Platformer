extends MeshInstance2D

@export var resolution: int = 64;
@export var polygonCollider: CollisionPolygon2D;
@export var radius: float = 128;
@export var rangeRadians: float = PI * 2;

var _points: Array[Vector2] = [];

func _ready():
	pass

func _generate_mesh ():
	mesh.clear_surfaces();
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES);

	for i in range(_points.size() - 1):
		mesh.surface_add_vertex(Vector3(global_position.x, global_position.y, 0));
		mesh.surface_add_vertex(Vector3(_points[i].x, _points[i].y, 0));
		mesh.surface_add_vertex(Vector3(_points[i + 1].x, _points[i + 1].y, 0));

	mesh.surface_end();	

func _physics_process(_delta):
	_calc_FOV(rangeRadians);
	_generate_mesh();

func _calc_FOV (innerAngle: float) -> void:
	var space_state = get_world_2d().direct_space_state
	_points.clear()
	for i in range(resolution + 1):
		var angle = i * (innerAngle / resolution);
		var globalPoint = global_position + Vector2.RIGHT.rotated(angle) * radius;

		var query = PhysicsRayQueryParameters2D.create(global_position, globalPoint);
		var result = space_state.intersect_ray(query);

		if result:
			_points.append(result.position);
		else:
			_points.append(globalPoint);
