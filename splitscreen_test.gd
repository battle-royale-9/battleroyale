extends HBoxContainer

@onready var viewport1 = $SubViewportContainer/SubViewport
@onready var viewport2 = $SubViewportContainer2/SubViewport
@onready var camera2 = $SubViewportContainer2/SubViewport/Camera2D

var player2_node = null
var ui_transplanted = false

func _ready():
	# 1. Share the world
	viewport2.world_2d = viewport1.world_2d
	print("SPLIT SCREEN: World Shared.")

func _process(delta):
	# 2. Look for Player 2
	if player2_node == null:
		# DEBUG: Print all children so we can see the REAL names
		if viewport1.get_child_count() > 0:
			# We only print this once to avoid spamming
			if not has_meta("debug_printed"):
				print("--- DEBUGGING PATHS ---")
				print("Viewport 1 Children: ", viewport1.get_children())
				if viewport1.has_node("Node2D"):
					print("Node2D found. Children of Node2D: ", viewport1.get_node("Node2D").get_children())
				else:
					print("ERROR: Could not find 'Node2D' inside Viewport 1!")
				set_meta("debug_printed", true)

		# The search attempt
		if viewport1.has_node("Node2D/Player2"):
			player2_node = viewport1.get_node("Node2D/Player2")
			print("SUCCESS: Player 2 Found!")
	
	# 3. Logic once found
	if player2_node != null:
		camera2.global_position = player2_node.global_position
		
		if ui_transplanted == false:
			if player2_node.has_node("CanvasLayer"):
				var p2_ui = player2_node.get_node("CanvasLayer")
				player2_node.remove_child(p2_ui)
				viewport2.add_child(p2_ui)
				ui_transplanted = true
				print("SUCCESS: UI Transplanted to Screen 2")
			else:
				print("ERROR: Player 2 found, but has no node named 'CanvasLayer'!")
				ui_transplanted = true # Stop trying anyway
