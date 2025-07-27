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
- `LevelGenerator.gd` - streamline chunk load/unload logic.
- `Chunk.gd` - optimize collider generation loops.
- `Scripts/item_manager.gd` - refactor inventory calculations.
- `Scripts/Mob/Mob.gd` - share meshes between mobs.
- `Scripts/input_manager.gd` - centralize player input handling.

### Files To Remove
- *(none yet)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Optimize world streaming performance
  - [ ] 1.1 Profile chunk loading/unloading performance
  - [ ] 1.2 Streamline memory use in `LevelGenerator.gd`
  - [ ] 1.3 Add tests for chunk streaming
- [ ] 2.0 Refactor inventory management for efficiency
  - [ ] 2.1 Review `item_manager.gd` loops
  - [ ] 2.2 Extract duplicate calculations into helper functions
  - [ ] 2.3 Write unit tests for inventory operations
- [ ] 3.0 Implement shared mob mesh caching
  - [ ] 3.1 Create global cache for mob meshes
  - [ ] 3.2 Modify `Mob.gd` to reuse cached meshes
  - [ ] 3.3 Validate memory usage improvements
- [ ] 4.0 Centralize input processing logic
  - [ ] 4.1 Move scattered input events to `input_manager.gd`
  - [ ] 4.2 Update scenes to use centralized signals
  - [ ] 4.3 Add tests for player actions
- [ ] 5.0 Audit and clean unused signals
  - [ ] 5.1 Search for unused signal connections
  - [ ] 5.2 Remove obsolete signal definitions
  - [ ] 5.3 Document remaining signals

*End of document*
