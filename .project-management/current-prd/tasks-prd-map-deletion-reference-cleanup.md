## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Assets
│   └── Fonts
├── Defaults
│   ├── Blocks
│   ├── Mobs
│   ├── Player
│   ├── Projectiles
│   ├── Shaders
│   └── Sprites
├── Documentation
│   ├── Game_design
│   ├── Game_development
│   └── Modding
├── FeatureList.md
├── Images
│   ├── Icons
│   └── Main menu
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelGenerator.gd.uid
├── LevelManager.gd
├── LevelManager.gd.uid
├── Main_menu_buttons.tres
├── Media
│   ├── Catax_basic.png
│   ├── Catax_basic.png.import
│   ├── Catax_basic_zoomed_out.png
│   ├── Catax_basic_zoomed_out.png.import
│   ├── Catax_content_editor.png
│   ├── Catax_content_editor.png.import
│   ├── Catax_crafting_editor.png
│   ├── Catax_crafting_editor.png.import
│   ├── Catax_furniture_editor.png
│   ├── Catax_furniture_editor.png.import
│   ├── Catax_item_editor.png
│   ├── Catax_item_editor.png.import
│   ├── Catax_itemgroup_editor.png
```

## Relevant Files
- `Scripts/Gamedata/DMap.gd`
- `Scripts/Gamedata/DNpc.gd`
- `Scripts/Gamedata/DOvermaparea.gd`
- `Scripts/Gamedata/DQuest.gd`
- `Mods/*/Maps/references.json`
- `Tests/Unit/`

### Proposed New Files
- `Tests/Unit/test_map_deletion_reference_cleanup.gd` - Tests for map deletion reference cleanup.

### Existing Files Modified
- `Scripts/Gamedata/DMap.gd` - Update delete logic and reference removal.
- `Scripts/Gamedata/DNpc.gd` - Remove map from NPC spawn lists.
- `Scripts/Gamedata/DOvermaparea.gd` - Remove map from overmap region lists.
- `Scripts/Gamedata/DQuest.gd` - Remove map references from quests.
- `Mods/*/Maps/references.json` - References file updated after deletion.

### Notes
- Unit tests go under `Tests/Unit`.
- Follow GDScript 4 syntax with tabs for indentation.

## Tasks
- [ ] **1.0 Review existing map deletion logic (`Scripts/Gamedata/DMap.gd`) against the specification.**
  - [ ] 1.1 Open `feature-specification.md` and compare current `delete()` and `remove_my_reference_from_all_entities()` with requirements.
  - [ ] 1.2 Identify gaps in reference cleanup and note required changes.
- [ ] **2.0 Update deletion process to remove references from NPCs, overmap areas and quests.**
  - [ ] 2.1 Load `/maps/references.json` to get lists of related NPCs, overmap areas and quests.
  - [ ] 2.2 For each NPC ID, remove the deleted map from its `spawn_maps` array and save using `DNpc`.
  - [ ] 2.3 For each overmap area ID, call `remove_map_from_all_regions(map_id)` and save.
  - [ ] 2.4 For each quest ID, remove or update steps referencing the map and save.
- [ ] **3.0 Ensure `/maps/references.json` is updated by removing the map entry.**
  - [ ] 3.1 After cleaning entities, delete the map key from the references dictionary.
  - [ ] 3.2 Save the updated JSON to disk.
- [ ] **4.0 Implement debug logging when reference removal fails.**
  - [ ] 4.1 When an entity is missing or locked, log a debug message describing the failure.
  - [ ] 4.2 Continue processing other entities after logging.
- [ ] **5.0 Add unit tests validating cleanup.**
  - [ ] 5.1 Create `test_map_deletion_reference_cleanup.gd` under `Tests/Unit`.
  - [ ] 5.2 Set up mock data for NPCs, overmap areas, quests and a map with references.
  - [ ] 5.3 Delete the map using `DMap.delete()` and assert NPCs, overmap areas, quests and the references file no longer include the map ID.
  - [ ] 5.4 Run tests via GUT to verify they pass.
*End of document*
