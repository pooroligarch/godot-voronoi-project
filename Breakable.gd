extends CharacterBody3D
@export var perf_test := false
@export var random_seed := ""

func random_points_in_box(amount: int, start: Vector3, end: Vector3, p_seed := ""):
	if p_seed != "":
		seed(hash(p_seed))
	var array = PackedVector3Array()
	for i in range(amount):
		var vec = Vector3(
		randf_range(start.x, end.x),
		randf_range(start.y, end.y),
		randf_range(start.z, end.z))
		array.append(vec)
	return array
	
func _ready():
	slice()

func slice():
	var voro = Voronoi.new()
	
	var og_xform = $MeshInstance3D.global_transform
	$MeshInstance3D.global_transform = Transform3D()
	var bounds = $MeshInstance3D.get_aabb().abs()
	
	var time : int
	var start_time : int
	var time2 : int
	if perf_test:
		time = Time.get_ticks_msec()
		start_time = time

	voro.setup(bounds.position, bounds.end)
	var points = random_points_in_box(10, bounds.position, bounds.end, random_seed)
	for point in points:
		if point > (bounds.end) or point < (bounds.position):
			print("Point out of bounds!")

	voro.set_points(points) # problem here?
	print(voro.compute())

	var slicer = Slicer.new()

#	if perf_test:
#		time2 = Time.get_ticks_msec()
#		print("Voronoi: " + str(time2 - time))
#		time = time2

	var positions = voro.compute() # result should be cached
	var positions_read := 0
	var last_was_zero := false

	var mesh = $MeshInstance3D.duplicate()
	var body = RigidDynamicBody3D.new()

	for i in range(positions.size()):
		var pos := positions[i]
		if pos == Vector3():
			positions_read = 0
			if last_was_zero: # new frag
				if mesh.mesh != $MeshInstance3D.mesh:
					body.global_transform = og_xform
					body.add_child(mesh)
					body.freeze = true
					get_parent().call_deferred("add_child", body)
			last_was_zero = true
		else:
			positions_read += 1
			if positions_read == 3:
				var plane = Plane(pos, positions[i-1], positions[i-2])
#				if plane.is_point_over(point):
#					plane = -plane

				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(randf(), randf(), randf())
				mesh.set_surface_override_material(0, mat)

				var sliced = slicer.slice_by_plane(mesh.mesh, plane, mat)
				if sliced:
					mesh.mesh = sliced.lower_mesh

#	if perf_test:
#		time2 = Time.get_ticks_msec()
#		print("Slicer: " + str(time2 - time))
#		print("Total: " + str(time2 - start_time))
	queue_free()
