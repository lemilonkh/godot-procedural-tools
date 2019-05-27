extends StaticBody

export var size = 100
export var size_scale = 1
export var amplitude = 5
export var object_count = 10
export var chunk_position = Vector3(0, 0, 0)

var noise_helper = preload("res://scripts/noise_helper.gd")
var terrain_objects = preload("res://scene/TerrainObjects.tscn")

var thread = Thread.new()
var mesh_instance
var noise
var heightmap = {}
var objects
var will_despawn = false

func _ready():
	mesh_instance = get_node("MeshInstance")
	#objects = get_node("Objects").get_children()
	objects = terrain_objects.instance().get_children()
	
	translate(chunk_position * size)
	
	# TODO use separate randomness generators for chunks and seed with base seed + chunk position
	randomize()
	
	noise = OpenSimplexNoise.new()
	noise.seed = 6 #randi()
	noise.octaves = 4
	noise.period = 10.0
	noise.persistence = 0.4
	noise.lacunarity = 0.8
	
	thread.start(self, "generate")

func generate(arg):
	var vertices = generate_mesh()
	generate_collision(vertices)
	call_deferred("_on_generated")
	return vertices

func despawn():
	get_parent().remove_child(self)
	
	if !thread.is_active():
		queue_free()
	else:
		will_despawn = true

func _on_generated():
	var vertices = thread.wait_to_finish()
	
	if will_despawn:
		queue_free()
	else:
		generate_objects(vertices)

func get_height(x: float, z: float) -> float:
	x += size * chunk_position.x
	z += size * chunk_position.z
	
	var height = 4 * noise_helper.ridged_multifractal(Vector3(x, 0, z) / 2.5, noise, 1, 0.65, 6) - 150
	#var height = noise.get_noise_2d(x, z) * amplitude
	
	return height

func generate_smooth_mesh() -> PoolVector3Array:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	surface_tool.add_smooth_group(true)
	
	var vertices = PoolVector3Array()
	var vertex_index = 0

	var hsize = size / 2

	for x in range(-hsize, hsize):
		for z in range(-hsize, hsize):
			var y = get_height(x, z)
			var vertex = Vector3(x, y, z)
			vertices.append(vertex)
			surface_tool.add_vertex(vertex)
			surface_tool.add_index(vertex_index)
			surface_tool.add_index(vertex_index + size)
			surface_tool.add_index(vertex_index + 1)
			surface_tool.add_index(vertex_index + 1)
			surface_tool.add_index(vertex_index + size)
			surface_tool.add_index(vertex_index + size + 1)
			
			vertex_index += 1
	
	surface_tool.generate_normals()
	var final_mesh = surface_tool.commit()
	mesh_instance.set_mesh(final_mesh)
	return vertices

func generate_mesh() -> PoolVector3Array:
	var surface_tool = SurfaceTool.new()
	var plane_mesh = PlaneMesh.new()
	plane_mesh.subdivide_width = size
	plane_mesh.subdivide_depth = size
	plane_mesh.size = Vector2(size, size) * size_scale
	surface_tool.create_from(plane_mesh, 0)
	var plane = surface_tool.commit()
	var vertices = PoolVector3Array()
	
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(plane, 0)
	for v in range(mesh_data_tool.get_vertex_count()):
		var vertex = mesh_data_tool.get_vertex(v)
		vertex.y = get_height(vertex.x, vertex.z)
		mesh_data_tool.set_vertex(v, vertex)
		vertices.append(vertex)
		
		if heightmap.get(int(vertex.x)) == null:
			heightmap[int(vertex.x)] = {}
		heightmap[int(vertex.x)][int(vertex.z)] = vertex.y
	
	for surface in range(plane.get_surface_count()):
		plane.surface_remove(surface)
	
	mesh_data_tool.commit_to_surface(plane)
	surface_tool.create_from(plane, 0)
	surface_tool.index()
	surface_tool.generate_normals()
	
	var final_mesh = surface_tool.commit()
	mesh_instance.set_mesh(final_mesh)
	return vertices
	
func generate_collision(vertices: PoolVector3Array):
	var shape = ConcavePolygonShape.new()
	shape.set_faces(vertices)
	var shape_owner: int = create_shape_owner(self)
	shape_owner_add_shape(shape_owner, shape)

func generate_objects(vertices: PoolVector3Array):
	for i in range(object_count):
		var vertex_index = randi() % vertices.size()
		var vertex = vertices[vertex_index]
		var object_index = randi() % objects.size()
		var object = objects[object_index]
		var horizontal_scale = 2 * randf() + 0.5
		var scale = Vector3(horizontal_scale, 2 * randf() + 0.5, horizontal_scale)
		var clone = object.duplicate()
		
#		var min_height = vertex.y
#		var aabb = clone.get_node("Mesh").get_aabb()
#		for corner_index in range(0,4):
#			var corner = aabb.get_endpoint(corner_index)
#			var heightmap_pos = (corner + vertex).round()
#
#			var corner_row = heightmap.get(int(heightmap_pos.x))
#
#			if corner_row == null:
#				continue
#
#			var corner_height = corner_row.get(int(heightmap_pos.z))
#
#			if corner_height == null:
#				continue
#
#			if corner_height < min_height:
#				min_height = corner.y
#
#		vertex.y = min_height
		
		#var mesh = clone.get_node("Mesh")
		#var material = mesh.get_surface_material(0).duplicate()
		#material.set_albedo(Color(randf(), randf(), randf(), rand_range(0.2, 0.7)))
		#mesh.set_surface_material(0, material)
		
		clone.set_visible(true)
		clone.set_translation(vertex)
		clone.set_scale(scale)
		add_child(clone)