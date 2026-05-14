class_name LinearPath2D extends RefCounted

var _points: Array[Vector2] = []

func _init() -> void:
	pass

func size() -> int:
	return self._points.size()

func push_point(p: Vector2) -> void:
	self._points.push_back(p)

func pop_point() -> Variant:
	return self._points.pop_front()


# [--------] ITERATOR [--------]

func iter() -> Iterator:
	return Iterator.IterArray.new(self._points)

func _iter_init(state: Array) -> bool:
	state[0] = 0
	return state[0] < self.size()

func _iter_next(state: Array) -> bool:
	state[0] += 1
	return state[0] < self.size()

func _iter_get(state: Variant) -> Variant:
	return self._points[state[0]]
