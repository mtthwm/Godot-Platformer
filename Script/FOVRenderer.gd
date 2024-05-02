extends MeshInstance2D

var _origin: Vector2;
var _points: Array[Vector2] = [];

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES);

	for i in range(_points.size() - 1):
		mesh.surface_add_vertex(Vector3(_origin.x, _origin.y, 0));
		mesh.surface_add_vertex(Vector3(_points[i].x, _points[i].y, 0));
		mesh.surface_add_vertex(Vector3(_points[i + 1].x, _points[i + 1].y, 0));

	mesh.surface_end();

func set_points(origin: Vector2, points: Array[Vector2]):
	_origin = origin;
	_points = points;
