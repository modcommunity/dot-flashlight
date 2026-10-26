class_name DotFlashlightBeam
extends RefCounted

## Builds and styles the SpotLight3D every flashlight draws: one place, so a local and a remote beam match.


## A new beam. [param scale] multiplies the energy (others' beams are dimmer).
static func make(cfg: DotFlashlightConfig, shadows: bool, scale: float = 1.0) -> SpotLight3D:
	var light := SpotLight3D.new()
	light.name = "Beam"
	light.light_volumetric_fog_energy = 0.0
	style(light, cfg, shadows, scale)
	return light


## Re-applies [param cfg] to [param light], e.g. after a cvar changed.
static func style(light: SpotLight3D, cfg: DotFlashlightConfig, shadows: bool, scale: float = 1.0) -> void:
	light.spot_range = cfg.range_m
	light.spot_angle = cfg.angle
	light.spot_angle_attenuation = cfg.angle_attenuation
	light.spot_attenuation = cfg.attenuation
	light.light_energy = cfg.energy * scale
	light.light_color = cfg.beam_colour()
	light.shadow_enabled = shadows
