class_name Follower extends CharacterBody2D

enum FollowerMode { LINE, CROWD, WANDER }

## Distance at which the follower will stop walking.
@export var min_separation: float = 24.0
## Distance beyond which the follower will start walking to reach their target.
@export var max_separation: float = 32.0
## Distance beyond which the follower will teleport.
@export var teleport_distance: float = 128.0
## The speed at which the follower will move. (If the target is a player, this
## will be overriden to the player's move speed.)
@export var speed: float = 128.0
## Whether this follower will walk in a line behind others or just crowd around the player.
@export var mode: FollowerMode = FollowerMode.LINE

## The actual follow target.
var target: Node2D:
	set(val):
		target = val
		if target.has_method("register_follower"):
			followed = target.call(&"register_follower", self)
		else:
			followed = target
## When in LINE mode, the effective target.
var followed: Node2D

var facing_dir: Cardinal.Direction = Cardinal.Direction.SOUTH:
	get:
		return facing_dir
	set(value):
		facing_dir = value
		if self.sprite != null:
			self.sprite.dir = facing_dir

var sprite: CharacterSprite2D:
	get:
		return sprite
	set(value):
		sprite = value
		if sprite != null:
			sprite.dir = self.facing_dir

enum FollowerState { CATCHING_UP, WAITING }
var state: FollowerState = FollowerState.WAITING

func _ready() -> void:
	if target == null:
		target = get_tree().get_first_node_in_group("avatar")
	if followed == null:
		followed = target

	for child: Node in self.get_children():
		if child is CharacterSprite2D:
			self.sprite = child as CharacterSprite2D
			break

	if sprite == null:
		printerr("couldn't find follower sprite...")
	else:
		sprite.animation = "walk_south"
		sprite.frame = 1

func _physics_process(_delta: float) -> void:
	var effective_target: Node2D = self.target
	match mode:
		FollowerMode.LINE:
			effective_target = followed
	if effective_target == null || !is_instance_valid(effective_target):
		return

	var to_eff: Vector2 = effective_target.global_position - global_position
	var distance: float = to_eff.length()

	# teleport if necessary
	#if distance > teleport_distance:
		#global_position = effective_target.global_position + (-to_eff.normalized() * max_separation)
		#to_eff = effective_target.global_position - global_position
		#distance = max_separation

	# update follower state
	if distance >= max_separation:
		state = FollowerState.CATCHING_UP
	elif distance <= min_separation:
		var target_vel: Vector2 = effective_target.get("velocity")
		if target_vel == null || is_zero_approx(target_vel.length()):
			state = FollowerState.WAITING

	# update velocity
	match state:
		FollowerState.CATCHING_UP:
			var move_speed: float = lerpf(0, speed, clampf(distance / min_separation, 0, 1))
			if distance >= max_separation:
				move_speed = lerpf(speed * 2, speed, clampf(max_separation / distance, 0, 1))
			var move_dir: Vector2 = to_eff.normalized() # Avatar.direction_vector(Avatar.direction_of(to_followed))
			velocity = move_dir * move_speed
		FollowerState.WAITING:
			velocity = Vector2.ZERO

	# move follower
	self.move_and_slide()

	var r_vel := self.get_real_velocity()

	if is_zero_approx(r_vel.length()):
		var facing_trg := self.target
		if facing_trg == null || !is_instance_valid(facing_trg):
			facing_trg = effective_target

		var to_target: Vector2 = facing_trg.global_position - global_position
		self.facing_dir = Cardinal.dir_of(to_target)
		if self.sprite.is_playing():
			self.sprite.stop_dir()
	else:
		self.facing_dir = Cardinal.dir_of(r_vel)
		if !self.sprite.is_playing():
			self.sprite.play_dir()
