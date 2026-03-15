extends "res://Assets/Characters/Enemies/Enemy.gd"

const STATE_IDLE := 0
const STATE_CHASE := 1
const STATE_ATTACK := 2

@export var sight_radius: float = 22.0
@export var attack_range: float = 3.0
@export var attack_interval: float = 1.0
@export var attack_damage: float = 10.0
@export var lose_sight_time: float = 2.0
@export var chase_speed: float = 5.0

var current_state: int = STATE_IDLE
var player: Node3D
var _attack_timer: float = 0.0
var _lost_sight_timer: float = 0.0

func _ready() -> void:
	MOVE_SPEED = chase_speed
	super()
	player = _find_player()

func _physics_process(delta: float) -> void:
	if not player:
		player = _find_player()
		if not player:
			return

	match current_state:
		STATE_IDLE:
			_process_idle(delta)
		STATE_CHASE:
			_process_chase(delta)
		STATE_ATTACK:
			_process_attack(delta)

	# Navigation movement
	if nav_agent.is_navigation_finished():
		velocity.x = 0.0
		velocity.z = 0.0
	else:
		var next_pos: Vector3 = nav_agent.get_next_path_position()
		var dir := (next_pos - global_position).normalized() * MOVE_SPEED
		velocity.x = dir.x
		velocity.z = dir.z

	velocity.y -= 40.0 * delta
	move_and_slide()

func _process_idle(_delta: float) -> void:
	if _can_see_player():
		current_state = STATE_CHASE
		target = player
		_lost_sight_timer = 0.0

func _process_chase(delta: float) -> void:
	if not _can_see_player():
		_lost_sight_timer += delta
		if _lost_sight_timer > lose_sight_time:
			current_state = STATE_IDLE
			target = null
			return
	else:
		_lost_sight_timer = 0.0

	# Attack when close enough
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= attack_range:
		current_state = STATE_ATTACK
		target = null
		_attack_timer = attack_interval
		return

	# Keep chasing
	target = player

func _process_attack(delta: float) -> void:
	if not _can_see_player():
		_lost_sight_timer += delta
		if _lost_sight_timer > lose_sight_time:
			current_state = STATE_IDLE
			target = null
			return
	else:
		_lost_sight_timer = 0.0

	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player > attack_range:
		current_state = STATE_CHASE
		target = player
		return

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		if player and player.has_method("take_damage"):
			player.take_damage(attack_damage)
		else:
			print("Bandit: player has no take_damage() method")

func _can_see_player() -> bool:
	if not player:
		return false

	var dist = global_position.distance_to(player.global_position)
	if dist > sight_radius:
		return false

	var space := get_world_3d().direct_space_state
	var from_pos := global_position + Vector3.UP * 0.5
	var to_pos := player.global_position + Vector3.UP * 0.5
	var ray_params := PhysicsRayQueryParameters3D.new()
	ray_params.from = from_pos
	ray_params.to = to_pos
	ray_params.exclude = [self]
	var result := space.intersect_ray(ray_params)
	if result.is_empty():
		return true

	var collider = result.get("collider")
	if collider == player:
		return true
	if collider and collider.is_in_group("player"):
		return true
	
	return false

func _find_player() -> Node3D:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0] as Node3D
	return null
