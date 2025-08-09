## Pre-Feature Development Project Tree
- Scenes
  - UI
  - Overmap
  - ContentManager
- Assets
  - Fonts
- Mods
  - Core
  - Backrooms
  - Dimensionfall
  - Test
- Shaders
- Images
  - Main menu
  - Icons
- Defaults
  - Projectiles
  - Shaders
  - Blocks
  - Player
  - Mobs
  - Sprites
- Documentation
  - Game_design
  - Modding
  - Game_development
- Media
- Sounds
  - Music
  - SFX
  - Ambience
- Scripts
  - Runtimedata
  - Mob
  - Components
  - Helper
  - Gamedata
- Textures
- Tests
  - Unit

## Relevant Files
- `Scenes/ContentManager/Custom_Editors/Scripts/ItemgroupEditor.gd` - Editor logic for managing item drops.
- `Scripts/Gamedata/DItemgroup.gd` - Defines item group data structure.
- `Scripts/Runtimedata/RItemgroup.gd` - Runtime representation of item groups.
- `Documentation/Modding/Getting_started.md` - Existing modding guide referencing item groups.

### Proposed New Files
- `Tests/Unit/test_itemgroup_editor.gd` - Unit tests verifying duplicate item drops are ignored.
- `Documentation/Modding/itemgroup_uniqueness.md` - Guidelines for modders on unique item drops.

### Existing Files Modified
- `Scenes/ContentManager/Custom_Editors/Scripts/ItemgroupEditor.gd` - Enforces unique item drops and displays inline feedback.
- `Scripts/Gamedata/DItemgroup.gd` - Adds cleanup logic for legacy duplicates.
- `Scripts/Runtimedata/RItemgroup.gd` - Silently ignores duplicates at runtime.
- `Documentation/Modding/Getting_started.md` - Notes that duplicate drops are removed.
- `/Tests/Unit/test_map_manager.gd` - Update expectations for unique item groups.

### Notes

- Unit tests should typically be placed in /Tests/Unit/.
- Duplicates should be removed silently with debug logs available for modders; metadata differences still treated as duplicates.

## Tasks

- [ ] 1.0 Ensure item drops are unique in the itemgroup editor
  - [ ] 1.1 Locate the itemgroup editor code to understand how item drops are stored and manipulated
  - [ ] 1.2 Update the drop-adding mechanism to check for existing entries and avoid inserting duplicates
  - [ ] 1.3 Add an automated cleanup step in the editor to remove duplicates from legacy data if necessary (backed by task #3)
  - [ ] 1.4 Display a brief inline message in the editor UI when a duplicate drop is attempted, highlighting its removal
- [ ] 2.0 Create unit tests verifying duplicate item drops are ignored
  - [ ] 2.1 Write tests that attempt to insert duplicates into an itemgroup and confirm only one instance remains
  - [ ] 2.2 Add tests verifying that already duplicated entries in a save file or configuration are cleaned up during load
  - [ ] 2.3 Ensure tests cover edge cases such as identical items with different metadata or drop quantities
- [ ] 3.0 Confirm existing itemgroups remain unchanged and require no cleanup
  - [ ] 3.1 Scan the existing itemgroup data for duplicates and record any findings
  - [ ] 3.2 Validate that the cleanup logic in task 1.3 handles all duplicates found in the scan
  - [ ] 3.3 Document which itemgroups were checked and confirm that no manual cleanup is needed post-update
- [ ] 4.0 Suppress user notifications when duplicates are dropped
  - [ ] 4.1 Identify where notifications or logs are generated for duplicate drops
  - [ ] 4.2 Modify logic so duplicates are silently ignored, ensuring any necessary logs remain only for debugging (e.g., debug mode)
  - [ ] 4.3 Test to verify no user-facing notification appears when a duplicate drop is processed
- [ ] 5.0 Document itemgroup uniqueness expectations for modders
  - [ ] 5.1 Update the modding documentation to explain that item drops must be unique and duplicates are ignored
  - [ ] 5.2 Provide an example of adding unique drops to an itemgroup in documentation
  - [ ] 5.3 Mention any limitations or edge cases (e.g., metadata differences still treated as duplicates)
  - [ ] 5.4 Highlight any debug-only logging available for modders to detect attempted duplicates

*End of document*
