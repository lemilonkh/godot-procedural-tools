extends GridMap

const CHUNK_SIZE = 50
const WALL_HEIGHT = 3

var leaves = []
var halls = []
var root: Leaf

class Leaf:
	const MIN_LEAF_SIZE = 6
	const MAX_LEAF_SIZE = 20
	
	var x: int
	var y: int
	var width: int
	var height: int
	var left_child: Leaf
	var right_child: Leaf
	var room
	var halls = []
	
	func _init(x: int, y: int, width: int, height: int):
		self.x = x
		self.y = y
		self.width = width
		self.height = height
	
	func split() -> bool:
		if left_child != null and right_child != null:
			return false # Leaf is already split
		
		# determine split direction
		# if one dimension exceeds the other by 25%, split along it, otherwise randomly
		var split_h = randf() > 0.5
		if width > height and width / height >= 1.25:
			split_h = false
		elif height > width and height / width >= 1.25:
			split_h = true
		
		var max_dimension = (height if split_h else width) - MIN_LEAF_SIZE
		if max_dimension <= MIN_LEAF_SIZE:
			return false
		
		var split_position = round(rand_range(MIN_LEAF_SIZE, max_dimension))
		
		if split_h:
			left_child = Leaf.new(x, y, width, split_position)
			right_child = Leaf.new(x, y + split_position, width, height - split_position)
		else:
			left_child = Leaf.new(x, y, split_position, height)
			right_child = Leaf.new(x + split_position, y, width - split_position, height)
		
		return true

func create_bsp_tree():
	root = Leaf.new(0, 0, CHUNK_SIZE, CHUNK_SIZE)
	leaves.append(root)
	
	var did_split = true
	
	while did_split:
		did_split = false
		for leaf in leaves:
			if leaf.left_child == null and leaf.right_child == null:
				if leaf.width > Leaf.MAX_LEAF_SIZE || leaf.height > Leaf.MAX_LEAF_SIZE:
					if leaf.split():
						leaves.append(leaf.left_child)
						leaves.append(leaf.right_child)
						did_split = true

func randi_range(start: int, end: int) -> int:
	return int(round(rand_range(start, end)))

func create_hallways(node):
	if node.left_child != null and node.right_child != null:
		halls += create_hall(node.left_child, node.right_child)
		create_hallways(node.left_child)
		create_hallways(node.right_child)

func create_hall(left, right) -> Array:
	var point1 = Vector2(randi_range(left.x, left.x + left.width), randi_range(left.y, left.y + left.height))
	var point2 = Vector2(randi_range(right.x, right.x + right.width), randi_range(right.y, right.y + right.height))
	
	var w = point2.x - point1.x
	var h = point2.y - point1.y
	
	var halls = []
	
	if w < 0:
		if h < 0:
			if randf() < 0.5:
				halls.append(Rect2(point2.x, point1.y, abs(w), 1))
				halls.append(Rect2(point2.x, point2.y, 1, abs(h)))
			else:
				halls.append(Rect2(point2.x, point2.y, abs(w), 1))
				halls.append(Rect2(point1.x, point2.y, 1, abs(h)))
		elif h > 0:
			if randf() < 0.5:
				halls.append(Rect2(point2.x, point1.y, abs(w), 1))
				halls.append(Rect2(point2.x, point1.y, 1, abs(h)))
			else:
				halls.append(Rect2(point2.x, point2.y, abs(w), 1))
				halls.append(Rect2(point1.x, point1.y, 1, abs(h)))
		else:
			halls.append(Rect2(point2.x, point2.y, abs(w), 1))
	elif w > 0:
		if h < 0:
			if randf() < 0.5:
				halls.append(Rect2(point1.x, point2.y, abs(w), 1))
				halls.append(Rect2(point1.x, point2.y, 1, abs(h)))
			else:
				halls.append(Rect2(point1.x, point1.y, abs(w), 1))
				halls.append(Rect2(point2.x, point2.y, 1, abs(h)))
		elif h > 0:
			if randf() < 0.5:
				halls.append(Rect2(point1.x, point1.y, abs(w), 1))
				halls.append(Rect2(point2.x, point1.y, 1, abs(h)))
			else:
				halls.append(Rect2(point1.x, point2.y, abs(w), 1))
				halls.append(Rect2(point1.x, point1.y, 1, abs(h)))
		else:
			halls.append(Rect2(point1.x, point1.y, abs(w), 1))
	else:
		if h < 0:
			halls.append(Rect2(point2.x, point2.y, 1, abs(h)))
		elif h > 0:
			halls.append(Rect2(point1.x, point1.y, 1, abs(h)))
	
	return halls

func render_tree():
	var floor_item = 0
	
	# fill grid with zeroes
	for z in range(-CHUNK_SIZE/2, CHUNK_SIZE/2):
		for x in range(-CHUNK_SIZE/2, CHUNK_SIZE/2):
			set_cell_item(x, 0, z, floor_item)
	
	render_leaf(root)

func render_leaf(leaf):
	var room_item = 1
	var wall_item = 2
	
	if leaf.left_child == null and leaf.right_child == null:
		var z_start = leaf.y - CHUNK_SIZE/2
		var x_start = leaf.x - CHUNK_SIZE/2
		
		# horizontal walls
		for x in range(x_start, x_start + leaf.width):
			for y in range(WALL_HEIGHT):
				set_cell_item(x, y, z_start, wall_item)
				set_cell_item(x, y, z_start + leaf.height, wall_item)
		
		# vertical walls
		for z in range(z_start, z_start + leaf.height):
			for y in range(WALL_HEIGHT):
				set_cell_item(x_start, y, z, wall_item)
				set_cell_item(x_start + leaf.width, y, z, wall_item)
		
		for z in range(z_start, z_start + leaf.height):
			for x in range(x_start, x_start + leaf.width):
				set_cell_item(x, 0, z, room_item)
		
		return
	
	render_leaf(leaf.left_child)
	render_leaf(leaf.right_child)

func render_halls():
	for hall in halls:
		for x in range(hall.position.x, hall.end.x):
			for z in range(hall.position.y, hall.end.y):
				for y in range(1, WALL_HEIGHT):
					set_cell_item(x - CHUNK_SIZE / 2, y, z - CHUNK_SIZE / 2, -1)
	
func _ready():
	randomize()
	create_bsp_tree()
	create_hallways(root)
	render_tree()
	render_halls()
