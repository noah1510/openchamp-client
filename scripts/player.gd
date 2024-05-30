extends Node3D

@export var cur_zoom: int

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D
@export var server_listener: Node

const MoveMarker: PackedScene = preload ("res://effects/move_marker.tscn")

var initial_mouse_position = Vector2.ZERO
var is_middle_mouse_dragging = false
var right_mouse_dragging = false

#@export var player := 1:
	#set(id):
		#player = id
		#$MultiplayerSynchronizer.set_multiplayer_authority(id)

func _ready():
	# For now close game when server dies
	multiplayer.server_disconnected.connect(get_tree().quit)
	spring_arm.spring_length = Config.max_zoom
	Config.camera_property_changed.connect(_on_camera_setting_changed)
	
	center_camera.call_deferred(multiplayer.get_unique_id())
	
	if server_listener == null:
		server_listener = get_parent();
		while !server_listener.is_in_group("Map"):
			server_listener = server_listener.get_parent();
		server_listener = server_listener.get_node("ServerListener");


func _input(event):
	if event is InputEventMouseButton:
		# Right click to move
		if event.button_index == MOUSE_BUTTON_RIGHT:
			# Start dragging
			player_action(event)  # For single clicks
			if not right_mouse_dragging and event.is_pressed():
				right_mouse_dragging = true
		
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				initial_mouse_position = event.position
				is_middle_mouse_dragging = true
			else:
				is_middle_mouse_dragging = false
		
		# Stop dragging if mouse is released
		if right_mouse_dragging and not event.is_pressed():
			right_mouse_dragging = false
	
	if event is InputEventMouseMotion and right_mouse_dragging:
		player_action(event)  # For dragging


func get_target_position(pid: int) -> Vector3:
	var champs = $"../Champions".get_children()
	for child in champs:
		if child.name == str(pid):
			return child.position
	return Vector3.ZERO


func player_action(event):
	var from = camera.project_ray_origin(event.position)
	var to = from + camera.project_ray_normal(event.position) * 1000
	
	var space = get_world_3d().direct_space_state
	var params = PhysicsRayQueryParameters3D.create(from, to)
	var result = space.intersect_ray(params)
	# Move
	if result and result.collider.is_in_group("ground"):
		result.position.y += 1
		var marker = MoveMarker.instantiate()
		marker.position = result.position
		get_node("/root").add_child(marker)
		server_listener.rpc_id(get_multiplayer_authority(), "move_to", result.position)
		#Player.MoveTo(result.position)
	# Attack
	if result and result.collider.is_in_group("Objective"):
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.name)
		return
	if result and result.collider.is_in_group("Minion"):
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.name)
		return
	if result and result.collider.is_in_group("Champion"):
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.name)
		return
	if result and result.collider is CharacterBody3D:
		server_listener.rpc_id(get_multiplayer_authority(), "target", result.collider.pid)
		
func center_camera(playerid):
	position = get_target_position(playerid)

func _process(delta):
	camera_movement_handler(delta)  # Responsible for all camera-related movement
	
	detect_ability_use()  # Listens for ability use, prevents double activation


func detect_ability_use() -> void:
	if Input.is_action_just_pressed("player_ability1"):
		server_listener.rpc_id(get_multiplayer_authority(), "trigger_ability", 1)
	if Input.is_action_just_pressed("player_ability2"):
		server_listener.rpc_id(get_multiplayer_authority(), "trigger_ability", 2)
	if Input.is_action_just_pressed("player_ability3"):
		server_listener.rpc_id(get_multiplayer_authority(), "trigger_ability", 3)
	if Input.is_action_just_pressed("player_ability4"):
		server_listener.rpc_id(get_multiplayer_authority(), "trigger_ability", 4)


func camera_movement_handler(delta) -> void:
	# don't move the cam while changing the settings since that is annoying af
	if Config.in_config_settings:
		return
	
	# If centered, blindly follow the champion
	if (Config.is_cam_centered):
		position = get_target_position(multiplayer.get_unique_id())
	else:
		# Get Mouse Coords on screen
		var mouse_pos = get_viewport().get_mouse_position()
		var size = get_viewport().size
		var cam_delta = Vector3(0, 0, 0)
		var edge_margin = Config.edge_margin
		
		# Edge Panning
		if mouse_pos.x <= edge_margin:
			cam_delta.x -= 1
		elif mouse_pos.x >= size.x - edge_margin:
			cam_delta.x += 1

		if mouse_pos.y <= edge_margin:
			cam_delta.z -= 1
		elif mouse_pos.y >= size.y - edge_margin:
			cam_delta.z += 1
		
		# Keyboard input
		cam_delta.x += Input.get_action_strength("player_right") - Input.get_action_strength("player_left")
		cam_delta.z += Input.get_action_strength("player_down") - Input.get_action_strength("player_up")
		
		# Middle mouse dragging
		if is_middle_mouse_dragging:
			var current_mouse_position = get_viewport().get_mouse_position()
			var mouse_delta = current_mouse_position - initial_mouse_position
			cam_delta += Vector3(mouse_delta.x, 0, mouse_delta.y) # * Config.middle_mouse_sensitivity
		
		# Apply camera movement
		if cam_delta != Vector3.ZERO:
			position += cam_delta.normalized() * delta * Config.cam_speed
	
	# Zoom
	if Input.is_action_just_pressed("player_zoomin"):
		if spring_arm.spring_length > Config.min_zoom:
			spring_arm.spring_length -= 1
	if Input.is_action_just_pressed("player_zoomout"):
		if spring_arm.spring_length < Config.max_zoom:
			spring_arm.spring_length += 1
	
	# Recenter - Tap
	if Input.is_action_pressed("player_camera_recenter"):
		position = get_target_position(multiplayer.get_unique_id())
	# Recenter - Toggle
	if Input.is_action_just_pressed("player_camera_recenter_toggle"):
		Config.set_cam_centered(!Config.is_cam_centered)
	
	# toggle fullscreen
	if Input.is_action_just_pressed("toggle_maximize"):
		var window_mode = get_tree().root.mode
		if window_mode == Window.MODE_FULLSCREEN or window_mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
			get_tree().root.mode = Window.MODE_WINDOWED
		else:
			get_tree().root.mode = Window.MODE_FULLSCREEN


func _on_camera_setting_changed():
	spring_arm.spring_length = clamp(spring_arm.spring_length, Config.min_zoom, Config.max_zoom)
