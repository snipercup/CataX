## Selected maintenance goal
- **Main gameplay logic refactoring**

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
...
├── test_environment.tscn
└── torso.aseprite
```

## Relevant Files
- `Scripts/Helper/SignalBroker/signal_broker.gd`


### Existing Files Modified
- `Scripts/Helper/SignalBroker/signal_broker.gd` - Updated signal definitions.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] **4.0 Standardize signal usage across gameplay scripts**
  - [ ] **4.1 Review signals in `signal_broker.gd` and document expected patterns**
  - [ ] **4.2 Update gameplay scripts to use broker signals and typed connections**
  - [ ] **4.3 Document signal conventions in `Documentation/Game_development/signal_conventions.md`**
  - [ ] **4.4 Ensure connections are made in `_ready` and cleared in `_exit_tree`**

*End of document*
