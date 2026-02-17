extends HBoxContainer

@onready var viewport1 = $SubViewportContainer/SubViewport
@onready var viewport2 = $SubViewportContainer2/SubViewport
@onready var camera2 = $SubViewportContainer2/SubViewport/Camera2D

func _ready():
	# 1. Share the world
	viewport2.world_2d = viewport1.world_2d
	
	# 2. Wait for players to spawn
	await get_tree().create_timer(0.2).timeout
	setup_split_screen()

func setup_split_screen():
	# Find the world node (mapCreation)
	if viewport1.get_child_count() == 0: return
	var world_node = viewport1.get_child(0) 
	
	# Find Player 2
	var player2 = find_node_recursive(world_node, "Player2")
	
	if player2:
		print("SUCCESS: Player 2 found for Split Screen!")
		
		# A. Link Camera 2 to Player 2
		var remote = RemoteTransform2D.new()
		remote.remote_path = camera2.get_path()
		player2.add_child(remote)
		
		# B. MOVE THE UI (The Fix)
		move_player_ui_to_viewport(player2, viewport2)
	else:
		print("ERROR: Player 2 not found.")

# --- HELPER 1: Find Nodes inside folders ---
func find_node_recursive(node, name_to_find):
	if node.name == name_to_find: return node
	for child in node.get_children():
		var found = find_node_recursive(child, name_to_find)
		if found: return found
	return null

# --- HELPER 2: The UI Transplant ---
func move_player_ui_to_viewport(player_node, target_viewport):
	# Look through all children of Player 2
	for child in player_node.get_children():
		# If we find a CanvasLayer (which is what UI uses)
		if child is CanvasLayer:
			print("Transplanting UI: ", child.name)
			
			# 1. Remove it from Player 2 (so it stops showing on Screen 1)
			player_node.remove_child(child)
			
			# 2. Add it to Viewport 2 (so it shows on Screen 2)
			target_viewport.add_child(child)
			return # Stop after moving the first UI we find
	
	print("WARNING: Player 2 has no CanvasLayer/UI to move!")
