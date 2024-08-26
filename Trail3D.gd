class_name Trail3D extends MeshInstance3D

var points := []
var widths := []

@export var trailEnabled := true
@export var fromWidth := 0.5
@export var toWidth := 0.0
@export_range(0.5,1.5) var scaleFactor := 1.0

@export var max_vertices := 100

@export var startColor := Color(1.0,1.0,1.0,1.0)
@export var endColor := Color(1.0,1.0,1.0,0.0)

func _ready():
	mesh = ImmediateMesh.new()

func _process(delta):
	addPoint()
	if points.size() > max_vertices:
		removePoint(0)
	render()

func addPoint():
	points.append(get_global_transform().origin)
	widths.append([get_global_transform().basis.x * fromWidth,
	get_global_transform().basis.x * fromWidth - get_global_transform().basis.x * toWidth])

func removePoint(i):
	points.remove_at(i)
	widths.remove_at(i)

func render():
	mesh.clear_surfaces()
	if points.size() < 2: return
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, null)
	for i in range(points.size()):
		var t = float(i) / (points.size() - 1.0)
		var currColor = startColor.lerp(endColor, 1 - t)
		mesh.surface_set_color(currColor)
		
		var currWidth = widths[i][0] - pow(1 - t, scaleFactor) * widths[i][1]
		
		var t0 = i / points.size()
		
		mesh.surface_set_uv(Vector2(t0, 0))
		mesh.surface_add_vertex(to_local(points[i] + currWidth))
		mesh.surface_set_uv(Vector2(t, 1))
		mesh.surface_add_vertex(to_local(points[i] - currWidth))
	mesh.surface_end()
