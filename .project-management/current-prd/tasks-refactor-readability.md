## Selected maintenance goal
- **Refactor for Readability & Maintainability**

## Pre-Feature Development Project Tree
```bash
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
```

## Relevant Files
- `Scenes/Overmap/Scripts/Overmap.gd`
- `Scripts/BuildManager.gd`
- `Scripts/general.gd`
- `Scripts/Helper.gd`
- `Tests/Unit/test_item_manager.gd`

### Proposed New Files
- `Documentation/Game_design/Overmap_refactor_notes.md` - Notes on updated Overmap architecture.
- `Tests/Unit/test_helper_functions.gd` - Unit tests for new helper methods.

### Existing Files Modified
- `Scenes/Overmap/Scripts/Overmap.gd` - Split into smaller functions and add docstrings.
- `Scripts/BuildManager.gd` - Clarify variable names and add comments.
- `Scripts/general.gd` - Document utility functions.
- `Scripts/Helper.gd` - Standardize naming and add explanations.
- `Documentation/Game_design/Game_architecture.md` - Update Overmap section.

### Files To Remove
- *(none)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] **1.0 Refactor `Overmap.gd` structure**
  - [ ] 1.1 Break large methods into helpers (e.g. `_create_chunk`, `_redraw_chunk`).
  - [ ] 1.2 Use typed arrays/dictionaries for `grid_chunks` and `chunk_pool`.
  - [ ] 1.3 Add docstrings and ensure tabs for indentation.

- [ ] **2.0 Improve `BuildManager.gd` readability**
  - [ ] 2.1 Document all public functions with brief comments.
  - [ ] 2.2 Replace magic numbers with named constants.
  - [ ] 2.3 Consolidate duplicate debug logging.

- [ ] **3.0 Standardize helper script naming and comments**
  - [ ] 3.1 Rename inconsistent variables for clarity.
  - [ ] 3.2 Add comments explaining each helper's responsibility.

- [ ] **4.0 Increase test coverage for helper functions**
  - [ ] 4.1 Add `Tests/Unit/test_helper_functions.gd` testing `General.string_to_vector2` and `Helper.raycast`.
  - [ ] 4.2 Run GUT tests to verify new cases pass.

- [ ] **5.0 Document the refactored Overmap system**
  - [ ] 5.1 Summarize new Overmap flow in `Game_architecture.md`.
  - [ ] 5.2 Provide additional notes in `Overmap_refactor_notes.md`.

*End of document*
