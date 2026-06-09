class_name FollowerSet extends RefCounted

var _path: LinearPath2D = LinearPath2D.new()
var _followers: Array[Follower] = []
var mode: Follower.FollowerMode = Follower.FollowerMode.LINE:
	get:
		return mode
	set(value):
		mode = value
		for follower: Follower in _followers:
			follower.mode = value

func _init() -> void:
	pass

func size() -> int:
	return self._followers.size()

func register(front: Avatar, follower: Follower) -> Node2D:
	var back: Node2D
	if _followers.size() == 0:
		back = front
	else:
		back = _followers[-1]
	_followers.push_back(follower)
	follower.speed = front.move_speed
	return back


# [--------] ITERATOR [--------]

func iter() -> Iterator:
	return Iterator.IterArray.new(self._followers)

func _iter_init(state: Array) -> bool:
	state[0] = 0
	return state[0] < self.size()

func _iter_next(state: Array) -> bool:
	state[0] += 1
	return state[0] < self.size()

func _iter_get(state: Variant) -> Variant:
	return self._followers[state[0]]
