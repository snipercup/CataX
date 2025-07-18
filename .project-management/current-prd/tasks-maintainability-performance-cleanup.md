## Selected maintenance goal
**Goal 7 – Maintainability & Performance Cleanup**

## Pre-Feature Development Project Tree
```bash
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
│   ├── Catax_mob_editor.png.import
│   ├── Catax_overmap_large.png
│   ├── Catax_overmap_large.png.import
│   ├── Catax_playerattribute_editor.png
│   ├── Catax_playerattribute_editor.png.import
│   ├── Catax_quest_editor.png
│   ├── Catax_quest_editor.png.import
│   ├── Catax_skills_editor.png
│   ├── Catax_skills_editor.png.import
│   ├── Catax_stats_editor.png
│   ├── Catax_stats_editor.png.import
│   ├── Catax_tacticalmap_editor.png
│   ├── Catax_tacticalmap_editor.png.import
│   ├── Catax_tile_editor.png
│   ├── Catax_tile_editor.png.import
│   ├── Catax_wearableslots_editor.png
│   ├── Catax_wearableslots_editor.png.import
│   ├── Dimensionfall_add_remove_mod_menu.png
│   ├── Dimensionfall_add_remove_mod_menu.png.import
│   ├── Dimensionfall_crafting_station.png
│   ├── Dimensionfall_crafting_station.png.import
│   ├── Dimensionfall_inventory.png
│   ├── Dimensionfall_inventory.png.import
│   ├── Dimensionfall_main_menu.png
│   ├── Dimensionfall_main_menu.png.import
│   ├── Dimensionfall_mobfaction_editor.png
│   ├── Dimensionfall_mobfaction_editor.png.import
│   ├── Dimensionfall_mobgroup_editor.png
│   ├── Dimensionfall_mobgroup_editor.png.import
│   ├── Dimensionfall_overmap.png
│   ├── Dimensionfall_overmap.png.import
│   ├── Dimensionfall_overmaparea_editor.png
│   ├── Dimensionfall_overmaparea_editor.png.import
│   ├── Dimensionfall_overmaparea_generator.png
│   ├── Dimensionfall_overmaparea_generator.png.import
│   ├── Dimensionfall_quest_journal.png
│   └── Dimensionfall_quest_journal.png.import
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
│   ├── FurniturePhysicsSpawner.gd.uid
│   ├── FurniturePhysicsSrv.gd
│   ├── FurniturePhysicsSrv.gd.uid
│   ├── FurnitureStaticSpawner.gd
│   ├── FurnitureStaticSpawner.gd.uid
│   ├── FurnitureStaticSrv.gd
│   ├── FurnitureStaticSrv.gd.uid
│   ├── FurnitureWindow.gd
│   ├── FurnitureWindow.gd.uid
│   ├── GameOver.gd
│   ├── GameOver.gd.uid
│   ├── Gamedata
│   ├── HeldItem.gd
│   ├── HeldItem.gd.uid
│   ├── Helper
│   ├── Helper.gd
│   ├── Helper.gd.uid
│   ├── InventoryContainerListItem.gd
│   ├── InventoryContainerListItem.gd.uid
│   ├── InventoryWindow.gd
│   ├── InventoryWindow.gd.uid
│   ├── ItemAmmoEditor.gd
│   ├── ItemAmmoEditor.gd.uid
│   ├── ItemCraftEditor.gd
│   ├── ItemCraftEditor.gd.uid
│   ├── ItemDetector.gd
│   ├── ItemDetector.gd.uid
│   ├── ItemEditor.gd
│   ├── ItemEditor.gd.uid
│   ├── ItemFoodEditor.gd
│   ├── ItemFoodEditor.gd.uid
│   ├── ItemMagazineEditor.gd
│   ├── ItemMagazineEditor.gd.uid
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
│   ├── PlayerShooting.gd
│   ├── PlayerShooting.gd.uid
│   ├── QuestTrackerUI.gd
│   ├── QuestTrackerUI.gd.uid
│   ├── QuestWindow.gd
│   ├── QuestWindow.gd.uid
│   ├── Runtimedata
│   ├── WearableSlot.gd
│   ├── WearableSlot.gd.uid
│   ├── bullet.gd
│   ├── bullet.gd.uid
│   ├── container.gd
│   ├── container.gd.uid
│   ├── crafting_recipes_manager.gd
│   ├── crafting_recipes_manager.gd.uid
│   ├── gamedata.gd
│   ├── gamedata.gd.uid
│   ├── general.gd
│   ├── general.gd.uid
│   ├── hud.gd
│   ├── hud.gd.uid
│   ├── input_manager.gd
│   ├── input_manager.gd.uid
│   ├── item_manager.gd
│   ├── item_manager.gd.uid
│   ├── player.gd
│   ├── player.gd.uid
│   ├── runtimedata.gd
│   ├── runtimedata.gd.uid
│   ├── scene_selector.gd
│   ├── scene_selector.gd.uid
│   ├── target_manager.gd
│   ├── target_manager.gd.uid
│   ├── weapon.gd
│   └── weapon.gd.uid
├── Shaders
│   ├── HideAbovePlayer.gdshader
│   ├── HideAbovePlayer.gdshader.uid
│   ├── HideAbovePlayerShadow.gdshader
│   └── HideAbovePlayerShadow.gdshader.uid
├── Sounds
│   ├── Ambience
│   ├── Music
│   ├── SFX
│   └── default_bus_layout.tres
├── Tests
│   └── Unit
├── Textures
│   ├── 9mm.png
│   ├── 9mm.png.import
│   ├── Screenshot_167.png
│   ├── Screenshot_167.png.import
│   ├── above.png
│   ├── above.png.import
│   ├── bar_border.png
│   ├── bar_border.png.import
│   ├── bar_progress.png
│   ├── bar_progress.png.import
│   ├── bullet.png
│   ├── bullet.png.import
│   ├── container_32.png
│   ├── container_32.png.import
│   ├── container_filled_32.png
│   ├── container_filled_32.png.import
│   ├── enemy.png
│   ├── enemy.png.import
│   ├── head.png
│   ├── head.png.import
│   ├── imgonline-com-ua-TextureSeamless-vPpbshdid4ZMVqj.png
│   ├── imgonline-com-ua-TextureSeamless-vPpbshdid4ZMVqj.png.import
│   ├── leftarm.png
│   ├── leftarm.png.import
│   ├── leftleg.png
│   ├── leftleg.png.import
│   ├── pistol_magazine.png
│   ├── pistol_magazine.png.import
│   ├── plank.png
│   ├── plank.png.import
│   ├── player.png
│   ├── player.png.import
│   ├── pointer2.png
│   ├── pointer2.png.import
│   ├── pointer3.png
│   ├── pointer3.png.import
│   ├── rightarm.png
│   ├── rightarm.png.import
│   ├── rightleg.png
│   ├── rightleg.png.import
│   ├── steel_scrap.png
│   ├── steel_scrap.png.import
│   ├── survivor.png
│   ├── survivor.png.import
│   ├── torso.png
│   ├── torso.png.import
│   ├── ui_concrete.png
│   ├── ui_concrete.png.import
│   ├── under_construction_32.png
│   └── under_construction_32.png.import
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

41 directories, 278 files
```

## Relevant Files
- `Scripts/FurnitureStaticSrv.gd`
- `Scripts/ItemAmmoEditor.gd`
- `Scripts/ItemCraftEditor.gd`
- `Scripts/ItemFoodEditor.gd`
- `Scripts/ItemMagazineEditor.gd`
- `Scripts/ItemMedicalEditor.gd`
- `Scripts/ItemMeleeEditor.gd`
- `Scripts/ItemRangedEditor.gd`
- `Scripts/ItemToolEditor.gd`
- `Scripts/ItemWearableEditor.gd`
- `Scripts/ItemEditor.gd`
- `Scripts/OvermapGrid.gd`
- `.gitignore`

### Proposed New Files
- `Scripts/ItemEditorBase.gd` - Shared logic for item editor scripts.
- `Tests/Unit/test_item_editor_base.gd` - Unit tests for ItemEditorBase.

### Existing Files Modified
- `Scripts/FurnitureStaticSrv.gd` - Optimize crafting queue loops.
- `Scripts/Item*Editor.gd` - Refactor to use base class.
- `Scripts/OvermapGrid.gd` - Improve road generation performance.
- `.gitignore` - Ignore Godot-generated `.uid` and `.import` files.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.
- Apply Godot 4.4 best practices and format scripts with `gdformat`.

## Tasks
- [ ] 1.0 Improve crafting queue performance in `FurnitureStaticSrv.gd`
  - [ ] 1.1 Profile existing loops and identify bottlenecks
  - [ ] 1.2 Implement cached lookups or data structures to minimize iterations
  - [ ] 1.3 Remove extraneous debug print statements
  - [ ] 1.4 Document updated logic with comments
  - [ ] 1.5 Format the script with `gdformat`
  - [ ] 1.6 Run GUT tests to ensure no regressions
- [ ] 2.0 Consolidate duplicate item editor code
  - [ ] 2.1 Identify shared functionality across all item editor scripts
  - [ ] 2.2 Create `ItemEditorBase.gd` containing common methods
  - [ ] 2.3 Refactor each item editor to extend or use the base class
  - [ ] 2.4 Add comments explaining base class usage
  - [ ] 2.5 Add or update unit tests for editors
  - [ ] 2.6 Format all affected scripts with `gdformat`
- [ ] 3.0 Optimize road and pathfinding logic in `OvermapGrid.gd`
  - [ ] 3.1 Analyze road generation loops for inefficiencies
  - [ ] 3.2 Refactor code to eliminate redundant calculations
  - [ ] 3.3 Comment the revised algorithm for clarity
  - [ ] 3.4 Format the script and run tests
- [ ] 4.0 Standardize debug logging across scripts
  - [ ] 4.1 Search for and remove excessive `print` statements
  - [ ] 4.2 Implement a consistent logging approach guarded by a debug flag
  - [ ] 4.3 Verify no stray debug prints remain
  - [ ] 4.4 Format updated files and run tests
- [ ] 5.0 Update repository ignore rules
  - [ ] 5.1 Add `*.uid` and `*.import` patterns to `.gitignore`
  - [ ] 5.2 Comment why these files are ignored
  - [ ] 5.3 Confirm new patterns work by checking `git status`

*End of document*

