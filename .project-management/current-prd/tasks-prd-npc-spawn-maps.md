## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
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
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelGenerator.gd.uid
├── LevelManager.gd
├── LevelManager.gd.uid
├── Main_menu_buttons.tres
├── Mods
│   ├── Backrooms
│   ├── Core
│   ├── Dimensionfall
│   └── Test
├── README.md
├── Scenes
│   ├── ContentManager
│   ├── GameOver.tscn
│   ├── InventoryContainerListItem.tscn
│   ├── InventoryWindow.tscn
│   ├── LoadingScreen.tscn
│   ├── Overmap
│   ├── UI
│   ├── input_manager.tscn
│   └── player.tscn
├── Scripts
│   ├── AttributesWindow.gd
│   ├── AttributesWindow.gd.uid
│   ├── BuildManager.gd
│   ├── BuildManager.gd.uid
│   ├── BuildingMenu.gd
│   ├── BuildingMenu.gd.uid
│   ├── Camera.gd
│   ├── Camera.gd.uid
│   ├── CharacterWindow.gd
│   ├── CharacterWindow.gd.uid
│   ├── Chunk.gd
│   ├── Chunk.gd.uid
│   ├── ChunkLevel.gd
│   ├── ChunkLevel.gd.uid
│   ├── Client.gd
│   ├── Client.gd.uid
│   ├── Components
│   ├── ConstructionGhost.gd
│   ├── ConstructionGhost.gd.uid
│   ├── CraftingMenu.gd
│   ├── CraftingMenu.gd.uid
│   ├── CtrlInventoryStackedCustom.gd
│   ├── CtrlInventoryStackedCustom.gd.uid
│   ├── CtrlInventoryStackedListItem.gd
│   ├── CtrlInventoryStackedListItem.gd.uid
│   ├── CtrlInventoryStackedlistHeaderItem.gd
│   ├── CtrlInventoryStackedlistHeaderItem.gd.uid
│   ├── Documentation.gd
│   ├── Documentation.gd.uid
│   ├── EquipmentSlot.gd
│   ├── EquipmentSlot.gd.uid
│   ├── EquippedItem.gd
│   ├── EquippedItem.gd.uid
│   ├── EscapeMenu.gd
│   ├── EscapeMenu.gd.uid
│   ├── FurnitureBlueprintSpawner.gd
│   ├── FurnitureBlueprintSpawner.gd.uid
│   ├── FurnitureBlueprintSrv.gd
│   ├── FurnitureBlueprintSrv.gd.uid
│   ├── FurnitureConstructionWindow.gd
│   ├── FurnitureConstructionWindow.gd.uid
│   ├── FurniturePhysicsSpawner.gd
```
## Relevant Files
- `Scripts/Gamedata/DNpc.gd` - NPC data model for persistent data
- `Scripts/Gamedata/DNpcs.gd` - Container for DNpc entries and disk operations
- `Scripts/Runtimedata/RNpc.gd` - Runtime NPC representation
- `Scenes/ContentManager/Custom_Editors/NpcEditor.tscn` - UI scene for editing NPCs
- `Scenes/ContentManager/Custom_Editors/Scripts/NpcEditor.gd` - Logic for NPC editor
- `Scenes/ContentManager/Custom_Widgets/Scripts/overmap_area_region_editor.gd` - Reference implementation for drag/drop grid
- `Mods/Dimensionfall/Npcs/hank.json` - Sample NPC JSON file
- `Tests/Unit/test_npc_editor.gd` - Existing editor unit tests
### Proposed New Files
- `/Tests/Unit/test_npc_spawn_maps.gd` - Unit tests covering spawn map persistence and UI
### Existing Files Modified
- `Scripts/Gamedata/DNpc.gd` - Add spawn_maps and related methods
- `Scripts/Gamedata/DNpcs.gd` - Load and save spawn_maps
- `Scripts/Runtimedata/RNpc.gd` - Mirror spawn_maps from DNpc
- `Scenes/ContentManager/Custom_Editors/NpcEditor.tscn` - Add grid container for spawn maps
- `Scenes/ContentManager/Custom_Editors/Scripts/NpcEditor.gd` - Implement spawn map UI logic
- `Mods/Dimensionfall/Npcs/hank.json` - Example spawn_maps field
- `Tests/Unit/test_npc_editor.gd` - Update for new editor fields
### Notes
- Unit tests are stored under `/Tests/Unit/` using GUT
- Use GDScript 4.4 syntax with tabs and follow patterns from `overmap_area_region_editor.gd`

## Tasks
- [x] **1.0 Add `spawn_maps` array to NPC data structures**
  - [x] 1.1 Extend `DNpc.gd` with a `spawn_maps` Array property and default empty array
  - [x] 1.2 Load `spawn_maps` from JSON in `DNpc._init`
  - [x] 1.3 Include `spawn_maps` in `DNpc.get_data`
  - [x] 1.4 Mirror property in `RNpc.gd` and copy values in `overwrite_from_dnpc`
- [ ] **2.0 Implement spawn map UI in NpcEditor**
  - [ ] 2.1 Add a GridContainer named `SpawnMapsGrid` to `NpcEditor.tscn`
  - [ ] 2.2 Populate entries with sprite preview, map id label, weight SpinBox and delete button
  - [ ] 2.3 Enable dragging map entries from content lists using drop callbacks
  - [ ] 2.4 Provide delete functionality and update `DNpc.spawn_maps`
  - [ ] 2.5 Load existing spawn maps when an NPC is assigned and gather grid values on save
- [ ] **3.0 Persist spawn maps in NPC JSON files**
  - [ ] 3.1 Update `DNpcs.save_npcs_to_disk` to write `spawn_maps`
  - [ ] 3.2 Parse `spawn_maps` in `DNpcs.load_npcs_from_disk`
  - [ ] 3.3 Add spawn map example to `Mods/Dimensionfall/Npcs/hank.json`
- [ ] **4.0 Update mod dependency tracking**
  - [ ] 4.1 Call `Gamedata.mods.add_reference` when a map is added to an NPC
  - [ ] 4.2 Call `Gamedata.mods.remove_reference` when removed or NPC deleted
- [ ] **5.0 Add automated tests**
  - [ ] 5.1 Write `test_npc_spawn_maps.gd` verifying save and load behavior
  - [ ] 5.2 Extend `test_npc_editor.gd` to check grid population and weight editing
  - [ ] 5.3 Ensure dependency functions are invoked when entries change
*End of document*
