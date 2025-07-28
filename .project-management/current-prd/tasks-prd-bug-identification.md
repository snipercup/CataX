## Selected maintenance goal
- 3. Bug & Logic Error Identification

## Pre-Feature Development Project Tree
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

## Relevant Files
### Proposed New Files
- `Scripts/tests/test_client_optional.gd` - Verifies the game loads without Nakama installed.
- `Tests/Unit/test_item_detector_cleanup.gd` - Tests removal of invalid entries from ItemDetector.
### Existing Files Modified
- `Scripts/Client.gd` - Guard Nakama usage when plugin is unavailable.
- `Scripts/ItemDetector.gd` - Ensure dictionaries are cleaned up and avoid memory leaks.
- `LevelGenerator.gd` - Refine queue logic for chunk management.
- `Scripts/item_manager.gd` - Fix magazine handling during reloads.
- `Scripts/Helper/save_helper.gd` - Add error checks when saving.
- `Scripts/Helper/map_manager.gd` - Validate spawn functions and file operations.
### Files To Remove
- *(none)*
### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Guard Nakama dependency
  - [ ] 1.1 Detect Nakama plugin availability at runtime.
  - [ ] 1.2 Provide fallback or disable networking when missing.
  - [ ] 1.3 Add test ensuring game loads without the plugin.
- [ ] 2.0 Clean up ItemDetector proximity lists
  - [ ] 2.1 Remove invalid areas and bodies each frame.
  - [ ] 2.2 Verify dictionaries cleared when nodes exit.
  - [ ] 2.3 Add unit test for cleanup logic.
- [ ] 3.0 Review LevelGenerator queue processing
  - [ ] 3.1 Prevent duplicate entries in load/unload queues.
  - [ ] 3.2 Confirm `process_next_chunk` cannot hang.
  - [ ] 3.3 Unit test chunk loading/unloading edge cases.
- [ ] 4.0 Validate ItemManager reloading
  - [ ] 4.1 Ensure magazines are removed from inventory when loaded.
  - [ ] 4.2 Reset `is_reloading` correctly after reload.
  - [ ] 4.3 Document reloading workflow.
- [ ] 5.0 Improve save/load error handling
  - [ ] 5.1 Add checks for directory creation failures.
  - [ ] 5.2 Gracefully handle missing files in map_manager.
  - [ ] 5.3 Test load/save with incomplete data.
