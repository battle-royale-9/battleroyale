extends HBoxContainer

@onready var viewport1 = $SubViewportContainer/SubViewport
@onready var viewport2 = $SubViewportContainer2/SubViewport
@onready var camera2 = $SubViewportContainer2/SubViewport/Camera2D

var label_p1 : Label
var label_p2 : Label

func _ready():
	create_split_game_over_ui()
	viewport2.world_2d = viewport1.world_2d
	await get_tree().create_timer(0.2).timeout
	setup_split_screen()

func create_split_game_over_ui():
	var overlay = CanvasLayer.new()
	overlay.layer = 100 
	add_child(overlay)
	
	var screen_size = get_viewport().get_visible_rect().size
	
	label_p1 = Label.new()
	label_p1.z_index = 5
	label_p1.add_theme_font_size_override("font_size", 80)
	label_p1.add_theme_color_override("font_outline_color", Color.BLACK)
	label_p1.add_theme_constant_override("outline_size", 12)
	label_p1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_p1.visible = false
	label_p1.custom_minimum_size = Vector2(400, 100)
	label_p1.position = Vector2(screen_size.x * 0.25 - 200, screen_size.y * 0.4)
	overlay.add_child(label_p1)

	label_p2 = Label.new()
	label_p2.z_index = 5
	label_p2.add_theme_font_size_override("font_size", 80)
	label_p2.add_theme_color_override("font_outline_color", Color.BLACK)
	label_p2.add_theme_constant_override("outline_size", 12)
	label_p2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label_p2.visible = false
	label_p2.custom_minimum_size = Vector2(400, 100)
	label_p2.position = Vector2(screen_size.x * 0.75 - 200, screen_size.y * 0.4)
	overlay.add_child(label_p2)

func setup_split_screen():
	if viewport1.get_child_count() == 0: return
	var world_node = viewport1.get_child(0)
	
	# Connect World match end signal
	if not world_node.is_connected("match_ended", _on_match_ended):
		world_node.match_ended.connect(_on_match_ended)
	
	# --- NEW: Connect individual player deaths for instant UI ---
	var all_entities = get_tree().get_nodes_in_group("players")
	for entity in all_entities:
		if entity.has_signal("player_died"):
			if not entity.player_died.is_connected(_on_individual_death):
				entity.player_died.connect(_on_individual_death)
	
	var player2 = find_node_recursive(world_node, "Player2")
	if player2:
		var remote = RemoteTransform2D.new()
		remote.remote_path = camera2.get_path()
		player2.add_child(remote)
		move_player_ui_to_viewport(player2, viewport2)

# --- INSTANT FEEDBACK LOGIC ---
func _on_individual_death(dead_entity):
	# If the match already fully ended, don't overwrite winner text
	if label_p1.text == "WINNER!" or label_p2.text == "WINNER!": return

	if "Player1" in dead_entity.name:
		label_p1.text = "YOU DIED"
		label_p1.modulate = Color.RED
		label_p1.visible = true
	elif "Player2" in dead_entity.name:
		label_p2.text = "YOU DIED"
		label_p2.modulate = Color.RED
		label_p2.visible = true

# --- FINAL MATCH END LOGIC ---
func _on_match_ended(text: String):
	label_p1.visible = true
	label_p2.visible = true
	
	var result = text.to_upper()
	
	if "PLAYER1" in result or "PLAYER 1" in result:
		label_p1.text = "WINNER!"
		label_p1.modulate = Color.GOLD
		# In case P2 was still alive and bot died last
		if label_p2.text != "WINNER!":
			label_p2.text = "YOU DIED"
			label_p2.modulate = Color.RED
		return

	if "PLAYER2" in result or "PLAYER 2" in result:
		label_p2.text = "WINNER!"
		label_p2.modulate = Color.GOLD
		# In case P1 was still alive and bot died last
		if label_p1.text != "WINNER!":
			label_p1.text = "YOU DIED"
			label_p1.modulate = Color.RED
		return

	# If a bot wins or draw
	if label_p1.text != "WINNER!": label_p1.text = "YOU DIED"
	if label_p2.text != "WINNER!": label_p2.text = "YOU DIED"

# --- HELPERS ---
func find_node_recursive(node, name_to_find):
	if node.name == name_to_find: return node
	for child in node.get_children():
		var found = find_node_recursive(child, name_to_find)
		if found: return found
	return null

func move_player_ui_to_viewport(player_node, target_viewport):
	for child in player_node.get_children():
		if child is CanvasLayer:
			player_node.remove_child(child)
			target_viewport.add_child(child)
			return
