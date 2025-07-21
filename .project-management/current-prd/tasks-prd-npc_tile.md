## Pre-Feature Development Project Tree
```
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
│   └── Catax_itemgroup_editor.png.import
```

## Relevant Files
### Proposed New Files
- `Tests/Unit/test_npc_tile.gd` - Unit tests verifying npc_tile save/load and processing.
### Existing Files Modified
- `Scenes/ContentManager/Mapeditor/mapeditor_brushcomposer.tscn` - UI button for npc_tile.
- `Scenes/ContentManager/Mapeditor/Scripts/mapeditor_brushcomposer.gd` - Handle npc_tile button logic.
- `Scenes/ContentManager/Mapeditor/Scripts/GridContainer.gd` - Paint rules for npc_tile.
- `Scenes/ContentManager/Mapeditor/Scripts/mapeditortile.gd` - Display npc_tile icon.
- `Scripts/Gamedata/DMap.gd` - Persist npc_tile data in maps.
- `Scripts/Helper/map_manager.gd` - Remove npc_tile during load and print message.

### Notes
- npc_tile uses `res://Scenes/ContentManager/Mapeditor/Images/nulltile_32.png` as its icon.
- Data stored per tile like other entities; not tracked in references.

## Tasks
- [ ] 1.0 Add npc_tile button to brush composer scene and connect signal.
  - [ ] 1.1 Create a new button node next to the existing null_tile button.
  - [ ] 1.2 Assign `res://Scenes/ContentManager/Mapeditor/Images/nulltile_32.png` as its icon.
  - [ ] 1.3 Connect the button's `button_up` signal to mapeditor_brushcomposer.gd.
- [ ] 2.0 Extend mapeditor_brushcomposer.gd with `_on_npc_tile_button_up` and property handling.
  - [ ] 2.1 Add a boolean property tracking npc_tile brush selection.
  - [ ] 2.2 Implement `_on_npc_tile_button_up()` to toggle this property and update UI state.
  - [ ] 2.3 Update brush selection logic to support the npc_tile brush.
- [ ] 3.0 Update GridContainer.gd to support painting and erasing npc_tile according to rules.
  - [ ] 3.1 When painting npc_tile, clear any mob, mobgroup, furniture or itemgroup entry on the same tile.
  - [ ] 3.2 Ensure npc_tile flag is set when painted and cleared when overwritten by other entities.
- [ ] 4.0 Show npc_tile icon in mapeditortile.gd when data present.
  - [ ] 4.1 Display the placeholder icon on tiles where npc_tile is set.
  - [ ] 4.2 Remove the icon when the npc_tile flag is cleared.
- [ ] 5.0 Store npc_tile flag in DMap serialization and loading.
  - [ ] 5.1 Extend tile data structures to include an `npc_tile` flag.
  - [ ] 5.2 Write this flag to JSON when saving maps.
  - [ ] 5.3 Read the flag from JSON during map load.
- [ ] 6.0 Process npc_tile in map_manager.gd, printing debug and removing entry on load.
  - [ ] 6.1 Detect npc_tile entries after loading a map.
  - [ ] 6.2 Print a debug statement for each npc_tile processed.
  - [ ] 6.3 Remove npc_tile entries from map data once handled.
- [ ] 7.0 Add GUT tests covering npc_tile save/load and processing behavior.
  - [ ] 7.1 Verify npc_tile is saved and loaded through DMap.
  - [ ] 7.2 Confirm map_manager prints and clears npc_tile entries on load.
  - [ ] 7.3 Test painting rules to ensure conflicting entities overwrite npc_tile and vice versa.
*End of document*
