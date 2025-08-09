## Selected maintenance goal
- 4. Decouple Tightly Coupled Scripts & Scenes

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
- `Scripts/Helper.gd`
- `Scripts/scene_selector.gd`
- `Scripts/hud.gd`
- `LevelManager.gd`
- `Scripts/test_environment.gd`

### Proposed New Files
- `Scripts/scene_manager.gd` - Central service for scene transitions and decoupled scene control.
- `Tests/Unit/test_scene_manager.gd` - Unit tests for scene_manager.gd.

### Existing Files Modified
- `Scripts/Helper.gd` - Replace direct scene changes with SceneManager calls.
- `Scripts/scene_selector.gd` - Use SceneManager for scene navigation.
- `Scripts/hud.gd` - Replace direct menu node access with signal-driven interactions.
- `LevelManager.gd` - Subscribe to player spawn signals instead of polling groups.
- `Scripts/test_environment.gd` - Update references to use SceneManager and signals.

### Files To Remove
- *(none)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Implement `SceneManager` for centralized scene transitions
  - [ ] 1.1 Create `Scripts/scene_manager.gd` with singleton registration.
  - [ ] 1.2 Implement `change_scene(scene_path)` to preload and switch scenes.
  - [ ] 1.3 Add optional fade-in/fade-out support using an AnimationPlayer or tween.
  - [ ] 1.4 Expose a `scene_changed` signal for other scripts to connect to.
  - [ ] 1.5 Document public methods and signals in docstring comments.
- [ ] 2.0 Refactor existing scripts to use `SceneManager` instead of direct scene changes
  - [ ] 2.1 Update `Scripts/Helper.gd` to call `SceneManager.change_scene`.
  - [ ] 2.2 Replace scene paths in `Scripts/scene_selector.gd` with SceneManager usage.
  - [ ] 2.3 Adjust `Scripts/test_environment.gd` to reference SceneManager for test scene loading.
  - [ ] 2.4 Verify all updated scripts connect to `scene_changed` where needed.
- [ ] 3.0 Decouple HUD from menu nodes by using signals via `SignalBroker`
  - [ ] 3.1 Introduce a signal (e.g., `toggle_menu`) in `SignalBroker`.
  - [ ] 3.2 Modify `Scripts/hud.gd` to emit and listen for `toggle_menu` rather than manipulating menu nodes directly.
  - [ ] 3.3 Ensure menu nodes subscribe to `SignalBroker` and respond appropriately.
  - [ ] 3.4 Remove direct references from HUD to menu nodes to finalize decoupling.
- [ ] 4.0 Update `LevelManager` to receive player references via signal
  - [ ] 4.1 Define a `player_spawned` signal in the relevant player or spawner script.
  - [ ] 4.2 Modify `LevelManager.gd` to connect to `player_spawned` instead of polling groups.
  - [ ] 4.3 Store the player reference provided via signal and update internal logic accordingly.
  - [ ] 4.4 Clean up any residual group-check logic or unused variables.
- [ ] 5.0 Document decoupling patterns and add tests for `SceneManager`
  - [ ] 5.1 Create `Tests/Unit/test_scene_manager.gd` with test cases for scene changes and signaling.
  - [ ] 5.2 Write README or documentation entry describing the decoupling approach and signal usage.
  - [ ] 5.3 Update project documentation to reference new `SceneManager` and signal patterns.
  - [ ] 5.4 Ensure tests run and pass after refactoring.

*End of document*
