## Selected maintenance goal
- **Main gameplay logic refactoring**

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
...
│   ├── ItemMedicalEditor.gd
│   ├── ItemMedicalEditor.gd.uid
│   ├── ItemMeleeEditor.gd
│   ├── ItemMeleeEditor.gd.uid
│   ├── ItemRangedEditor.gd
│   ├── ItemRangedEditor.gd.uid
│   ├── ItemToolEditor.gd
│   ├── ItemToolEditor.gd.uid
│   ├── ItemWearableEditor.gd
│   ├── ItemWearableEditor.gd.uid
│   ├── LoadingScreen.gd
│   ├── LoadingScreen.gd.uid
│   ├── Mob
│   ├── NonHUDclick.gd
│   ├── NonHUDclick.gd.uid
│   ├── OvermapGrid.gd
│   ├── OvermapGrid.gd.uid
│   ├── PlayerAttribute.gd
│   ├── PlayerAttribute.gd.uid
...
├── test_environment.tscn
└── torso.aseprite
```

## Relevant Files
- `Scripts/player.gd`
- `Scenes/player.tscn`
- `Scripts/item_manager.gd`
- `Scripts/Helper/map_manager.gd`
- `Scripts/Helper/SignalBroker/signal_broker.gd`
- `Tests/Unit/test_item_manager.gd`

### Proposed New Files
- `Scripts/Components/PlayerMovement.gd` - Handles player movement logic.
- `Scripts/Components/PlayerAttributes.gd` - Encapsulates player attribute updates.
- `Scripts/Components/PlayerInteraction.gd` - Manages interaction checks and raycasts.
- `Scripts/Helper/inventory_utils.gd` - Reusable inventory helper functions.
- `Scripts/Helper/map_area_processor.gd` - Functions for map area processing.
- `Tests/Unit/test_player_movement.gd` - Unit tests for `PlayerMovement.gd`.
- `Tests/Unit/test_inventory_utils.gd` - Unit tests for `inventory_utils.gd`.
- `Tests/Unit/test_map_area_processor.gd` - Unit tests for map area processing.

### Existing Files Modified
- `Scripts/player.gd` - Refactored to delegate logic to components.
- `Scenes/player.tscn` - Adds component nodes for the player.
- `Scripts/item_manager.gd` - Simplified with helper functions.
- `Scripts/Helper/map_manager.gd` - Delegates area processing.
- `Scripts/Helper/SignalBroker/signal_broker.gd` - Updated signal definitions.
- `Tests/Unit/test_item_manager.gd` - Adjusted to new inventory logic.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] **1.0 Refactor Player.gd into modular components**
  - [ ] **1.1 Identify movement, attribute and interaction logic sections in Player.gd**
  - [ ] **1.2 Create `PlayerMovement.gd`, `PlayerAttributes.gd`, and `PlayerInteraction.gd` under `Scripts/Components`**
  - [ ] **1.3 Move the corresponding code from Player.gd into these modules**
  - [ ] **1.4 Update `player.gd` and `player.tscn` to use the new components**
  - [ ] **1.5 Manually test player controls to ensure behaviour is unchanged**
- [ ] **2.0 Simplify ItemManager.gd and consolidate inventory logic**
  - [ ] **2.1 Review duplicate inventory operations in ItemManager.gd**
  - [ ] **2.2 Implement `Scripts/Helper/inventory_utils.gd` with common functions**
  - [ ] **2.3 Replace duplicated code in ItemManager.gd with calls to inventory_utils**
  - [ ] **2.4 Update unit tests in `test_item_manager.gd` to fit new logic**
  - [ ] **2.5 Verify signals still emit correctly after refactor**
- [ ] **3.0 Extract map area processing from map_manager.gd into helper modules**
  - [ ] **3.1 Create `map_area_processor.gd` with area processing functions**
  - [ ] **3.2 Refactor map_manager.gd to delegate to MapAreaProcessor**
  - [ ] **3.3 Add unit tests in `test_map_area_processor.gd`**
  - [ ] **3.4 Validate map generation still works via manual run**
- [ ] **4.0 Standardize signal usage across gameplay scripts**
  - [ ] **4.1 Review signals in `signal_broker.gd` and document expected patterns**
  - [ ] **4.2 Update gameplay scripts to use broker signals and typed connections**
  - [ ] **4.3 Document signal conventions in `Documentation/Game_development/signal_conventions.md`**
  - [ ] **4.4 Ensure connections are made in `_ready` and cleared in `_exit_tree`**
- [ ] **5.0 Add unit tests for refactored gameplay modules**
  - [ ] **5.1 Write tests for `PlayerMovement.gd`**
  - [ ] **5.2 Write tests for `inventory_utils.gd`**
  - [ ] **5.3 Write tests for `map_area_processor.gd`**
  - [ ] **5.4 Run `godot` unit tests to verify all pass**

*End of document*
