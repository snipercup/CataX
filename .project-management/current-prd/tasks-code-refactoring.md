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
- Reference *existing* project files here

### Proposed New Files
- `Scripts/Helper/logger.gd` - Shared logging utility replacing scattered `print` and `print_debug` calls.
- `/Tests/Unit/test_logger.gd` - Unit tests for `logger.gd`.

### Existing Files Modified
- `Scripts/BuildManager.gd` - Separate ghost updates from build logic.
- `Scripts/hud.gd` - Extract input toggles and progress bar logic into smaller methods.
- `Scripts/player.gd` - Modularize movement and attribute initialization sections.
- `Scenes/ContentManager/Scripts/addremovemods.gd` - Split large functions and centralize validation logic.

### Files To Remove
- None

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Implement centralized Logger utility
  - [ ] 1.1 Create `Scripts/Helper/logger.gd` with info, warning and error methods
  - [ ] 1.2 Replace `print` statements in core scripts with Logger calls
  - [ ] 1.3 Add unit tests verifying log output
- [ ] 2.0 Refactor `BuildManager.gd`
  - [ ] 2.1 Move ghost update logic into `update_ghost()` method
  - [ ] 2.2 Invoke `update_ghost()` from build functions
  - [ ] 2.3 Add tests for ghost placement
- [ ] 3.0 Simplify `hud.gd` structure
  - [ ] 3.1 Extract input toggle handling to a separate method
  - [ ] 3.2 Move progress bar updates into helper method
  - [ ] 3.3 Use signals to decouple HUD from other scripts
- [ ] 4.0 Break down `player.gd`
  - [ ] 4.1 Create `Scripts/PlayerMovement.gd` for movement logic
  - [ ] 4.2 Move attribute initialization to `Scripts/PlayerAttributes.gd`
  - [ ] 4.3 Use exported constants for movement parameters
- [ ] 5.0 Clean up mod management script
  - [ ] 5.1 Split functions in `addremovemods.gd` for readability
  - [ ] 5.2 Centralize mod path validation logic
  - [ ] 5.3 Add error handling and unit tests
