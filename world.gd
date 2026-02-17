extends Node2D

# --- SIGNAL FOR SPLIT-SCREEN UI ---
signal match_ended(winner_text)

# --- UI & VISUALS ---
@onready var timer_label = get_node_or_null("CanvasLayer/TimerLabel")
@onready var ring_visual = get_node_or_null("RingVisual")
@onready var minimap_ring = get_node_or_null("CanvasLayer/Minimap/SubViewport/MinimapRing")
@onready var map: Node2D = $Map

# --- DYNAMIC PLAYER TRACKING ---
var active_players = [] 
var game_over = false

# --- PHASE SETTINGS ---
enum Phase { FARM1, SHRINK1, PVP2, SHRINK2, FINAL_PVP, FINAL_SHRINK }
var current_phase = Phase.FARM1
var phase_timer = 60.0 

# --- RING CONSTANTS ---
var possible_centers = [Vector2(1000, 1000), Vector2(1000, -1000), Vector2(-1000, 1000), Vector2(-1000, -1000)]
var current_center = Vector2.ZERO
var target_center = Vector2.ZERO
var chosen_corner = Vector2.ZERO 
var current_radius = 3000.0
var target_radius = 3000.0 
var shrink_speed = 0.0
var move_speed = 0.0
var last_print_time = 0

func _ready():
	# Initial attempt to find players
	link_player_signals()
	_setup_minimap_points()
	start_phase(Phase.FARM1)

# --- CRITICAL FIX: The Connector ---
# We make this a public function so HBox can call it after moving Player 2
func link_player_signals():
	var all_entities = get_tree().get_nodes_in_group("players")
	
	for entity in all_entities:
		if not active_players.has(entity):
			active_players.append(entity)
			print("WORLD: Tracked new entity: ", entity.name)
		
		# Connect the signal if not already connected
		if entity.has_signal("player_died"):
			if not entity.player_died.is_connected(_on_entity_died):
				entity.player_died.connect(_on_entity_died)
				print("WORLD: Connected to death signal of: ", entity.name)
		else:
			print("WORLD WARNING: ", entity.name, " is missing 'player_died' signal!")

# --- DYNAMIC VICTORY LOGIC ---
func _on_entity_died(dead_entity):
	if game_over: return

	print("WORLD DEBUG: Received death signal from ", dead_entity.name)

	# 1. Remove the dead guy from our list
	if active_players.has(dead_entity):
		active_players.erase(dead_entity)
	
	print("WORLD DEBUG: Remaining active entities: ", active_players.size())

	# 2. Check Win Condition
	# If only one entity remains (could be a player or a bot)
	if active_players.size() == 1:
		game_over = true
		var winner = active_players[0]
		var win_text = winner.name.to_upper() + " WINS!"
		
		print("WORLD DEBUG: Winner determined: ", win_text)
		emit_signal("match_ended", win_text)
		
	elif active_players.size() == 0:
		game_over = true
		print("WORLD DEBUG: Draw detected!")
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
		if is_instance_valid(entity) and entity.visible: # Only damage if visible/alive
			var dist = entity.global_position.distance_to(current_center)
			if dist > current_radius:
				if entity.has_method("take_ring_damage"):
					entity.take_ring_damage(5.0 * delta)

# --- THE REST OF YOUR HELPERS (UNCHANGED) ---
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
