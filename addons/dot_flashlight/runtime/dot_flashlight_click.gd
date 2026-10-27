class_name DotFlashlightClick
extends RefCounted

## The switch click, shared by the local light and the crowd: one place decides the id, the level and the jitter.

## Plays the on or off click at [param at] through a dot-audio-shaped [param audio] (`play_at`, `catalogue.has`). Returns whether a sound was requested; silent for no audio, an empty id, an id the catalogue lacks, or a zero volume.
static func play(audio: Object, config: DotFlashlightConfig, now_on: bool, at: Vector3) -> bool:
	var id := StringName(config.click_on if now_on else config.click_off)
	if audio == null or id == &"" or config.click_volume <= 0.0 or not audio.has_method("play_at"):
		return false
	var catalogue: Variant = audio.get("catalogue")
	if catalogue != null and (catalogue as Object).has_method("has") and not catalogue.has(id):
		return false
	var pitch := 1.0 + randf_range(-config.click_pitch_jitter, config.click_pitch_jitter)
	audio.call("play_at", id, at, config.click_volume, pitch)
	return true
