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
- `Documentation/Game_development/signal_conventions.md`
- `Scripts/hud.gd`
- `Scripts/LoadingScreen.gd`
- `Scripts/input_manager.gd`


### Existing Files Modified
- `Scripts/Helper/SignalBroker/signal_broker.gd` - Updated signal definitions.
- `Documentation/Game_development/signal_conventions.md` - Document broker usage and conventions.
- `Scripts/hud.gd` - Connect and disconnect signals in proper callbacks.
- `Scripts/LoadingScreen.gd` - Connect broker signals in `_ready` and disconnect in `_exit_tree`.
- `Scripts/input_manager.gd` - Use callable for inventory visibility and disconnect in `_exit_tree`.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [x] **4.0 Standardize signal usage across gameplay scripts**
  - [x] **4.1 Review signals in `signal_broker.gd` and document expected patterns**
  - [x] **4.2 Update gameplay scripts to use broker signals and typed connections**
  - [x] **4.3 Document signal conventions in `Documentation/Game_development/signal_conventions.md`**
  - [x] **4.4 Ensure connections are made in `_ready` and cleared in `_exit_tree`**

*End of document*
