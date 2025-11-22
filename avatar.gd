class_name Avatar extends CharacterBody2D

## Movement speed, in units(?) per second.
@export var move_speed: float = 128.0
## The initial direction in which to face.
@export var facing_dir: Cardinal.Direction = Cardinal.Direction.SOUTH:
	get:
		return facing_dir
	set(value):
		facing_dir = value
		self._facing_vec = Cardinal.vector(facing_dir)
		if self.sprite != null:
			self.sprite.dir = facing_dir
## The max distance from which the avatar can interact with things.
@export var interact_distance: float = 24.0

var _facing_vec: Vector2

var facing_vec: Vector2:
	get:
		return _facing_vec

var sprite: CharacterSprite2D:
	get:
		return sprite
	set(value):
		sprite = value
		if sprite != null:
			sprite.dir = self.facing_dir

## whether we should try to interact on the next physics processing step
var queued_interact: bool = false

## Registered followers
var followers: Array = []
var follower_mode: Follower.FollowerMode = Follower.FollowerMode.LINE:
	get:
		return follower_mode
	set(value):
		follower_mode = value
		#print("changing follower mode to " + Follower.FollowerMode.keys()[mode])
		for follower: Follower in followers:
			follower.mode = value


## Emitted before the avatar tries to interact with something
signal interacting_with(interactee: Node)

## Emitted after the avatar tries to interact with something
signal interacted_with(interactee: Node)

func _enter_tree() -> void:
	if !self.is_in_group(&"avatar"):
		self.add_to_group(&"avatar")

func _ready() -> void:
	self.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING

	for child: Node in self.get_children():
		if child is CharacterSprite2D:
			self.sprite = child as CharacterSprite2D
			break
	if self.sprite == null:
		push_error("Avatar {0} could not find CharacterSprite2D".format([self.name]))

# movement :)
func _physics_process(_delta: float) -> void:
	# handle interaction...
	# doing this in _physics_process because the physics state can only safely be accessed during
	# this function
	if self.queued_interact:
		self._interact()

	# TODO :: customizable input names?
	var input_vec := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")

	if !is_zero_approx(input_vec.length()):
		# update facing
		self.facing_dir = Cardinal.dir_of(input_vec)
		# update velocity
		self.velocity = self.facing_vec * move_speed
		# play walk animation if not already
		if !self.sprite.is_playing():
			self.sprite.play_dir()
	else:
		# stop moving
		self.velocity = Vector2.ZERO
		# stop animation and leave it on the standing frame
		if self.sprite.is_playing():
			self.sprite.stop_dir()

	# move avatar
	if self.move_and_slide():
		# handle collisions
		for i: int in range(self.get_slide_collision_count()):
			var collision := self.get_slide_collision(i)
			var collider := collision.get_collider()
			if collider is Node:
				var n := collider as Node
				if n.has_method(&"on_avatar_collision"):
					n.call(&"on_avatar_collision", self, collision)

func _interact() -> void:
	self.queued_interact = false
	var space_state: PhysicsDirectSpaceState2D = get_world_2d().direct_space_state
	var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		self.global_position,
		self.global_position + (self.facing_vec * self.interact_distance),
		# collision mask; 0xFFFFFFFF collides with all layers
		0xFFFFFFFF,
		[self]
	)
	# don't just collide with shapes...
	query.collide_with_areas = true

	var result: Dictionary = space_state.intersect_ray(query)
	if result:
		# i'm pretty sure this is always true but whatever might as well check
		if result.collider is Node:
			var col: Node = result.collider as Node
			# tell everyone we're interacting with the thing...
			self.interacting_with.emit(col)
			# can we interact with it? (checked after emitting above because that might change in response to that)
			if !col.has_method(&"can_interact") || col.call(&"can_interact", self, result):
				# does it have a special thing that happens when you interact with it?
				if col.has_method(&"on_interact"):
					col.call(&"on_interact", self, result)
				# tell everyone we interacted with the thing
				self.interacted_with.emit(col)

# [--------] INPUT [--------]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_menu"):
		# open the pause menu
		# FIX :: assumes existence of SceneManager and menu
		SceneManager.push_overlay(preload("res://gui/menu.tscn").instantiate())
		self.get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		# we gotta wait til _physics_process to actually do the interaction
		self.queued_interact = true
		self.get_viewport().set_input_as_handled()

# [--------] FOLLOWERS [--------]

func register_follower(follower: Follower) -> Node2D:
	var back: Node2D
	if followers.size() == 0:
		back = self
	else:
		back = followers[-1]
	followers.push_back(follower)
	follower.speed = move_speed
	follower.mode = follower_mode
	return back

# [--------] WARP [--------]

## Used by Warp2D to determine whether this can be warped
func can_warp(warp: Warp2D) -> bool:
	# only warp if we're moving towards the warp node
	var to_wrp := warp.global_position - self.global_position
	return to_wrp.normalized().dot(self.velocity.normalized()) >= 0.5

func on_warped(warp: Warp2D, trg: Node2D) -> void:
	self.facing_dir = Cardinal.dir_of_angle(trg.global_rotation)
	for follower: Follower in self.followers:
		follower._target_warped(warp, trg)

