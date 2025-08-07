## An AnimatedSprite2D that makes it easy to play animations based on direction.
class_name CharacterSprite2D extends AnimatedSprite2D

var _cardinal_cache: bool = false

var dir: Cardinal.Direction = Cardinal.Direction.SOUTH:
	get:
		return dir
	set(value):
		if value == dir:
			return
		dir = value
		self._actual_dir = dir

var _actual_dir: Cardinal.Direction = Cardinal.Direction.SOUTH:
	get:
		return _actual_dir
	set(value):
		if self.is_cardinal():
			value = Cardinal.nearest_cardinal(dir, value)

		if value == _actual_dir:
			return

		_actual_dir = value

		if self.sprite_frames != null:
			self._update()


# var phys_ancestor: CharacterBody2D = null:
# 	get:
# 		return phys_ancestor
# 	set(value):
# 		phys_ancestor = value
# 		if phys_ancestor != null:
# 			self._update()
#
# func _find_phys_ancestor() -> void:
# 	var p: Node = self.get_parent()
# 	while p != null:
# 		if p is CharacterBody2D:
# 			self.phys_ancestor = p
# 			return
# 		p = p.get_parent()
# 	self.phys_ancestor = null

func _init() -> void:
	self.sprite_frames_changed.connect(self._on_frames_changed)

func _enter_tree() -> void:
	self._on_frames_changed()

func _on_frames_changed() -> void:
	self._cardinal_cache = self.sprite_frames != null && !self._has_diagonals()

func is_cardinal() -> bool:
	return self._cardinal_cache

func _has_diagonals() -> bool:
	return self.sprite_frames.has_animation(&"walk_northeast") && self.sprite_frames.has_animation(&"walk_southeast") && self.sprite_frames.has_animation(&"walk_southwest") && self.sprite_frames.has_animation(&"walk_northwest")

func set_vector(vec: Vector2, cardinal: bool = false) -> void:
	self.dir = Cardinal.dir_of(vec, cardinal)

func get_dir_animation() -> String:
	return Cardinal.animation(self._actual_dir)

func _play_dir(anim: String) -> void:
	if self.sprite_frames == null || !self.sprite_frames.has_animation(anim):
		return
	var fr := self.frame
	var pr := self.frame_progress
	self.play(anim)
	self.set_frame_and_progress(fr, pr)

func play_dir() -> void:
	self._play_dir(self.get_dir_animation())

func _stop_dir(anim: String) -> void:
	self.stop()
	self.animation = anim
	self.frame = 1

func stop_dir() -> void:
	self._stop_dir(self.get_dir_animation())

# func _update_dir() -> void:
# 	if self.phys_ancestor != null:
# 		var vel := self.phys_ancestor.velocity
# 		self.dir = Cardinal.dir_of(vel)
# 	pass

func _update() -> void:
	var anim := self.get_dir_animation()
	if self.is_playing():
		self._play_dir(anim)
	else:
		self.animation = anim
		self.frame = 1

# func _physics_process(delta: float) -> void:
# 	pass

