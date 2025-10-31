@tool
class_name VoxelMesh
extends Node3D

@export var noise_texture: FastNoiseLite:
	set(value):
		noise_texture = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var chunk_size: Vector3 = Vector3(8,8,8):
	set(value):
		chunk_size = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var noise_scale: float = 1.0:
	set(value):
		noise_scale = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var threshold: float = 0.5:
	set(value):
		threshold = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var material : Material:
	set(value):
		material = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var collision_enabled : bool = true:
	set(value):
		collision_enabled = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var offset : Vector3 = Vector3.ZERO: # Important: Initialize offset to ZERO
	set(value):
		offset = value
		if Engine.is_editor_hint():
			generate_landscape()

@export var visibility_range : float

@export var inverse : bool = false:
	set(value):
		inverse = value
		if Engine.is_editor_hint():
			generate_landscape()


func _ready():
	generate_landscape()

# Function to generate the landscape based on 3D noise
func generate_landscape():
	# Clear any previous children (old landscape chunks)
	for child in get_children():
		child.queue_free()

	# Create a new ArrayMesh to store the geometry
	var mesh = ArrayMesh.new()
	# Create a SurfaceTool to build the geometry (vertices, indices, etc.)
	var surface = SurfaceTool.new()
	# Begin building, using Triangle primitives
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Check for invalid chunk sizes
	if chunk_size.x <= 0 or chunk_size.y <= 0 or chunk_size.z <= 0:
		return

	#var cube_count = 0 # Commented out: cube counter
	var vertex_count = 0 # Tracks the vertex offset for each new cube (important for indices)

	# Iterate over all positions within the defined chunk size
	for x in range(int(chunk_size.x)):
		for y in range(int(chunk_size.y)):
			for z in range(int(chunk_size.z)):
				# Add offset to the noise sample coordinates, typically for chunking purposes
				var noise_value = noise_texture.get_noise_3d((x + offset.x) * noise_scale, (y + offset.y) * noise_scale, (z + offset.z) * noise_scale)
				
				# Invert the noise value if specified
				if inverse:
					noise_value = - noise_value

				# If the noise value exceeds the threshold, place a cube here
				if noise_value > threshold:
					# Add the cube geometry to the SurfaceTool
					add_cube(surface, Vector3(x, y, z), vertex_count)
					#cube_count += 1
					# Increment the vertex offset by 8, as each cube adds 8 vertices
					vertex_count += 8

	# Calculate normals for correct lighting
	surface.generate_normals()  # Important for proper lighting
	
	# Finish building, commit the arrays, and add them as a surface to the Mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface.commit_to_arrays())
	
	# Create a MeshInstance3D to display the generated mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh
	add_child(mesh_instance)
	
	# Apply the specified material
	mesh_instance.material_override = material
	# Set the visibility range
	mesh_instance.visibility_range_end = visibility_range
	
	# Create trimesh collision if collision is enabled
	if collision_enabled:
		mesh_instance.create_trimesh_collision()


# Function to add the geometry of a single cube to the SurfaceTool
func add_cube(surface: SurfaceTool, position: Vector3, vertex_offset: int):
	# Define the 8 vertices of the cube relative to its position
	var vertices = [
		position + Vector3(0, 0, 0), #0: Near bottom left
		position + Vector3(1, 0, 0), #1: Near bottom right
		position + Vector3(1, 1, 0), #2: Near top right
		position + Vector3(0, 1, 0), #3: Near top left
		position + Vector3(0, 0, 1), #4: Far bottom left
		position + Vector3(1, 0, 1), #5: Far bottom right
		position + Vector3(1, 1, 1), #6: Far top right
		position + Vector3(0, 1, 1)  #7: Far top left
	]

	# Define the indices forming 12 triangles (6 faces * 2 triangles per face)
	var indices = [
		0, 1, 2,   0, 2, 3,   # Front face
		4, 6, 5,   4, 7, 6,   # Back face
		0, 4, 5,   0, 5, 1,   # Bottom face
		3, 2, 6,   3, 6, 7,   # Top face
		0, 3, 7,   0, 7, 4,   # Left face
		1, 5, 6,   1, 6, 2    # Right face
	]

	# Add the 8 vertices to the SurfaceTool
	for vertex in vertices:
		surface.add_vertex(vertex)

	# Add the 36 indices (12 triangles * 3 vertices), offset by vertex_offset
	for index in indices:
		surface.add_index(index + vertex_offset)
