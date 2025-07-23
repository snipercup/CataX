## Selected maintenance goal
- Code Refactoring & Simplification (Goal #1)

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
```

## Relevant Files
### Proposed New Files
- `Scripts/player/player_movement.gd` - Handles player movement.
- `Scripts/player/player_combat.gd` - Handles player combat logic.
- `Scripts/player/player_interaction.gd` - Handles player environment interactions.
- `Scripts/inventory/inventory_manager.gd` - Encapsulates inventory logic.
- `Scripts/inventory/crafting_manager.gd` - Encapsulates crafting logic.
- `Scripts/Editors/item_editor_base.gd` - Shared functionality for item editors.
- `/Tests/Unit/player_module_tests.gd` - Unit tests for player modules.
- `/Tests/Unit/item_manager_tests.gd` - Unit tests for inventory and crafting managers.

### Existing Files Modified
- `Scripts/player.gd` - Split into modular components.
- `Scripts/item_manager.gd` - Use dedicated inventory and crafting managers.
- `Scripts/Item*Editor.gd` scripts - Inherit from new base class.
- `Scripts/CraftingMenu.gd` - Simplify UI update flow.
- `Scripts/Helper/SignalBroker/signal_broker.gd` - Centralize signal connections.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.


## Tasks
- [ ] 1.0 Modularize Player.gd by splitting movement, combat, and interaction into separate scripts
  - [ ] 1.1 Review `Scripts/player.gd` and mark sections for movement, combat, and interaction
  - [ ] 1.2 Create `Scripts/player/player_movement.gd` and migrate movement code
  - [ ] 1.3 Create `Scripts/player/player_combat.gd` and migrate combat logic
  - [ ] 1.4 Create `Scripts/player/player_interaction.gd` and migrate interaction functions
  - [ ] 1.5 Update `player.gd` to instantiate and call the new modules
  - [ ] 1.6 Add tests in `/Tests/Unit/player_module_tests.gd` for the new scripts
- [ ] 2.0 Simplify ItemManager.gd by extracting inventory and crafting logic into smaller components
  - [ ] 2.1 Implement `Scripts/inventory/inventory_manager.gd` for inventory operations
  - [ ] 2.2 Implement `Scripts/inventory/crafting_manager.gd` for crafting logic
  - [ ] 2.3 Refactor `Scripts/item_manager.gd` to use these managers
  - [ ] 2.4 Update scenes and scripts that depend on `item_manager.gd`
  - [ ] 2.5 Add tests in `/Tests/Unit/item_manager_tests.gd` for new functionality
- [ ] 3.0 Introduce a base class for item editor scripts to reduce duplicate code
  - [ ] 3.1 Identify shared functionality among `Scripts/Editors/*` item editors
  - [ ] 3.2 Create `Scripts/Editors/item_editor_base.gd` with common methods
  - [ ] 3.3 Make item editor scripts inherit from the new base class
  - [ ] 3.4 Verify editors still operate correctly in game and editor
- [ ] 4.0 Refactor CraftingMenu.gd for clearer UI update flow
  - [ ] 4.1 Break up long UI update functions into smaller helpers
  - [ ] 4.2 Connect menu logic to the new inventory and crafting managers
  - [ ] 4.3 Simplify signal connections and callbacks
  - [ ] 4.4 Add tests or manual checks to ensure the menu updates correctly
- [ ] 5.0 Standardize signal connections through SignalBroker to improve readability
  - [ ] 5.1 Audit existing scripts for direct signal connections
  - [ ] 5.2 Extend `Scripts/Helper/SignalBroker/signal_broker.gd` with required events
  - [ ] 5.3 Replace direct connections with broker-based ones throughout the project
  - [ ] 5.4 Test that signals fire as expected after refactoring

