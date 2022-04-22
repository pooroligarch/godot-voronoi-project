extends CharacterBody3D

func random_points_in_box(amount: int, start: Vector3, end: Vector3, p_seed := "", margin: float = 0.001):
	if p_seed != "":
		seed(hash(p_seed))
	var array = PackedVector3Array()
	for i in range(amount):
		var vec = Vector3(
		randf_range(start.x - margin, end.x + margin),
		randf_range(start.y - margin, end.y + margin),
		randf_range(start.z - margin, end.z + margin))
		array.append(vec)
	return array
	
func _ready():
	slice()

func slice():
	var meshinstance = $MeshInstance3D
	var voro = Voronoi.new()
	var bounds = meshinstance.get_aabb().abs()
	
	var og_xform = global_transform
	
	voro.setup(bounds.position, bounds.end)
	var points = random_points_in_box(10, bounds.position, bounds.end)
	for point in points:
		if point > (bounds.end) or point < (bounds.position):
			print("Point out of bounds!")
	
	voro.set_points(points)
	voro.compute()
#	problem above this line
#	var face1 = voro.get_face(0, 0)
#	var face2 = voro.get_face(0, 1)

	var slicer = Slicer.new()
	
	var file = File.new()
	file.open("voronoi.out", File.READ)
	
	#var face = PackedVector3Array()
	
	while !file.eof_reached():
		var mesh = $MeshInstance3D.duplicate()
		var body = RigidDynamicBody3D.new()
		
		
		var line = file.get_line()
		
		var split = line.split(";")
		mesh.global_transform = Transform3D()
		
		if split.size() == 3:
			var point_str = split[0].split(" ")
			var point = Vector3(point_str[0].to_float(), point_str[1].to_float(), point_str[2].to_float())
			
			var positions_str = split[1].split(" ")
			var positions = PackedVector3Array()
			for pos in positions_str:
				var pos_split = pos.split(",")
				# remove parentheses
				positions.append(Vector3(pos_split[0].substr(1).to_float(), pos_split[1].to_float(), pos_split[2].substr(0, pos_split[2].length()-1).to_float()))
			
			var faces_str = split[2].split(" ")
			
			for face_str in faces_str:
				var face = face_str.substr(1, face_str.length()-1).split(",")
				
				if face.size() >= 3:
					
					var plane = Plane(positions[face[0].to_int()], positions[face[1].to_int()], positions[face[2].to_int()])
					
					if plane.is_point_over(point):
						plane = -plane

					var mat = StandardMaterial3D.new()
					mat.albedo_color = Color(randf(), randf(), randf())
					mesh.mesh.surface_set_material(0, mat)

					var sliced = slicer.slice_by_plane(mesh.mesh, plane, mat)
					if sliced:
						mesh.mesh = sliced.lower_mesh
			if mesh.mesh != $MeshInstance3D.mesh:
				body.global_transform = og_xform
				body.add_child(mesh)
				body.freeze = true
				get_parent().call_deferred("add_child", body)
			
	queue_free()
