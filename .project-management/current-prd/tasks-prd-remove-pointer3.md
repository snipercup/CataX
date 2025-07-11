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
- `project.godot` - references `pointer3.png` as the custom cursor.
- `Textures/pointer3.png` - cursor image referenced by the project.
- `Textures/pointer3.png.import` - import configuration for `pointer3.png`.

### Proposed New Files
- *(none)*

### Existing Files Modified
- `project.godot` - update or remove custom cursor reference.
- `Textures/pointer3.png` - delete if no longer used.
- `Textures/pointer3.png.import` - delete if removing the image.

### Notes
- Non-Goals: fallback pointer logic is out of scope.
- Success criteria: `godot --headless --import` runs without errors.

## Tasks
- [ ] **1.0 Audit pointer3.png usage**
  - [ ] 1.1 Search repository for references to `pointer3.png`.
  - [ ] 1.2 List files referencing it, starting with `project.godot`.
  - [ ] 1.3 Review `.project-management/current-prd/prd-background/feature-specification.md` for context.
- [ ] **2.0 Decide on cursor strategy**
  - [ ] 2.1 Determine if `pointer3.png` is required for gameplay.
  - [ ] 2.2 Choose between restoring the asset or switching to `pointer2.png` or the default cursor.
  - [ ] 2.3 Record the chosen approach.
- [ ] **3.0 Implement chosen solution**
  - [ ] 3.1 If removing: delete `Textures/pointer3.png` and its `.import` file and update `project.godot` accordingly.
  - [ ] 3.2 If restoring: open the project in Godot to reimport the image so `.godot/imported/*pointer3*.ctex` is created.
  - [ ] 3.3 Ensure no invalid references remain in the repository.
- [ ] **4.0 Verify import process**
  - [ ] 4.1 Run `godot --headless --import`.
  - [ ] 4.2 Confirm there are no missing resource errors.
- [ ] **5.0 Update documentation and commit**
  - [ ] 5.1 Document the decision and steps in `Documentation` or `README.md`.
  - [ ] 5.2 Commit all changes to Git.
*End of document*
