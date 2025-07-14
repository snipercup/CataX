# Signal conventions

This document explains how gameplay scripts communicate via `SignalBroker`.

## Overview
`SignalBroker` (located at `Scripts/Helper/SignalBroker/signal_broker.gd`) exposes a collection of typed signals used across the project.  Scripts obtain the broker through `Helper.signal_broker` and connect to the required signals.  Connections should be made in `_ready` and cleaned up in `_exit_tree`.

- Declare connections in the `_ready` function using typed connections.
- Disconnect signals in `_exit_tree` to avoid dangling connections.
- Some signals are generated dynamically with `SignalFactory`.  These helper methods return a `Signal` instance scoped by a unique key, for example `item_was_equipped_to_slot(slot_index)`.

Example:
```gdscript
func _ready() -> void:
    Helper.signal_broker.game_started.connect(_on_game_started)

func _exit_tree() -> void:
    Helper.signal_broker.game_started.disconnect(_on_game_started)
```

## Common signals
| Signal | Purpose |
| --- | --- |
| `hud_start_progressbar(time_left: float)` | Tell the HUD to display a progress bar for `time_left` seconds. |
| `inventory_window_visibility_changed(window: Control)` | Emitted when the inventory window is shown or hidden. |
| `build_window_visibility_changed(window: Control)` | Emitted when the build menu is shown or hidden. |
| `items_were_used(items: Array[InventoryItem])` | Sent after one or more items are consumed. |
| `wearable_was_equipped(item: InventoryItem, slot: Control)` | A wearable item was equipped into a slot. |
| `container_entered_proximity(container: Node3D)` | The player approached a container. |
| `player_stat_changed(player: Player)` | A player stat changed, e.g. health or stamina. |
| `game_started()` / `game_loaded()` | Emitted when a new game begins or a save is loaded. |

When a signal needs to be scoped to a specific slot or entity, use the factory helpers.  For example:
```gdscript
var sig := Helper.signal_broker.item_was_equipped_to_slot(0)
sig.connect(on_slot_equipped)
```

By adhering to these conventions gameplay scripts can remain decoupled while still responding to game events.
