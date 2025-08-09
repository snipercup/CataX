## Selected maintenance goal
- 3 – Bug & Logic Error Identification

## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Assets
│└── Fonts
├── Defaults
│├── Blocks
│├── Mobs
│├── Player
│├── Projectiles
│├── Shaders
│└── Sprites
├── FeatureList.md
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelManager.gd
├── Main_menu_buttons.tres
├── README.md
├── Scenes
│├── ContentManager
│├── Overmap
│├── UI
│├── input_manager.tscn
│└── player.tscn
├── Scripts
│├── AttributesWindow.gd
│├── BuildManager.gd
│├── BuildingMenu.gd
│├── Camera.gd
│├── CharacterWindow.gd
│├── Chunk.gd
│├── ChunkLevel.gd
│├── Client.gd
│├── Components
│├── ConstructionGhost.gd
│├── CraftingMenu.gd
│├── CtrlInventoryStackedCustom.gd
│├── CtrlInventoryStackedListItem.gd
│├── CtrlInventoryStackedlistHeaderItem.gd
│├── Documentation.gd
│├── EquipmentSlot.gd
│├── EquippedItem.gd
│├── EscapeMenu.gd
│├── FurnitureBlueprintSpawner.gd
│├── FurnitureBlueprintSrv.gd
│├── FurnitureConstructionWindow.gd
│├── FurniturePhysicsSpawner.gd
│├── FurniturePhysicsSrv.gd
│├── FurnitureStaticSpawner.gd
│├── FurnitureStaticSrv.gd
│├── FurnitureWindow.gd
│├── GameOver.gd
│├── Gamedata
│├── HeldItem.gd
│├── Helper
│├── Helper.gd
│├── InventoryContainerListItem.gd
│├── InventoryWindow.gd
│├── ItemAmmoEditor.gd
│├── ItemCraftEditor.gd
│├── ItemDetector.gd
│├── ItemEditor.gd
│├── ItemFoodEditor.gd
│├── ItemMagazineEditor.gd
│├── ItemMedicalEditor.gd
│├── ItemMeleeEditor.gd
│├── ItemRangedEditor.gd
│├── ItemToolEditor.gd
│├── ItemWearableEditor.gd
│├── LoadingScreen.gd
│├── Mob
│├── NonHUDclick.gd
│├── OvermapGrid.gd
│├── PlayerAttribute.gd
│├── PlayerShooting.gd
│├── QuestTrackerUI.gd
│├── QuestWindow.gd
│├── Runtimedata
│├── WearableSlot.gd
│├── bullet.gd
│├── container.gd
│├── crafting_recipes_manager.gd
│├── gamedata.gd
│├── general.gd
│├── hud.gd
│├── input_manager.gd
│├── item_manager.gd
│├── player.gd
│├── runtimedata.gd
│├── scene_selector.gd
│├── target_manager.gd
│└── weapon.gd
├── Shaders
│├── HideAbovePlayer.gdshader
│└── HideAbovePlayerShadow.gdshader
├── day_night.gd
├── day_night.tscn
├── documentation.tscn
├── entity_manager.gd
├── front_light.gd
├── front_light.tscn
├── hud.tscn
├── icon.svg
├── level_generation.tscn
├── override.cfg
├── project.godot
├── scene_selector.tscn
├── spot_light_3d.tscn
├── spot_light_3d_2.tscn
├── test_environment.gd
└── torso.aseprite
```

## Relevant Files
- `LevelGenerator.gd`
- `LevelManager.gd`
- `Scripts/CharacterWindow.gd`
- `Scripts/AttributesWindow.gd`
- `Scripts/PlayerShooting.gd`
- `entity_manager.gd`
- `front_light.gd`
- `day_night.gd`
- `Scripts/QuestTrackerUI.gd`

### Proposed New Files
- `Tests/Unit/test_level_generator.gd` - Unit tests for LevelGenerator player checks.
- `Tests/Unit/test_character_window.gd` - Unit tests for handling missing player.
- `Tests/Unit/test_player_shooting.gd` - Unit tests for delayed projectile signal connections.
- `Tests/Unit/test_front_light.gd` - Unit tests verifying color sync.
- `Tests/Unit/test_quest_tracker_ui.gd` - Unit tests for instigator-based quest progress.

### Existing Files Modified
- `LevelGenerator.gd` - Wrap player references in null checks, safe chunk initialization, and player watchdog.
- `LevelManager.gd` - Guard chunk updates with player checks and shared initialization function.
- `Scripts/CharacterWindow.gd` - Defer player lookup and provide `set_player_ref` for late initialization.
- `Scripts/AttributesWindow.gd` - Defer player lookup and provide `set_player_ref` for late initialization.
- `Scripts/PlayerShooting.gd` - Delay `projectile_spawned` connection until entity manager ready.
- `entity_manager.gd` - Ensure `projectiles_container` exists before signal connections.
- `front_light.gd` - Cache `day_night` reference and add diagnostics for color synchronization.
- `Scripts/QuestTrackerUI.gd` - Track killer identity in mob kill events.

### Files To Remove
- None.

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

- [ ] 1.0 Harden LevelGenerator player dependency
	- [ ] 1.1 Wrap all `player` references in `LevelGenerator.gd` and `LevelManager.gd` chunk-update logic with null checks.
	- [ ] 1.2 Move initialization logic for chunks into a function that can be safely called when `player` becomes available.
	- [ ] 1.3 Add a watchdog that periodically verifies `player` presence before running chunk-update routines.
- [ ] 2.0 Add player existence checks in UI windows
	- [ ] 2.1 Modify `CharacterWindow.gd` and `AttributesWindow.gd` to defer fetching the player node until `_ready` and verify the node exists.
	- [ ] 2.2 If no player is found, display a placeholder message or disable UI controls instead of accessing player properties.
	- [ ] 2.3 Provide a public method (e.g., `set_player_ref(player)`) that can be called when the player is spawned to reinitialize the window safely.
- [ ] 3.0 Delay projectile spawn connection until entity manager ready
	- [ ] 3.1 In the relevant script (likely `PlayerShooting.gd` or `entity_manager.gd`), move the connection of `projectile_spawned` signals to occur after the `projectiles_container` node has been created and added to the scene.
	- [ ] 3.2 Store pending connections if signals are emitted before the container exists, and connect them once initialization finishes.
	- [ ] 3.3 Write automated checks or logging to confirm that no projectile signals are connected before `projectiles_container` becomes valid.
- [ ] 4.0 Validate front light color synchronization
	- [ ] 4.1 In `front_light.gd` (and any related light scripts), replace `get_node()` lookups with direct references to `day_night` when available, caching the node for reuse.
	- [ ] 4.2 Before each frame update, verify that the `day_night` node reference is still valid; if not, attempt to reacquire it or skip the update.
	- [ ] 4.3 Create a diagnostic function to print current light color and `day_night` state for easier debugging during development.
- [ ] 5.0 Track killer identity in quest helper events
	- [ ] 5.1 Modify the signal or function `_on_mob_killed` (likely in `QuestTrackerUI.gd` or related quest scripts) to include the `instigator` parameter.
	- [ ] 5.2 Update quest progression logic to evaluate the instigator and ensure credit is given only when the player is the killer (or meets specific criteria).
	- [ ] 5.3 Add unit tests or in-game logging to ensure quest progress no longer increments when mobs die from non‑player sources.
