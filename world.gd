extends Node2D

# --- SIGNAL FOR SPLIT-SCREEN UI ---
signal match_ended(winner_text)

# --- UI & VISUALS ---
@onready var timer_label = get_node_or_null("CanvasLayer/TimerLabel")
@onready var ring_visual = get_node_or_null("RingVisual")
@onready var minimap_ring = get_node_or_null("CanvasLayer/Minimap/SubViewport/MinimapRing")
@onready var map: Node2D = $Map

# --- SPAWN POINT REFERENCE ---
# Make sure you have a Node named "SpawnPoints" holding Marker2Ds in your scene
@onready var spawn_point_container = get_node_or_null("SpawnPoints")

# --- DYNAMIC PLAYER TRACKING ---
var active_players = [] 
var game_over = false

# --- PHASE SETTINGS ---
enum Phase { FARM1, SHRINK1, PVP2, SHRINK2, FINAL_PVP, FINAL_SHRINK }
var current_phase = Phase.FARM1
var phase_timer = 1

# --- RING CONSTANTS ---
var possible_centers = [Vector2(0, 0)]
var current_center = Vector2.ZERO
var target_center = Vector2.ZERO
var chosen_corner = Vector2.ZERO 
var current_radius = 3000.0
var target_radius = 3000.0 
var shrink_speed = 0.0
var move_speed = 0.0
var last_print_time = 0

func _ready():
	# 1. Find players and link signals
	link_player_signals()
	
	# 2. Setup visual aids
	_setup_minimap_points()
	
	# 3. Teleport players to random spots
	spawn_players()
	
	# 4. Start the game loop
	start_phase(Phase.FARM1)

# --- CRITICAL FIX: The Connector ---
func link_player_signals():
	var all_entities = get_tree().get_nodes_in_group("players")
	
	for entity in all_entities:
		if not active_players.has(entity):
			active_players.append(entity)
		
		if entity.has_signal("player_died"):
			if not entity.player_died.is_connected(_on_entity_died):
				entity.player_died.connect(_on_entity_died)

# --- SPAWN LOGIC (NEW) ---
func spawn_players():
	if not spawn_point_container:
		print("WORLD ERROR: 'SpawnPoints' node is missing from the scene!")
		return

	# 1. Get all Marker2D nodes
	var available_spawns = spawn_point_container.get_children()
	
	# 2. Shuffle them to make it random
	available_spawns.shuffle()
	
	# 3. Check if we have enough points
	if available_spawns.size() < active_players.size():
		print("WORLD WARNING: Not enough spawn points for all players!")

	# 4. Assign positions
	for i in range(active_players.size()):
		var player = active_players[i]
		
		# Stop if we run out of spawn points
		if available_spawns.is_empty():
			break
			
		# Pick the last spawn point from the list and remove it (so no duplicates)
		var chosen_spawn = available_spawns.pop_back()
		
		# A. Teleport the visual body
		player.global_position = chosen_spawn.global_position
		
		# B. CRITICAL: Update the click-to-move target to prevent walking back
		if "target_position" in player:
			player.target_position = player.global_position

# --- DYNAMIC VICTORY LOGIC ---
func _on_entity_died(dead_entity):
	if game_over: return
	if active_players.has(dead_entity):
		active_players.erase(dead_entity)
	print(len(active_players))
	
	# Check Win Condition
	if active_players.size() == 1:
		game_over = true
		var winner = active_players[0]
		var win_text = winner.name.to_upper() + " WINS!"
		emit_signal("match_ended", win_text)
		
	elif active_players.size() == 0:
		game_over = true
		emit_signal("match_ended", "DRAW!")

# --- GAME LOOP ---
func _process(delta):
	if game_over: return
	
	phase_timer -= delta
	if floor(phase_timer) != last_print_time:
		last_print_time = floor(phase_timer)
		if timer_label:
			timer_label.text = "Phase: " + Phase.keys()[current_phase] + " | " + str(int(phase_timer)) + "s"

	if phase_timer <= 0:
		advance_phase()
		
	if current_phase in [Phase.SHRINK1, Phase.SHRINK2, Phase.FINAL_SHRINK]:
		current_radius = move_toward(current_radius, target_radius, shrink_speed * delta)
		current_center = current_center.move_toward(target_center, move_speed * delta)

	if ring_visual:
		ring_visual.material.set_shader_parameter("center", current_center)
		ring_visual.material.set_shader_parameter("radius", current_radius)
	if minimap_ring:
		minimap_ring.global_position = current_center
		minimap_ring.scale = Vector2(current_radius, current_radius)

	# Damage loop
	for entity in active_players:
		if is_instance_valid(entity) and entity.visible:
			var dist = entity.global_position.distance_to(current_center)
			if dist > current_radius:
				if entity.has_method("take_ring_damage"):
					entity.take_ring_damage(5.0 * delta)

# --- HELPERS ---
func start_phase(new_phase):
	current_phase = new_phase
	match current_phase:
		Phase.FARM1: phase_timer = 60.0
		Phase.SHRINK1:
			phase_timer = 45.0
			select_fixed_sub_circle(1500.0) 
		Phase.PVP2: phase_timer = 60.0
		Phase.SHRINK2:
			phase_timer = 45.0
			select_fixed_sub_circle(500.0)
		Phase.FINAL_PVP: phase_timer = 30.0
		Phase.FINAL_SHRINK:
			phase_timer = 30.0
			target_radius = 0.0
			target_center = chosen_corner if chosen_corner != Vector2.ZERO else current_center
			shrink_speed = current_radius / phase_timer
			move_speed = current_center.distance_to(target_center) / phase_timer

func select_fixed_sub_circle(new_radius: float):
	if chosen_corner == Vector2.ZERO: chosen_corner = possible_centers.pick_random()
	target_center = chosen_corner
	target_radius = new_radius
	move_speed = current_center.distance_to(target_center) / phase_timer
	shrink_speed = (current_radius - target_radius) / phase_timer

func advance_phase():
	var total_phases = Phase.size() 
	var next_idx = int(current_phase) + 1
	if next_idx < total_phases: start_phase(next_idx as Phase)

func _setup_minimap_points():
	if not minimap_ring: return
	var points = PackedVector2Array()
	for i in range(65):
		var angle = deg_to_rad(i * (360.0 / 64.0))
		points.push_back(Vector2(cos(angle), sin(angle)))
	minimap_ring.points = points
