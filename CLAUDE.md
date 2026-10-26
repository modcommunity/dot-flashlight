# dot-flashlight

A player-carried, replicated spot light. Read the family [CLAUDE.md](../../CLAUDE.md) first. **The distributable is `addons/dot_flashlight/`**; it requires [dot-core](../dot-core) only (`ln -s ../../dot-core/addons/dot_core addons/dot_core`, gitignored).

| Path | What |
| --- | --- |
| `core/dot_flashlight_config.gd` | `DotFlashlightConfig`: every tunable, `from_files()`, `local_shadows()` (platform rule) |
| `core/dot_flashlight_rules.gd` | pure decisions: allowed map, dark map, start state, battery step, flicker, nearest N |
| `runtime/dot_flashlight.gd` | `DotFlashlight`: state, battery, local beam, click; authoritative or a client that asks |
| `runtime/dot_flashlight_crowd.gd` | `DotFlashlightCrowd`: everyone else's beams, ranked by distance |
| `runtime/dot_flashlight_beam.gd` | the one place a beam is built and styled |
| `examples/flashlight_selftest.tscn` | the suite (7 sections, 67 checks); `flashlight_demo.tscn` and `tools/screenshot.sh` render a frame |

- **No autoloads, no scene paths**: the host is a `DotNodeRef`, the audio manager is a `DotNodeRef` and duck-typed (`play`, `catalogue.has`).
- **The server owns on/off.** A client shows its own switch at once, emits `switch_requested`, and takes the server's `apply_state` silently.
- **Game rules stay in the game**: what a lit beam means to NPCs is the game's; this addon only holds the state.
- **Validate**: `--import`, parse every `.gd`, run the suite.
