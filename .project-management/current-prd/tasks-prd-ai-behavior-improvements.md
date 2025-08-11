## Selected maintenance goal
- 12 – AI Behavior Improvements

## Pre-Feature Development Project Tree
```
.
├── Assets
│└── Fonts
├── Defaults
│├── Blocks
│├── Mobs
│├── Player
│├── Projectiles
│├── Shaders
│└── Sprites
├── Documentation
│├── Game_design
│├── Game_development
│└── Modding
├── Mods
│├── Backrooms
│├── Core
│├── Dimensionfall
│└── Test
├── Scenes
│├── ContentManager
│├── Overmap
│└── UI
├── Scripts
│├── Components
│├── Gamedata
│├── Helper
│├── Mob
│└── Runtimedata
├── Shaders
├── Sounds
│├── Ambience
│├── Music
│└── SFX
└── Tests
    └── Unit
```

## Relevant Files

### Existing Files Modified
- `Scripts/Mob/StateMachine.gd` - Validate transitions and add fallbacks.
- `Scripts/Mob/MobFollow.gd` - Validate target references and handle missing targets.
- `Scripts/Mob/MobAttack.gd` - Add target validation and fallback to follow.
- `Scripts/Mob/MobRangedAttack.gd` - Ensure target validity and fallback.

### Files To Remove
- *(none)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

 - [x] 4.0 Harden state-machine transitions to gracefully recover from lost or invalid targets
  - [x] 4.1 Map current transitions in `StateMachine.gd` and identify failure points.
  - [x] 4.2 Add validation checks for target references before state changes.
  - [x] 4.3 Implement fallback logic when targets disappear or become unreachable.

*End of document*
