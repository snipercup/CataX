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
- `Tests/Unit/test_item_detector_cleanup.gd` - Tests removal of invalid entries from ItemDetector.
### Existing Files Modified
- `Scripts/ItemDetector.gd` - Ensure dictionaries are cleaned up and avoid memory leaks.
### Files To Remove
- *(none)*
### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 2.0 Clean up ItemDetector proximity lists
  - [ ] 2.1 Remove invalid areas and bodies each frame.
  - [ ] 2.2 Verify dictionaries cleared when nodes exit.
  - [ ] 2.3 Add unit test for cleanup logic.
