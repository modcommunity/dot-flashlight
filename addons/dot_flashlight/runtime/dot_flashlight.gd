class_name DotFlashlight
extends Node

## One player's flashlight: the on/off state, the battery and the local beam.
##
## Authoritative (offline, listen host, server) it owns the state. A connected client is not: [method toggle] shows the change at once and emits [signal switch_requested] for the game to send; the server's answer arrives through [method apply_state]. Replicate [method state] (a Dictionary of `on` and `charge`) however the game replicates.

## The light changed state.
signal toggled(on: bool)
## A non-authoritative node wants the state [param want]; send it to the server.
signal switch_requested(want: bool)
## The battery ran out and the light went off.
signal depleted
## A switch click, for a game that plays its own sound.
signal clicked(on: bool)

const CHANNEL := "flashlight"

@export var config: DotFlashlightConfig
## The eye or camera the beam is mounted on; empty is this node's parent.
@export var host: DotNodeRef
## Optional dot-audio manager for the switch clicks.
@export var audio: DotNodeRef
## Input action that toggles; created from `config.key` only if the project has no such action.
@export var action: StringName = &"flashlight"
## Whether this node reads its action itself; a game with its own key table turns it off and calls [method toggle].
@export var handle_input: bool = true
## Whether this process owns the state.
@export var authoritative: bool = true
## Where the beam sits on the host.
@export var beam_offset: Vector3 = Vector3(0.2, -0.15, 0.0)

var on: bool = false
var charge: float = 1.0
var allowed: bool = true
var beam: SpotLight3D = null

var _audio: Object = null
var _time := 0.0


func _ready() -> void:
	if config == null:
		config = DotFlashlightConfig.new()
	if handle_input:
		_ensure_action()
	var mount := (host.resolve_or_null(self, CHANNEL) if host != null else get_parent()) as Node3D
	if mount != null:
		beam = DotFlashlightBeam.make(config, config.local_shadows())
		mount.add_child(beam)
		beam.position = beam_offset
		beam.visible = on
	if audio != null:
		_audio = audio.resolve_or_null(self, CHANNEL)


## Starts a map: whether the light works there and whether it begins on.
func begin_map(map_id: String, ambient: float, mood: String = "") -> void:
	allowed = DotFlashlightRules.allowed_on(config, map_id)
	charge = 1.0
	_apply(DotFlashlightRules.start_on(config, map_id, ambient, mood), false)
	DotLog.debug(CHANNEL, "map", {"map": map_id, "allowed": allowed, "on": on})


## Flips the light. Returns whether anything was done.
func toggle() -> bool:
	return request(not on)


## Asks for [param want]. Refused when not allowed, or a dead battery. Non-authoritative: shown at once and emitted for the server.
func request(want: bool) -> bool:
	if not allowed or not config.enabled or want == on:
		return false
	if want and not DotFlashlightRules.can_light(config, charge):
		return false
	if not authoritative:
		switch_requested.emit(want)
	_apply(want, true)
	return true


## The server's state, applied without a click: the player already heard their own.
func apply_state(state: Dictionary) -> void:
	charge = float(state.get("charge", charge))
	_apply(bool(state.get("on", on)), false)


## What to replicate.
func state() -> Dictionary:
	return {"on": on, "charge": snappedf(charge, 0.01)}


func describe() -> Dictionary:
	return {"on": on, "charge": snappedf(charge, 0.01), "allowed": allowed, "authoritative": authoritative, "beam": beam != null}


func _process(delta: float) -> void:
	_time += delta
	if authoritative and config.battery:
		charge = DotFlashlightRules.step_charge(config, charge, on, delta)
		if on and charge <= 0.0:
			_apply(false, true)
			depleted.emit()
	if beam != null and on:
		beam.light_energy = config.energy * DotFlashlightRules.flicker(config, charge, _time)


func _unhandled_input(event: InputEvent) -> void:
	if handle_input and InputMap.has_action(action) and event.is_action_pressed(action):
		toggle()


func _apply(next: bool, click: bool) -> void:
	if next == on:
		return
	on = next
	if beam != null:
		beam.visible = on
	if click:
		_click(on)
	toggled.emit(on)


func _click(now_on: bool) -> void:
	clicked.emit(now_on)
	var id := StringName(config.click_on if now_on else config.click_off)
	if _audio == null or id == &"" or not _audio.has_method("play"):
		return
	var catalogue: Variant = _audio.get("catalogue")
	if catalogue != null and (catalogue as Object).has_method("has") and not catalogue.has(id):
		return
	_audio.call("play", id)


func _ensure_action() -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	var ev := InputEventKey.new()
	ev.keycode = OS.find_keycode_from_string(config.key)
	InputMap.action_add_event(action, ev)
