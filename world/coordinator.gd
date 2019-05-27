extends Spatial

export(NodePath) var player_node
export(float, 0, 1000, 1) var despawn_distance = 200
export(float, 0, 200, 1) var spawn_distance = 150
export(int, 0, 500) var chunk_size = 100

var terrain_scene = preload("res://scene/Terrain.tscn")
var terrain_grid = {}
var player

func _ready():
	player = get_node(player_node)
	
	make_terrain(Vector3(0, 0, 0))

func _process(delta):
	var player_position = player.get_global_transform().origin
	player_position.y = 0
	
	# despawn far away terrain
	for terrain in get_children():
		var terrain_position = terrain.get_global_transform().origin
		terrain_position.y = 0
		
		var distance = (player_position - terrain_position).length()
		
		if distance > despawn_distance:
			var chunk_position = terrain.chunk_position
			print("Despawn at ", chunk_position)
			terrain_grid[chunk_position.x][chunk_position.z] = null
			terrain.despawn() # TODO fade out/ obscure view?
	
	# spawn new terrain around player if necessary
	var player_chunk = (player_position / chunk_size).round()

	# custom order so current and adjacent chunks will be spawned first
	#var chunk_indices = [[0, 0], [0, -1], [-1, 0], [1, 0], [0, 1], [1, -1], [-1, -1], [1, 1], [-1, 1]]
	#for chunk_index in chunk_indices:
	for z in range(-1, 2):
		for x in range(-1, 2):
			var chunk_x = player_chunk.x + x #chunk_index[0]
			var chunk_z = player_chunk.z + z #chunk_index[1]
			var chunk_position = Vector3(chunk_x, 0, chunk_z)
			var chunk_world_position = chunk_position * chunk_size
			var distance = (player_position - chunk_world_position).length()
			
			if distance < spawn_distance:
				if terrain_grid.get(chunk_x) == null or terrain_grid[chunk_x].get(chunk_z) == null:
					print("Spawning chunk ", chunk_x, "/", chunk_z)
					make_terrain(chunk_position)
	
func make_terrain(chunk_position: Vector3) -> Node:
	var terrain = terrain_scene.instance()
	terrain.chunk_position = chunk_position
	terrain.size = chunk_size
	
	if terrain_grid.get(chunk_position.x) == null:
		terrain_grid[chunk_position.x] = {}
	
	terrain_grid[chunk_position.x][chunk_position.z] = terrain
	add_child(terrain)
	
	return terrain
