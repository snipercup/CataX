## Selected maintenance goal
- Code Refactoring & Simplification

## Pre-Feature Development Project Tree
```
.
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
├── Images
│   ├── Icons
│   └── Main menu
├── Media
├── Mods
│   ├── Backrooms
│   ├── Core
│   ├── Dimensionfall
│   └── Test
├── Scenes
│   ├── ContentManager
│   ├── Overmap
│   └── UI
├── Scripts
│   ├── Components
│   ├── Gamedata
│   ├── Helper
│   ├── Mob
│   └── Runtimedata
├── Shaders
├── Sounds
│   ├── Ambience
│   ├── Music
│   └── SFX
├── Tests
│   └── Unit
└── Textures

41 directories

## Relevant Files

### Existing Files Modified
- `Scripts/BuildManager.gd` - Separate ghost updates from build logic.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Implement centralized Logger utility
  - [ ] 1.1 Create `Scripts/Helper/logger.gd` with info, warning and error methods
  - [ ] 1.2 Replace `print` statements in core scripts with Logger calls
  - [ ] 1.3 Add unit tests verifying log output
