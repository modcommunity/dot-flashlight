# dot-flashlight

A player-carried flashlight for TMC's **Dot** collection: a spot light on the player's eye, a toggle, an optional battery, state the server owns, and cheap beams for everyone else. It depends only on dot-core.

Why not dot-lighting: that addon is a world's lighting as a document. A flashlight is carried, switched and replicated, so it is its own small addon.

## Use

```gdscript
var fl := DotFlashlight.new()
fl.config = cfg                                  # a DotFlashlightConfig
fl.host = DotNodeRef.of_path(^"Camera")          # the eye; empty is the parent
fl.authoritative = is_server_or_offline
add_child(fl)
fl.begin_map(map_id, ambient_energy, mood)       # allowed here? starts on a dark map?
fl.switch_requested.connect(send_to_server)      # a client only
fl.apply_state(server_state)                     # from the server; fl.state() is what to replicate

var crowd := DotFlashlightCrowd.new()            # everyone else
crowd.config = cfg
add_child(crowd)
crowd.set_viewer(camera.global_position)
crowd.set_lit(key, player.flashlight)
crowd.place(key, player.eye_position(), player.look_direction())
```

## Configuration

Every number is a `DotFlashlightConfig` field (range, angle, energy, colour, shadows, battery drain and recharge, key, default state, allowed maps, how many other beams are drawn and shadowed). Layers, weakest first: defaults, `cfg/addon/dot_flashlight/*.yml`, the game's, the operator's, `DOT_FLASHLIGHT_*`, `--flashlight-*`. A game that wants cvars and the workbench binds the config with dot-game's `DotGameConfigBinder` (`profile_kind = "flashlight"`), which exposes every field as a cvar and a profile set.

## Cost

Only the local beam and the nearest `shadow_beams` others cast shadows, only the nearest `remote_beams` inside `remote_range` are drawn, and the ranking runs four times a second. Shadows are off by default in a browser or on a phone (`shadows_on_web`).

## Tests

Import, parse every script, then run `examples/flashlight_selftest.tscn` headless. `tools/screenshot.sh <out.png>` renders `examples/flashlight_demo.tscn`.

MIT licensed, see LICENSE.
