class_name DotFlashlightRules
extends RefCounted

## Pure decisions, so a server and a client agree and a suite can ask them without a scene.


## Whether the light works on [param map_id] at all.
static func allowed_on(cfg: DotFlashlightConfig, map_id: String) -> bool:
	if not cfg.enabled:
		return false
	return cfg.allowed_maps.is_empty() or cfg.allowed_maps.has(map_id)


## Whether a map reads as dark: a dark mood, or an ambient energy under the floor.
static func is_dark(cfg: DotFlashlightConfig, ambient: float, mood: String = "") -> bool:
	return (mood != "" and cfg.dark_moods.has(mood)) or ambient < cfg.dark_ambient_floor


## The state a light starts a map in: on only if allowed, and by `default_state` (dark maps only, for the default).
static func start_on(cfg: DotFlashlightConfig, map_id: String, ambient: float, mood: String = "") -> bool:
	if not allowed_on(cfg, map_id):
		return false
	match cfg.default_state:
		DotFlashlightConfig.START_ON:
			return true
		DotFlashlightConfig.START_DARK:
			return is_dark(cfg, ambient, mood)
	return false


## One step of the battery: the new charge, draining while [param on], recharging while off.
static func step_charge(cfg: DotFlashlightConfig, charge: float, on: bool, delta: float) -> float:
	if not cfg.battery:
		return 1.0
	var rate := (-1.0 / cfg.battery_seconds) if on else (1.0 / cfg.recharge_seconds)
	return clampf(charge + rate * delta, 0.0, 1.0)


## Whether a light at [param charge] may be switched on.
static func can_light(cfg: DotFlashlightConfig, charge: float) -> bool:
	return cfg.enabled and (not cfg.battery or charge >= maxf(cfg.restart_charge, 0.0001))


## The beam's energy scale at [param charge] and [param time]: steady, then a flicker as it dies.
static func flicker(cfg: DotFlashlightConfig, charge: float, time: float) -> float:
	if not cfg.battery or charge >= cfg.flicker_below:
		return 1.0
	var weak := charge / maxf(cfg.flicker_below, 0.0001)
	return lerpf(0.25, 1.0, weak) * (0.65 + 0.35 * absf(sin(time * 31.0)))


## The indices of [param distances] that cast shadows: the [param count] smallest.
static func nearest(distances: PackedFloat32Array, count: int) -> PackedInt32Array:
	var order: Array = range(distances.size())
	order.sort_custom(func(a: int, b: int) -> bool: return distances[a] < distances[b])
	var out := PackedInt32Array()
	for i in mini(count, order.size()):
		out.append(order[i])
	return out
