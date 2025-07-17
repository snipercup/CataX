## Selected maintenance goal
- Refactor for Readability & Maintainability

## Pre-Feature Development Project Tree
```text
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
### Proposed New Files
- `Scripts/InventoryUtils.gd` - Extracted helper functions for item and inventory operations.
- `/Tests/Unit/test_inventory_utils.gd` - Unit tests for `InventoryUtils.gd`.

### Existing Files Modified
- `Scripts/item_manager.gd` - Split long functions into methods in `InventoryUtils` and update calls.
- `Scripts/player.gd` - Extract repeated input and attribute logic into smaller functions with comments.
- `Scenes/ContentManager/Custom_Editors/*` - Add unsaved-change checks before closing editors.
- `/Tests/Unit/test_item_manager.gd` - Adapt tests for refactored inventory methods.

### Files To Remove
- *(none)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Implement unsaved changes detection for editors
  - [ ] 1.1 Introduce a reusable confirmation dialog in editor scripts
  - [ ] 1.2 Emit warnings when closing if data differs from `olddata`
  - [ ] 1.3 Update all editor close buttons to use the new logic
- [ ] 2.0 Refactor item_manager.gd
  - [ ] 2.1 Move helper functions like `count_items` and `get_nested_property` to `InventoryUtils.gd`
  - [ ] 2.2 Simplify `reload_weapon` workflow using new helpers
  - [ ] 2.3 Add comments and clarify variable names
- [ ] 3.0 Clean up player.gd
  - [ ] 3.1 Split input handling and stamina management into dedicated methods
  - [ ] 3.2 Document knockback and stun code sections
- [ ] 4.0 Standardize signal connections and remove unused code
  - [ ] 4.1 Audit scripts for duplicate signal connections
  - [ ] 4.2 Remove stale variables and unreachable code paths
- [ ] 5.0 Update unit tests
  - [ ] 5.1 Create tests for `InventoryUtils.gd`
  - [ ] 5.2 Update existing `test_item_manager.gd` to use refactored APIs
  - [ ] 5.3 Ensure all tests pass under GUT

*End of document*
