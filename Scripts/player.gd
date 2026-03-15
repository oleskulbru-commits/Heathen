extends CharacterBody3D

# --- Nodes ---
@onready var anim_tree: AnimationTree = $WitchSkin/AnimationTree
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

# --- Movement Settings ---
@export var rotation_speed: float = 12.0 
@export var mouse_sensitivity: float = 0.002
@export var camera_height_offset: float = 1.5

# --- Camera Auto-Center Settings ---
@export var cam_auto_center_time: float = 2.0 
@export var cam_auto_center_speed: float = 2.5
var cam_idle_timer: float = 0.0

# --- Sprint Zoom Settings ---
@export var normal_fov: float = 54.0
@export var sprint_fov: float = 75.0
@export var zoom_speed: float = 4.0

# --- Logic Variables ---
var current_state: PlayerState
var states = {}
var is_walking_toggled: bool = false 

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	states = {
		"idle": IdleState.new(self),
		"move": MoveState.new(self)
	}
	change_state("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("walk_toggle"):
		is_walking_toggled = !is_walking_toggled
	
	if event is InputEventMouseMotion:
		cam_idle_timer = 0.0
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		var y_rot = event.relative.y * mouse_sensitivity
		spring_arm.rotate_x(y_rot)
		spring_arm.rotation.x = clamp(spring_arm.rotation.x, deg_to_rad(-40), deg_to_rad(60))

func _physics_process(delta: float) -> void:
	current_state.physics_update(delta)
	camera_pivot.global_position = global_position + Vector3(0, camera_height_offset, 0)
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	if input_dir.length() > 0.1:
		# Directional Logic (Inversions Fixed)
		var camera_rot_y = camera_pivot.global_transform.basis.get_euler().y
		var move_dir = Vector3(-input_dir.x, 0, -input_dir.y).rotated(Vector3.UP, camera_rot_y).normalized()
		
		var target_angle = atan2(move_dir.x, move_dir.z)
		rotation.y = lerp_angle(rotation.y, target_angle, rotation_speed * delta)
		
		# Root Motion Physics
		var root_motion_pos = anim_tree.get_root_motion_position()
		# We multiply the root motion by 0.45 only if walking to manually slow it down
		var multiplier = 0.75 if is_walking_toggled else 1.0
		var velocity_from_anim = (transform.basis * root_motion_pos * multiplier) / delta
		velocity.x = velocity_from_anim.x
		velocity.z = velocity_from_anim.z
		
		# Auto-Center Logic
		cam_idle_timer += delta
		if cam_idle_timer >= cam_auto_center_time:
			camera_pivot.rotation.y = lerp_angle(camera_pivot.rotation.y, rotation.y, cam_auto_center_speed * delta)
	else:
		velocity.x = 0
		velocity.z = 0
		cam_idle_timer = 0.0 

	# FOV Control
	var target_fov = normal_fov
	if Input.is_action_pressed("sprint") and input_dir.length() > 0.1 and !is_walking_toggled:
		target_fov = sprint_fov
	camera.fov = lerp(camera.fov, target_fov, zoom_speed * delta)

	# Gravity
	if not is_on_floor():
		velocity.y -= 25.0 * delta 
	else:
		velocity.y = 0
		
	move_and_slide()

func change_state(state_name: String) -> void:
	if current_state: current_state.exit()
	current_state = states[state_name]
	current_state.enter()

# --- INNER STATES (Bottom of Script) ---

class IdleState extends PlayerState:
	func _init(p): player = p
	func enter():
		player.anim_tree.set("parameters/conditions/is_moving", false)
		player.anim_tree.set("parameters/conditions/is_idle", true)
	func physics_update(_delta):
		if Input.get_vector("move_left", "move_right", "move_forward", "move_backward").length() > 0.1:
			player.change_state("move")

class MoveState extends PlayerState:
	func _init(p): player = p
	func enter():
		player.anim_tree.set("parameters/conditions/is_moving", true)
		player.anim_tree.set("parameters/conditions/is_idle", false)
	func physics_update(_delta):
		var input = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		# ADJUSTED VALUES FOR SPEED DISCREPANCY
		var speed_val = 0.7 # Jog
		if player.is_walking_toggled:
			speed_val = 0.25 # Lowered to ensure walk isn't as fast as jog
		elif Input.is_action_pressed("sprint"):
			speed_val = 1.0 # Full Sprint
			
		player.anim_tree.set("parameters/Move/blend_position", speed_val)
		
		if input.length() < 0.1:
			player.change_state("idle")
