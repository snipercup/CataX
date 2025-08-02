## Selected maintenance goal
- 4 – Decouple Tightly Coupled Scripts & Scenes

## Pre-Feature Development Project Tree
```
.
Assets/
  Fonts/
Defaults/
  Blocks/
  Mobs/
  Player/
  Projectiles/
  Shaders/
  Sprites/
Documentation/
  Game_design/
  Game_development/
  Modding/
Images/
  Icons/
  Main menu/
Media/
Mods/
  Backrooms/
  Core/
  Dimensionfall/
  Test/
Scenes/
  ContentManager/
  Overmap/
  UI/
Scripts/
  Components/
  Gamedata/
  Helper/
  Mob/
  Runtimedata/
Shaders/
Sounds/
  Ambience/
  Music/
  SFX/
Tests/
  Unit/
Textures/
```

## Relevant Files
- `Scripts/hud.gd` – HUD script with direct node references and input handling.
- `Scripts/BuildManager.gd` – Construction system tightly coupled to HUD and LevelGenerator.
- `Scripts/CraftingMenu.gd` – UI script exporting unused HUD references.
- `Scripts/player.gd` – Player logic wiring equipment slots directly to HUD callbacks.
- `Scripts/Helper/SignalBroker/signal_broker.gd` – Central broker for decoupled communication.

### Proposed New Files
- `Scripts/event_bus.gd` – Centralized event bus for scene-to-scene communication.

### Existing Files Modified
- `Scripts/hud.gd`
- `Scripts/BuildManager.gd`
- `Scripts/CraftingMenu.gd`
- `Scripts/player.gd`
- `Scripts/Helper/SignalBroker/signal_broker.gd`

### Files To Remove
- None identified.

### Notes
- Unit tests should be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Refactor HUD interactions to use signals instead of direct node paths.
  - [ ] 1.1 Replace direct node path references in `Scripts/hud.gd` with signal-based communication.
  - [ ] 1.2 Emit player state signals (e.g., health, inventory) from the gameplay scripts to the HUD via the signal broker.
  - [ ] 1.3 Update existing HUD handlers to connect and react to these signals instead of calling nodes directly.
  - [ ] 1.4 Remove unused or redundant node references once signal-based wiring is complete.
- [ ] 2.0 Introduce event-based communication between BuildManager and construction UI.
  - [ ] 2.1 Create a central `event_bus.gd` (or leverage `signal_broker.gd`) to broadcast build-related events (e.g., start/stop construction, block placed).
  - [ ] 2.2 In `BuildManager.gd`, emit events instead of invoking UI elements directly.
  - [ ] 2.3 Update the construction UI script(s) to subscribe to these build events and adjust UI state accordingly.
  - [ ] 2.4 Remove any direct `NodePath` dependencies between `BuildManager.gd` and UI nodes.
- [ ] 3.0 Clean up CraftingMenu by removing HUD NodePath dependency and emitting UI events through the broker.
  - [ ] 3.1 Eliminate the exported HUD reference in `Scripts/CraftingMenu.gd`.
  - [ ] 3.2 Rework crafting UI state changes to emit and consume events through the broker/event bus.
  - [ ] 3.3 Validate that the crafting menu behaves correctly without requiring a HUD node path.
- [ ] 4.0 Decouple player equipment updates from the HUD by routing through a dedicated event bus or broker signals.
  - [ ] 4.1 Emit equipment change signals from `Scripts/player.gd` to the signal broker or event bus.
  - [ ] 4.2 Modify `hud.gd` to listen for equipment signals rather than being directly invoked by player logic.
  - [ ] 4.3 Ensure other systems (e.g., inventory UI) subscribe to the same equipment signals if needed.
- [ ] 5.0 Replace global group lookups in gameplay scripts with service or signal-driven approaches to reduce scene-tree coupling.
  - [ ] 5.1 Audit existing gameplay scripts for `get_tree().get_nodes_in_group` or similar global lookups.
  - [ ] 5.2 Introduce signal-based or service locator patterns for these scripts, registering required nodes with the broker/event bus.
  - [ ] 5.3 Refactor scripts to use these new services/signals and remove group-based coupling.
  - [ ] 5.4 Verify no residual group lookups remain and adjust tests accordingly.

*End of document*
