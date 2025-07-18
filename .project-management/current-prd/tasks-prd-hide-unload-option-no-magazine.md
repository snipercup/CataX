## Pre-Feature Development Project Tree
```bash
./
├── AGENTS.md
├── Assets/
├── Defaults/
├── Documentation/
├── FeatureList.md
├── Images/
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelGenerator.gd.uid
├── LevelManager.gd
├── LevelManager.gd.uid
├── Main_menu_buttons.tres
├── Media/
├── Mods/
├── README.md
├── Scenes/
├── Scripts/
├── Shaders/
├── Sounds/
├── Tests/
├── Textures/
├── day_night.gd
├── day_night.gd.uid
├── day_night.tscn
├── documentation.tscn
├── entity_manager.gd
├── entity_manager.gd.uid
├── export_presets.cfg
├── front_light.gd
├── front_light.gd.uid
├── front_light.tscn
├── hud.tscn
├── icon.svg
├── icon.svg.import
├── level_generation.tscn
├── override.cfg
├── project.godot
├── scene_selector.tscn
├── spot_light_3d.tscn
├── spot_light_3d_2.tscn
├── test_environment.gd
├── test_environment.gd.uid
├── test_environment.tscn
└── torso.aseprite

13 directories, 33 files
```

## Relevant Files
- `Scripts/CtrlInventoryStackedCustom.gd`
- `Scripts/item_manager.gd`
- `Scenes/UI/CtrlInventoryStackedCustom.tscn`

### Proposed New Files
- `Tests/Unit/test_unload_option_visibility.gd` - Tests for hiding the `Unload` option when no magazine is inserted.

### Existing Files Modified
- `Scripts/CtrlInventoryStackedCustom.gd` - Add magazine check when building the context menu.
- `Scripts/item_manager.gd` - Ensure magazine insertion/removal updates `current_magazine` property.

### Notes
- Unit tests should be placed in `/Tests/Unit/`.
- Reuse existing reload and unload logic to determine when a magazine is present.

## Tasks
- [ ] **1.0 Update inventory context menu logic**
  - [ ] 1.1 Modify `_can_unload()` in `CtrlInventoryStackedCustom.gd` to return `false` if `current_magazine` is null.
  - [ ] 1.2 Ensure `_build_context_menu()` only adds the `Unload` action when `_can_unload()` returns `true`.
- [ ] **2.0 Track inserted magazines on weapons**
  - [ ] 2.1 Verify `insert_magazine()` and `unload_magazine_from_item()` in `item_manager.gd` correctly set and clear `current_magazine`.
  - [ ] 2.2 Update any related code paths to maintain this property after reload or drop actions.
- [ ] **3.0 Maintain context menu order**
  - [ ] 3.1 Review action insertion order in `_build_context_menu()`.
  - [ ] 3.2 Adjust code or tests if the order changes after implementing the magazine check.
- [ ] **4.0 Add unit tests for unload option visibility**
  - [ ] 4.1 Create `test_unload_option_visibility.gd`.
  - [ ] 4.2 Test that guns without a magazine do not show the `Unload` option.
  - [ ] 4.3 Test that guns with a magazine show the option in the expected order.
- [ ] **5.0 Manual regression testing**
  - [ ] 5.1 Launch the game and open the inventory UI.
  - [ ] 5.2 Right-click guns with and without magazines to verify the menu behaves correctly.
*End of document*
