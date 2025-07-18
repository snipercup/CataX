## Selected maintenance goal
- **Test Coverage & QA Enhancement**

## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Assets
│   └── Fonts
├── Defaults
│   ├── Blocks
│   ├── Mobs
│   ├── Player
│   ├── Projectiles
│   ├── Shaders
│   └── Sprites
├── Documentation
│   ├── Game_design
│   ├── Game_development
│   └── Modding
├── FeatureList.md
├── Images
│   ├── Icons
│   └── Main menu
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelGenerator.gd.uid
├── LevelManager.gd
├── LevelManager.gd.uid
├── Main_menu_buttons.tres
├── Media
│   ├── Catax_basic.png
│   ├── Catax_basic.png.import
│   ├── Catax_basic_zoomed_out.png
│   ├── Catax_basic_zoomed_out.png.import
│   ├── Catax_content_editor.png
│   ├── Catax_content_editor.png.import
│   ├── Catax_crafting_editor.png
│   ├── Catax_crafting_editor.png.import
│   ├── Catax_furniture_editor.png
│   ├── Catax_furniture_editor.png.import
│   ├── Catax_item_editor.png
│   ├── Catax_item_editor.png.import
│   ├── Catax_itemgroup_editor.png
│   ├── Catax_itemgroup_editor.png.import
│   ├── Catax_map_editor.png
│   ├── Catax_map_editor.png.import
│   ├── Catax_map_editor_area_editor.png
│   ├── Catax_map_editor_area_editor.png.import
│   ├── Catax_map_editor_areas.png
│   ├── Catax_map_editor_areas.png.import
│   ├── Catax_map_editor_preview.png
│   ├── Catax_map_editor_preview.png.import
│   ├── Catax_mob_editor.png
│   ├── Catax_mob_editor.png.import
│   ├── Catax_overmap_large.png
│   ├── Catax_overmap_large.png.import
│   ├── Catax_playerattribute_editor.png
│   ├── Catax_playerattribute_editor.png.import
│   ├── Catax_quest_editor.png
│   ├── Catax_quest_editor.png.import
│   ├── Catax_skills_editor.png
│   ├── Catax_skills_editor.png.import
│   ├── Catax_stats_editor.png
│   ├── Catax_stats_editor.png.import
│   ├── Catax_tacticalmap_editor.png
│   ├── Catax_tacticalmap_editor.png.import
│   ├── Catax_tile_editor.png
│   ├── Catax_tile_editor.png.import
│   ├── Catax_wearableslots_editor.png
│   ├── Catax_wearableslots_editor.png.import
│   ├── Dimensionfall_add_remove_mod_menu.png
│   ├── Dimensionfall_add_remove_mod_menu.png.import
│   ├── Dimensionfall_crafting_station.png
│   ├── Dimensionfall_crafting_station.png.import
│   ├── Dimensionfall_inventory.png
│   ├── Dimensionfall_inventory.png.import
│   ├── Dimensionfall_main_menu.png
│   ├── Dimensionfall_main_menu.png.import
│   ├── Dimensionfall_mobfaction_editor.png
│   ├── Dimensionfall_mobfaction_editor.png.import
│   ├── Dimensionfall_mobgroup_editor.png
│   ├── Dimensionfall_mobgroup_editor.png.import
│   ├── Dimensionfall_overmap.png
│   ├── Dimensionfall_overmap.png.import
│   ├── Dimensionfall_overmaparea_editor.png
│   ├── Dimensionfall_overmaparea_editor.png.import
│   ├── Dimensionfall_overmaparea_generator.png
│   ├── Dimensionfall_overmaparea_generator.png.import
│   ├── Dimensionfall_quest_journal.png
│   └── Dimensionfall_quest_journal.png.import
├── Mods
│   ├── Backrooms
│   ├── Core
│   ├── Dimensionfall
│   └── Test
├── README.md
├── Scenes
│   ├── ContentManager
│   ├── GameOver.tscn
│   ├── InventoryContainerListItem.tscn
│   ├── InventoryWindow.tscn
│   ├── LoadingScreen.tscn
│   ├── Overmap
```

## Relevant Files
- `Scripts/BuildManager.gd`
- `Scripts/ConstructionGhost.gd`
- `Scripts/PlayerShooting.gd`
- `Scripts/Helper/json_helper.gd`
- `Mods/Core/Items/Items.json`
- `Mods/Dimensionfall/Npcs`
- `Tests/Unit`

### Proposed New Files
- `Tests/Unit/test_build_manager.gd` - Unit tests for `BuildManager` logic.
- `Tests/Unit/test_player_shooting.gd` - Unit tests for `PlayerShooting` features.
- `Tests/Unit/test_mod_validation.gd` - Validate mod JSON definitions.
- `Tests/Unit/test_construction_ghost.gd` - Tests interactions with `ConstructionGhost`.

### Existing Files Modified
- `Scripts/BuildManager.gd` - Add signals for easier testing hooks.
- `Scripts/ConstructionGhost.gd` - Minor refactoring for testability.
- `Scripts/PlayerShooting.gd` - Expose bullet spawning for tests.

### Files To Remove
- *(none)*

### Notes
- Unit tests should be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Audit current unit tests and document coverage gaps across `Scripts` and `Scenes`.
  - [ ] 1.1 List all existing test files under `Tests/Unit`.
  - [ ] 1.2 Map test files to the scripts and scenes they exercise.
  - [ ] 1.3 Identify scripts or scenes lacking any tests.
  - [ ] 1.4 Document coverage gaps in a report within `/Documentation`.
- [ ] 2.0 Implement GUT tests for building mechanics using `BuildManager` and `ConstructionGhost`.
  - [ ] 2.1 Create a fixture for `BuildManager` and `ConstructionGhost`.
  - [ ] 2.2 Verify `BuildManager` correctly places valid structures.
  - [ ] 2.3 Test `ConstructionGhost` preview creation and cleanup logic.
  - [ ] 2.4 Run `gdformat` on modified scripts.
  - [ ] 2.5 Run GUT tests for building mechanics.
- [ ] 3.0 Expand `Player` tests to cover `PlayerShooting` behavior and ammo consumption.
  - [ ] 3.1 Build a player test fixture including `PlayerShooting`.
  - [ ] 3.2 Check bullet spawn count and ammo reduction each shot.
  - [ ] 3.3 Validate behavior when firing with no ammo.
  - [ ] 3.4 Run `gdformat` on modified scripts.
  - [ ] 3.5 Execute GUT tests for player shooting.
- [ ] 4.0 Create validation tests for mod JSON files to ensure all required fields load correctly.
  - [ ] 4.1 Use `json_helper.gd` to load `Mods/Core/Items/Items.json`.
  - [ ] 4.2 Assert essential keys exist in every item definition.
  - [ ] 4.3 Load NPC data from `Mods/Dimensionfall/Npcs` and ensure files parse.
  - [ ] 4.4 Format `json_helper.gd` if it is updated.
  - [ ] 4.5 Run GUT tests for mod validation.
- [ ] 5.0 Integrate coverage metrics into the test workflow and update documentation.
  - [ ] 5.1 Enable coverage output in GUT configuration.
  - [ ] 5.2 Update `README.md` with instructions to generate coverage reports.
  - [ ] 5.3 Add a step to fail CI or testing if coverage decreases.
  - [ ] 5.4 Run full test suite and confirm coverage report is produced.
*End of document*
