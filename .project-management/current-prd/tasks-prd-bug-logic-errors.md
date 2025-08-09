## Selected maintenance goal
- 3 – Bug & Logic Error Identification

## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Assets
│└── Fonts
├── Defaults
│├── Blocks
│├── Mobs
│├── Player
│├── Projectiles
│├── Shaders
│└── Sprites
├── FeatureList.md
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelManager.gd
├── Main_menu_buttons.tres
├── README.md
├── Scenes
│├── ContentManager
│├── Overmap
│├── UI
│├── input_manager.tscn
│└── player.tscn
├── Scripts
│├── AttributesWindow.gd
│├── BuildManager.gd
│├── BuildingMenu.gd
│├── Camera.gd
│├── CharacterWindow.gd
│├── Chunk.gd
│├── ChunkLevel.gd
│├── Client.gd
│├── Components
│├── ConstructionGhost.gd
│├── CraftingMenu.gd
│├── CtrlInventoryStackedCustom.gd
│├── CtrlInventoryStackedListItem.gd
│├── CtrlInventoryStackedlistHeaderItem.gd
│├── Documentation.gd
│├── EquipmentSlot.gd
│├── EquippedItem.gd
│├── EscapeMenu.gd
│├── FurnitureBlueprintSpawner.gd
│├── FurnitureBlueprintSrv.gd
│├── FurnitureConstructionWindow.gd
│├── FurniturePhysicsSpawner.gd
│├── FurniturePhysicsSrv.gd
│├── FurnitureStaticSpawner.gd
│├── FurnitureStaticSrv.gd
│├── FurnitureWindow.gd
│├── GameOver.gd
│├── Gamedata
│├── HeldItem.gd
│├── Helper
│├── Helper.gd
│├── InventoryContainerListItem.gd
│├── InventoryWindow.gd
│├── ItemAmmoEditor.gd
│├── ItemCraftEditor.gd
│├── ItemDetector.gd
│├── ItemEditor.gd
│├── ItemFoodEditor.gd
│├── ItemMagazineEditor.gd
│├── ItemMedicalEditor.gd
│├── ItemMeleeEditor.gd
│├── ItemRangedEditor.gd
│├── ItemToolEditor.gd
│├── ItemWearableEditor.gd
│├── LoadingScreen.gd
│├── Mob
│├── NonHUDclick.gd
│├── OvermapGrid.gd
│├── PlayerAttribute.gd
│├── PlayerShooting.gd
│├── QuestTrackerUI.gd
│├── QuestWindow.gd
│├── Runtimedata
│├── WearableSlot.gd
│├── bullet.gd
│├── container.gd
│├── crafting_recipes_manager.gd
│├── gamedata.gd
│├── general.gd
│├── hud.gd
│├── input_manager.gd
│├── item_manager.gd
│├── player.gd
│├── runtimedata.gd
│├── scene_selector.gd
│├── target_manager.gd
│└── weapon.gd
├── Shaders
│├── HideAbovePlayer.gdshader
│└── HideAbovePlayerShadow.gdshader
├── day_night.gd
├── day_night.tscn
├── documentation.tscn
├── entity_manager.gd
├── front_light.gd
├── front_light.tscn
├── hud.tscn
├── icon.svg
├── level_generation.tscn
├── override.cfg
├── project.godot
├── scene_selector.tscn
├── spot_light_3d.tscn
├── spot_light_3d_2.tscn
├── test_environment.gd
└── torso.aseprite
```

## Relevant Files
- `LevelGenerator.gd`
- `LevelManager.gd`

### Existing Files Modified
- `LevelGenerator.gd` - Wrap player references in null checks, safe chunk initialization, and player watchdog.
- `LevelManager.gd` - Guard chunk updates with player checks and shared initialization function.

### Files To Remove
- None.

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

- [ ] 1.0 Harden LevelGenerator player dependency
	- [ ] 1.1 Wrap all `player` references in `LevelGenerator.gd` and `LevelManager.gd` chunk-update logic with null checks.
	- [ ] 1.2 Move initialization logic for chunks into a function that can be safely called when `player` becomes available.
