class_name Cardinal extends RefCounted

enum Direction {
	EAST,
	SOUTHEAST,
	SOUTH,
	SOUTHWEST,
	WEST,
	NORTHWEST,
	NORTH,
	NORTHEAST
}

static func random() -> Direction:
	return randi_range(0, Direction.NORTHEAST) as Direction

static func is_cardinal(dir: Direction) -> bool:
	return dir == Direction.EAST || dir == Direction.WEST || dir == Direction.NORTH || dir == Direction.SOUTH

static func incompatible(a: Direction, b: Direction) -> bool:
	var diff := absi(a - b)
	return diff <= 1 || diff == Direction.NORTHEAST

static func nearest_cardinal(prev: Direction, dir: Direction) -> Direction:
	if is_cardinal(dir):
		return dir
	if !incompatible(prev, dir) && is_cardinal(prev):
		return prev
	return (dir - 1) as Direction

static func vector(dir: Direction) -> Vector2:
	# lmao is this actually what that's called what a nerd
	const MU: float = 1 / sqrt(2)
	const VECS: Array = [
		Vector2(1, 0), # east
		Vector2(MU, MU), # southeast
		Vector2(0, 1), # south
		Vector2(-MU, MU), # southwest
		Vector2(-1, 0), # west
		Vector2(-MU, -MU), # northwest
		Vector2(0, -1), # north
		Vector2(MU, -MU), # northeast
	]
	return VECS[dir]

static func angle_index(angle: float, cardinal: bool = false) -> int:
	var divisions: int = 8 if cardinal else 16
	var scl: float = (divisions - 1) / TAU
	angle = angle + PI
	return floori((roundi((angle * scl) + 1) % divisions) / 2.0)

static func dir_of(vec: Vector2, cardinal: bool = false) -> Direction:
	return dir_of_angle(vec.angle(), cardinal)

static func dir_of_angle(angle: float, cardinal: bool = false) -> Direction:
	const DIRECTIONS: Array = [
		Direction.WEST,
		Direction.NORTHWEST,
		Direction.NORTH,
		Direction.NORTHEAST,
		Direction.EAST,
		Direction.SOUTHEAST,
		Direction.SOUTH,
		Direction.SOUTHWEST,
	]
	const DIRECTIONS_CARDINAL: Array = [
		Direction.WEST,
		Direction.NORTH,
		Direction.EAST,
		Direction.SOUTH
	]
	var index: int = angle_index(angle, cardinal)
	return DIRECTIONS_CARDINAL[index] if cardinal else DIRECTIONS[index];

static func name(dir: Direction) -> String:
	return (Direction.keys()[dir] as StringName).to_lower()

static func vector_name(vec: Vector2, cardinal: bool = false) -> String:
	return name(dir_of(vec, cardinal))

static func animation(dir: Direction) -> String:
	return "walk_" + name(dir)

static func vector_animation(vec: Vector2, cardinal: bool = false) -> String:
	return animation(dir_of(vec, cardinal))
