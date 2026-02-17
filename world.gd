extends Node2D

# --- UI & VISUALS (Safe Mode) ---
# We use 'get_node_or_null' so the game doesn't crash if these are missing
@onready var timer_label = get_node_or_null("CanvasLayer/TimerLabel")
@onready var ring_visual = get_node_or_null("RingVisual")
@onready var minimap_ring = get_node_or_null("CanvasLayer/Minimap/SubViewport/MinimapRing")
@onready var spawn_point_container = get_node_or_null("SpawnPoints")

# --- PLAYERS (Now supports 2 players) ---
var players = []

# --- PHASE SETTINGS ---
enum Phase { FARM1, SHRINK1, PVP2, SHRINK2, FINAL_PVP, FINAL_SHRINK }
var current_phase = Phase.FARM1
var phase_timer = 60.0 

@onready var map: Node2D = $Map

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
	# 1. Find both players safely
	if map.has_node("Player1"): 
		players.append(map.get_node("Player1"))
		
	if map.has_node("Player2"): 
		players.append(map.get_node("Player2"))
	print(players)
	if players.is_empty():
		print("WARNING: No players found in mapCreation!")

	_setup_minimap_points()
	start_phase(Phase.FARM1)
	spawn_players() # <--- Updated function name

func start_phase(new_phase):
	current_phase = new_phase
	
	match current_phase:
		Phase.FARM1:
			phase_timer = 60.0
			print("PHASE 1: Farming time!")
		Phase.SHRINK1:
			phase_timer = 45.0
			select_fixed_sub_circle(1500.0) 
			print("Ring is closing to Phase 2!")
		Phase.PVP2:
			phase_timer = 60.0
			print("PHASE 2: PvP time!")
		Phase.SHRINK2:
			phase_timer = 45.0
			select_fixed_sub_circle(500.0)
			print("Ring is closing to Final Zone!")
		Phase.FINAL_PVP:
			phase_timer = 30.0
			print("FINAL PHASE: Finish them!")
		Phase.FINAL_SHRINK:
			phase_timer = 30.0
			target_radius = 0.0
			target_center = chosen_corner if chosen_corner != Vector2.ZERO else current_center
			shrink_speed = current_radius / phase_timer
			move_speed = current_center.distance_to(target_center) / phase_timer
			print("SUDDEN DEATH: Total closure!")

func select_fixed_sub_circle(new_radius: float):
	if chosen_corner == Vector2.ZERO:
		chosen_corner = possible_centers.pick_random()
	target_center = chosen_corner
	target_radius = new_radius
	
	var distance_to_travel = current_center.distance_to(target_center)
	move_speed = distance_to_travel / phase_timer
	shrink_speed = (current_radius - target_radius) / phase_timer

func advance_phase():
	var total_phases = Phase.size() 
	var next_idx = int(current_phase) + 1
	if next_idx < total_phases:
		start_phase(next_idx as Phase)
	else:
		print("Match Ended!")

func _process(delta):
	# 1. Handle Phase Timer
	phase_timer -= delta
	
	if floor(phase_timer) != last_print_time:
		last_print_time = floor(phase_timer)
		if timer_label:
			timer_label.text = "Phase: " + Phase.keys()[current_phase] + " | " + str(int(phase_timer)) + "s"

	if phase_timer <= 0:
		advance_phase()
		
	# 2. Movement and Shrink
	if current_phase in [Phase.SHRINK1, Phase.SHRINK2, Phase.FINAL_SHRINK]:
		current_radius = move_toward(current_radius, target_radius, shrink_speed * delta)
		current_center = current_center.move_toward(target_center, move_speed * delta)

	# 3. Update Visuals
	if ring_visual:
		ring_visual.material.set_shader_parameter("center", current_center)
		ring_visual.material.set_shader_parameter("radius", current_radius)
	
	if minimap_ring:
		minimap_ring.global_position = current_center
		minimap_ring.scale = Vector2(current_radius, current_radius)

	# 4. Player Damage Logic (LOOPS THROUGH BOTH PLAYERS)
	for p in players:
		var dist = p.global_position.distance_to(current_center)
		if dist > current_radius:
			if p.has_method("take_ring_damage"):
				p.take_ring_damage(5.0 * delta)

func _setup_minimap_points():
	if not minimap_ring: return
	var points = PackedVector2Array()
	for i in range(65):
		var angle = deg_to_rad(i * (360.0 / 64.0))
		points.push_back(Vector2(cos(angle), sin(angle)))
	minimap_ring.points = points
	
func spawn_players():
	if not spawn_point_container: return

	var available_spawns = spawn_point_container.get_children()
	
	available_spawns.shuffle()
	
	if available_spawns.size() < players.size():
		printerr("WARNING: Not enough spawn points for the number of players!")

	for p in players:
		if available_spawns.is_empty():
			break
			
		var chosen_spawn = available_spawns.pop_back()
		
		p.global_position = chosen_spawn.global_position
		
		if "target_position" in p:
			p.target_position = p.global_position
