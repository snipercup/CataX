## Selected maintenance goal
- 4 – Decouple Tightly Coupled Scripts & Scenes

## Pre-Feature Development Project Tree
```
.
Assets/
  Fonts/
Defaults/
  Blocks/
  Mobs/
  Player/
  Projectiles/
  Shaders/
  Sprites/
Documentation/
  Game_design/
  Game_development/
  Modding/
Images/
  Icons/
  Main menu/
Media/
Mods/
  Backrooms/
  Core/
  Dimensionfall/
  Test/
Scenes/
  ContentManager/
  Overmap/
  UI/
Scripts/
  Components/
  Gamedata/
  Helper/
  Mob/
  Runtimedata/
Shaders/
Sounds/
  Ambience/
  Music/
  SFX/
Tests/
  Unit/
Textures/
```

## Relevant Files
- `Scripts/hud.gd` – HUD script with direct node references and input handling.


### Existing Files Modified
- `Scripts/hud.gd`

### Files To Remove
- None identified.

### Notes
- Unit tests should be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Refactor HUD interactions to use signals instead of direct node paths.
  - [ ] 1.1 Replace direct node path references in `Scripts/hud.gd` with signal-based communication.
  - [ ] 1.2 Emit player state signals (e.g., health, inventory) from the gameplay scripts to the HUD via the signal broker.
  - [ ] 1.3 Update existing HUD handlers to connect and react to these signals instead of calling nodes directly.
  - [ ] 1.4 Remove unused or redundant node references once signal-based wiring is complete.

*End of document*
