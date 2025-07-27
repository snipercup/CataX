## Selected maintenance goal
- 7. **Maintainability & Performance Cleanup**

## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Assets
├── Defaults
├── Documentation
├── FeatureList.md
├── Images
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelGenerator.gd.uid
├── LevelManager.gd
├── LevelManager.gd.uid
├── Main_menu_buttons.tres
├── Media
├── Mods
├── README.md
├── Scenes
├── Scripts
├── Shaders
├── Sounds
├── Tests
├── Textures
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
### Proposed New Files
- *(none yet)*

### Existing Files Modified
- `Scripts/Mob/Mob.gd` - share meshes between mobs.

### Files To Remove
- *(none yet)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 3.0 Implement shared mob mesh caching
  - [ ] 3.1 Create global cache for mob meshes
  - [ ] 3.2 Modify `Mob.gd` to reuse cached meshes
  - [ ] 3.3 Validate memory usage improvements
- [ ] 5.0 Audit and clean unused signals
  - [ ] 5.1 Search for unused signal connections
  - [ ] 5.2 Remove obsolete signal definitions

*End of document*
