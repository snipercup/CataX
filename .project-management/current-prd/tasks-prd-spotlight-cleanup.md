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
```
## Relevant Files
- `spot_light_3d_main.tscn` - Canonical spotlight scene using player's settings.
- `front_light.tscn` - Player spotlight parameters.
- `Scenes/player.tscn` - References canonical spotlight scene.
### Removed Files
- `spot_light_3d.tscn` - Old spotlight candidate.
- `spot_light_3d_2.tscn` - Old spotlight candidate.
### Proposed New Files
- `spot_light_3d_main.tscn` - Canonical spotlight scene using player's settings.
- `/Tests/Unit/test_spotlight_scene.gd` - Unit tests for canonical spotlight.
### Existing Files Modified
- `Scenes/player.tscn` - Replace old spotlight references.
### Notes
- See `.project-management/current-prd/prd-background/feature-specification.md` for consolidation details.

## Tasks
- [x] 1.0 Evaluate `spot_light_3d.tscn` and `spot_light_3d_2.tscn` to select the best default settings.
- [x] 2.0 Create canonical spotlight scene `spot_light_3d_main.tscn` using player's parameters from `front_light.tscn`.
- [x] 3.0 Update `Scenes/player.tscn` and other scenes/scripts to use `spot_light_3d_main.tscn`.
- [x] 4.0 Remove the redundant spotlight scene from the repository.
- [x] 5.0 Verify no references to the removed scene remain and run unit tests.
*End of document*
