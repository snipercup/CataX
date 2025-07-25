## Selected maintenance goal
- 3: Bug & Logic Error Identification

## Pre-Feature Development Project Tree
```
    .
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
    ├── Images
    │   ├── Icons
    │   └── Main menu
    ├── Media
    │   ├── Catax_basic.png
    │   ├── Catax_basic.png.import
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
```

## Relevant Files
### Proposed New Files
- `Tests/Unit/test_map_manager_null_chunk.gd` - Unit tests for spawning items and mobs when chunks are missing.
- `Tests/Unit/test_level_generator_missing_map_cell.gd` - Test LevelGenerator's map cell retrieval with invalid coordinates.
- `Tests/Unit/test_general_string_to_vector2.gd` - Validate string_to_vector2 with malformed strings.

### Existing Files Modified
- `Scripts/Helper/map_manager.gd` - Add null checks when retrieving chunks and containers.
- `LevelGenerator.gd` - Guard against missing map cell data.
- `Scripts/bullet.gd` - Ensure collision callbacks handle null bodies safely.
- `Scripts/general.gd` - Improve parsing logic in string_to_vector2.

### Files To Remove
- _None_

### Notes
- Unit tests should be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Harden chunk retrieval and item spawning
  - [ ] 1.1 Add null-checks in `spawn_item_at_current_player_map` and `spawn_mob_at_nearby_map`.
  - [ ] 1.2 Update related unit tests to cover missing chunk scenarios.
- [ ] 2.0 Prevent crashes when map cells are missing
  - [ ] 2.1 Modify `LevelGenerator.get_chunk_data_at_position` to verify the map cell exists before use.
  - [ ] 2.2 Add a GUT test ensuring invalid coordinates return default data without errors.
- [ ] 3.0 Safe bullet collision handling
  - [ ] 3.1 Ensure `_on_body_shape_entered` and `_on_area_3d_body_shape_entered` skip null bodies and log appropriately.
- [ ] 4.0 Validate utility parsing functions
  - [ ] 4.1 Improve `string_to_vector2` to handle malformed strings gracefully.
  - [ ] 4.2 Add tests for valid and invalid input strings.
- [ ] 5.0 New edge-case unit tests
  - [ ] 5.1 Implement new test files listed above and ensure all tests pass.
