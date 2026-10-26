class_name DotFlashlightConfig
extends DotConfig

## Every tunable of a flashlight. Exposed like any config: a game binds it with DotGameConfigBinder (kind `flashlight`) for cvars and the workbench; `cfg/addon/dot_flashlight/*.yml`, `DOT_FLASHLIGHT_*` and `--flashlight-*` layer over these defaults.

const ADDON := "dot-flashlight"
const START_OFF := 0
const START_ON := 1
const START_DARK := 2

## Master switch: off, the node never lights and refuses to toggle.
@export var enabled: bool = true

@export_group("Beam")
## Metres the beam reaches.
@export_range(2.0, 80.0, 0.5) var range_m: float = 20.0
## Cone angle in degrees.
@export_range(5.0, 90.0, 1.0) var angle: float = 36.0
## Light energy of the local player's beam.
@export_range(0.1, 16.0, 0.1) var energy: float = 3.2
## Beam colour as #rrggbb.
@export var colour: String = "#ffedcc"
## Under 1 the light falls away from the middle at once, a hot centre; 1 and over is an even disc.
@export_range(0.1, 4.0, 0.05) var angle_attenuation: float = 0.55
## Falloff along the beam.
@export_range(0.1, 4.0, 0.05) var attenuation: float = 0.6

@export_group("Shadows")
## Whether the local beam casts shadows.
@export var shadows: bool = true
## Shadows on a browser or a phone; off by default, they cost most of the frame there.
@export var shadows_on_web: bool = false
## How many other players' beams, nearest first, cast shadows. The rest are plain cones.
@export_range(0, 16, 1) var shadow_beams: int = 2

@export_group("Others")
## The most other players' beams drawn at once, nearest first.
@export_range(0, 256, 1) var remote_beams: int = 24
## Beams further than this from the viewer are not drawn.
@export_range(5.0, 200.0, 1.0) var remote_range: float = 45.0
## Other players' beams against yours.
@export_range(0.1, 2.0, 0.05) var remote_energy_scale: float = 0.7

@export_group("Battery")
## Whether the light drains a battery.
@export var battery: bool = false
## Seconds a full battery lasts.
@export_range(5.0, 3600.0, 1.0) var battery_seconds: float = 120.0
## Seconds an off light takes to recharge fully.
@export_range(1.0, 3600.0, 1.0) var recharge_seconds: float = 60.0
## The charge (0 to 1) a dead light needs before it can be lit again.
@export_range(0.0, 1.0, 0.01) var restart_charge: float = 0.1
## Below this charge the beam flickers.
@export_range(0.0, 1.0, 0.01) var flicker_below: float = 0.15

@export_group("Start")
## Toggle key (the game binds it; the node makes the action only when missing).
@export var key: String = "F"
## 0 off, 1 on, 2 on only where the map is dark.
@export_range(0, 2, 1) var default_state: int = START_DARK
## Maps the light works on; empty is every map.
@export var allowed_maps: PackedStringArray = PackedStringArray()
## Ambient energy under which a map counts as dark.
@export_range(0.0, 1.0, 0.01) var dark_ambient_floor: float = 0.25
## Moods that count as dark whatever the ambient.
@export var dark_moods: PackedStringArray = PackedStringArray(["interior_horror"])

@export_group("Sound")
## dot-audio catalogue ids for the switch clicks; empty is silent.
@export var click_on: String = "flashlight_on"
@export var click_off: String = "flashlight_off"


func env_prefix() -> String:
	return "DOT_FLASHLIGHT_"


func cli_prefix() -> String:
	return "--flashlight-"


func validate() -> DotResult:
	if not colour.begins_with("#") or not Color.html_is_valid(colour):
		return DotResult.fail(DotError.CODE_INVALID, "flashlight colour '%s' is not #rrggbb" % colour)
	return DotResult.success(self)


func beam_colour() -> Color:
	return Color.html(colour) if Color.html_is_valid(colour) else Color(1.0, 0.93, 0.8)


## Whether a beam may cast shadows on this machine: the cvar and the platform agree.
func local_shadows() -> bool:
	return shadows and (shadows_on_web or not (DotPlatform.is_web() or DotPlatform.is_mobile()))


## Defaults, then `cfg/addon/dot_flashlight/*.yml` and the game tier, then environment and command line.
static func from_files() -> DotResult:
	var cfg := DotFlashlightConfig.new()
	var files := DotAddonConfig.load_dir(ADDON)
	if not files.ok:
		return files
	cfg.apply_dictionary(files.value as Dictionary, "yml")
	return cfg.load_layered()


func describe() -> String:
	return "flashlight %s %.0fm %.0f° energy %.1f shadows %s/%d battery %s start %d" % [
		"on" if enabled else "disabled", range_m, angle, energy, local_shadows(), shadow_beams, battery, default_state]
