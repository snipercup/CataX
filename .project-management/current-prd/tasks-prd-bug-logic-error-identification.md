## Selected maintenance goal
- 3: Bug & Logic Error Identification

## Pre-Feature Development Project Tree
```
.
./Assets
./Defaults
./Documentation
./Images
./Media
./Mods
./Scenes
./Scripts
./Shaders
./Sounds
./Tests
./Textures
```

## Relevant Files
- Reference *existing* project files here

### Proposed New Files
- `Scripts/Mob/state.gd` - Define `Transitioned` signal to replace misspelled `Transistioned`.
- `/Tests/Unit/test_state_transitions.gd` - Unit tests for state signal handling.
- `Scripts/Mob/MobRangedAttack.gd` - Use mob data to set ranged cooldown and projectile speed.
- `/Tests/Unit/test_mob_ranged_attack.gd` - Unit tests for ranged attack timing and speed.
- `Scripts/EquippedItem.gd` - Compute ranged attack stats based on player and item properties.
- `/Tests/Unit/test_equipped_item_ranged.gd` - Unit tests for ranged attack calculation.
- `Scenes/ContentManager/Mapeditor/Scripts/mapeditor.gd` - Check for unsaved changes before closing.
- `/Tests/Unit/test_mapeditor_unsaved_changes.gd` - Unit tests for unsaved change detection.
- `Scripts/CtrlInventoryStackedCustom.gd` - Restrict equippable items by weight and size.
- `/Tests/Unit/test_ctrl_inventory_stack_custom.gd` - Unit tests for equip restriction logic.

### Existing Files Modified
- `Scripts/Mob/state.gd` - Rename `Transistioned` signal for clarity.
- `Scripts/Mob/MobRangedAttack.gd` - Replace hard‑coded values with mob data properties.
- `Scripts/EquippedItem.gd` - Implement dynamic ranged attack damage/hit chance.
- `Scenes/ContentManager/Mapeditor/Scripts/mapeditor.gd` - Prompt to save changes when closing.
- `Scripts/CtrlInventoryStackedCustom.gd` - Prevent heavy/large items from being equipped.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Fix misnamed mob state transition signal
  - [ ] 1.1 In `Scripts/Mob/state.gd`, rename the `Transistioned` signal to `Transitioned`.
  - [ ] 1.2 Update all references to the old signal name across the codebase.
  - [ ] 1.3 Add unit tests (`Tests/Unit/test_state_transitions.gd`) verifying that `Transitioned` fires correctly when state changes occur.
- [ ] 2.0 Expose ranged attack cooldown and projectile speed through mob data
  - [ ] 2.1 Modify `Scripts/Mob/MobRangedAttack.gd` to pull cooldown and projectile speed from mob data instead of hard‑coding them.
  - [ ] 2.2 Ensure mob data definitions include fields for ranged cooldown and projectile speed where applicable.
  - [ ] 2.3 Write unit tests (`Tests/Unit/test_mob_ranged_attack.gd`) confirming that cooldown and projectile speed are applied per mob data.
- [ ] 3.0 Rework ranged weapon attack calculation for equipped items
  - [ ] 3.1 Enhance `Scripts/EquippedItem.gd` to compute ranged attack damage and hit chance dynamically based on player stats and item properties.
  - [ ] 3.2 Validate that derived values properly update during gameplay.
  - [ ] 3.3 Add unit tests (`Tests/Unit/test_equipped_item_ranged.gd`) to check calculations for several item/player combinations.
- [ ] 4.0 Add unsaved changes detection in map editor
  - [ ] 4.1 In `Scenes/ContentManager/Mapeditor/Scripts/mapeditor.gd`, track whether current map edits differ from the last saved state.
  - [ ] 4.2 Prompt the user to save or discard changes when closing the editor with unsaved modifications.
  - [ ] 4.3 Provide unit tests (`Tests/Unit/test_mapeditor_unsaved_changes.gd`) ensuring unsaved edits are detected and prompts triggered accordingly.
- [ ] 5.0 Restrict equippable items based on weight and size
  - [ ] 5.1 Implement logic in `Scripts/CtrlInventoryStackedCustom.gd` to disallow equipping items exceeding defined weight or size thresholds.
  - [ ] 5.2 Make thresholds configurable or clearly defined for various inventory slots.
  - [ ] 5.3 Add unit tests (`Tests/Unit/test_ctrl_inventory_stack_custom.gd`) verifying that heavy/large items cannot be equipped and valid items still equip normally.

*End of document*
