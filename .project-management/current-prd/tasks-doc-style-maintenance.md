## Selected maintenance goal
Documentation & Style Consistency

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
├── Images
│   ├── Icons
│   └── Main menu
├── ItemProtosets.tres
...
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
- `README.md` - Central documentation that will link to style guidelines
- `Documentation/Game_design/Game_architecture.md` - Existing architecture doc with typos
- `Documentation/Game_development/Getting_started.md` - Contains introductory instructions
- `Documentation/Game_development/Working_with_codex.md` - Details Codex workflow
- `Scripts/general.gd` - Example script with inconsistent indentation
- `Scripts/Helper.gd` - Contains constants that need naming cleanup
- `Scripts/Helper/json_helper.gd` - Helper with mixed spaces and tabs

### Proposed New Files
- `CONTRIBUTING.md` - Describes coding standards and documentation style.
- `.editorconfig` - Configure indentation and whitespace settings.

### Existing Files Modified
- `Documentation/Game_design/Game_architecture.md` - Fix typos like "it's" vs "its".
- `Documentation/Game_development/Getting_started.md` - Grammar corrections.
- `Documentation/Game_development/Working_with_codex.md` - Fix "managment" typo.
- `README.md` - Update references to documentation guidelines.
- `Scripts/general.gd` - Convert indentation to tabs.
- `Scripts/Helper.gd` - Normalize constant names and use tabs.
- `Scripts/Helper/json_helper.gd` - Apply consistent indentation.

### Files To Remove
- _None_

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Fix documentation typos
  - [ ] 1.1 Review documentation files for spelling and grammar issues
  - [ ] 1.2 Correct "managment" to "management" in Working_with_codex.md
  - [ ] 1.3 Proofread README for punctuation and clarity
- [ ] 2.0 Standardize indentation across scripts
  - [ ] 2.1 Scan scripts for mixed spaces and tabs
  - [ ] 2.2 Apply gdformat to affected scripts
  - [ ] 2.3 Verify indentation uses tabs only
- [ ] 3.0 Normalize variable naming conventions
  - [ ] 3.1 Identify variables with inconsistent casing
  - [ ] 3.2 Rename variables using preferred style
  - [ ] 3.3 Update references in other scripts
- [ ] 4.0 Add style guideline documents
  - [ ] 4.1 Create CONTRIBUTING.md with documentation standards
  - [ ] 4.2 Add .editorconfig specifying tab indentation
  - [ ] 4.3 Document gdformat usage in CONTRIBUTING.md
- [ ] 5.0 Update README to reference style guidelines
  - [ ] 5.1 Link to CONTRIBUTING.md from README
  - [ ] 5.2 Describe formatting and lint commands in README

*End of document*
