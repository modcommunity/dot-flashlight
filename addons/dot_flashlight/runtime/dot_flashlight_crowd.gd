class_name DotFlashlightCrowd
extends Node3D

## The beams of everyone else, cheap for a crowd.
##
## One SpotLight3D per lit player, placed by the game each frame from that player's eye and look direction. Only the nearest `shadow_beams` to the viewer cast shadows, only the nearest `remote_beams` are drawn, and the ranking runs a few times a second, not per frame.

@export var config: DotFlashlightConfig
## How often the nearest beams are ranked, in seconds.
@export var rank_interval: float = 0.25
## Optional dot-audio manager: another player's switch is heard in 3D where they stand.
@export var audio: DotNodeRef

var _beams: Dictionary = {}
var _lit: Dictionary = {}
var _origins: Dictionary = {}
var _viewer := Vector3.ZERO
var _left := 0.0
var _audio: Object = null
var _shadow_count := 0
var _drawn_count := 0


func _ready() -> void:
	if config == null:
		config = DotFlashlightConfig.new()
	if audio != null:
		_audio = audio.resolve_or_null(self, "flashlight")


## Who is lit. A player never seen is created on first call. A change in a player already known clicks at their last placed origin; the first sighting is silent, so joining a server does not click for everyone.
func set_lit(key: Variant, lit: bool) -> void:
	if _lit.has(key) and bool(_lit[key]) != lit:
		DotFlashlightClick.play(_audio, config, lit, _origins.get(key, Vector3.ZERO))
	_lit[key] = lit
	if lit and not _beams.has(key):
		var beam := DotFlashlightBeam.make(config, false, config.remote_energy_scale)
		beam.visible = false
		add_child(beam)
		_beams[key] = beam
		_left = 0.0


## Places [param key]'s beam at [param origin] pointing along [param direction].
func place(key: Variant, origin: Vector3, direction: Vector3) -> void:
	_origins[key] = origin
	var beam: SpotLight3D = _beams.get(key, null)
	if beam != null and direction.length_squared() > 0.0001:
		beam.global_transform = Transform3D(Basis.looking_at(direction.normalized(), Vector3.UP), origin)


## Forgets a player who left.
func remove(key: Variant) -> void:
	var beam: SpotLight3D = _beams.get(key, null)
	if beam != null:
		beam.queue_free()
	_beams.erase(key)
	_lit.erase(key)
	_origins.erase(key)


## Forgets every player not in [param keys].
func retain(keys: Array) -> void:
	for key: Variant in _beams.keys():
		if not keys.has(key):
			remove(key)


## Re-applies the config to every beam.
func refresh() -> void:
	for beam: SpotLight3D in _beams.values():
		DotFlashlightBeam.style(beam, config, false, config.remote_energy_scale)


## Where the viewer is (their camera), for the ranking.
func set_viewer(at: Vector3) -> void:
	_viewer = at


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		_left = rank_interval
		rank()


## Ranks the lit beams by distance now: shows the nearest `remote_beams` inside `remote_range`, gives shadows to the nearest `shadow_beams`.
func rank() -> void:
	var keys: Array = []
	var dist := PackedFloat32Array()
	for key: Variant in _beams:
		if bool(_lit.get(key, false)) and _origins.has(key):
			var d := _viewer.distance_to(_origins[key] as Vector3)
			if d <= config.remote_range:
				keys.append(key)
				dist.append(d)
	var shown := DotFlashlightRules.nearest(dist, config.remote_beams)
	var shadowed := DotFlashlightRules.nearest(dist, config.shadow_beams) if config.local_shadows() else PackedInt32Array()
	var visible_keys := {}
	for i in shown:
		var beam: SpotLight3D = _beams[keys[i]]
		visible_keys[keys[i]] = true
		beam.visible = true
		beam.shadow_enabled = shadowed.has(i)
	for key: Variant in _beams:
		if not visible_keys.has(key):
			(_beams[key] as SpotLight3D).visible = false
			(_beams[key] as SpotLight3D).shadow_enabled = false
	_drawn_count = shown.size()
	_shadow_count = shadowed.size()


func describe() -> Dictionary:
	return {"tracked": _beams.size(), "drawn": _drawn_count, "shadowed": _shadow_count}
