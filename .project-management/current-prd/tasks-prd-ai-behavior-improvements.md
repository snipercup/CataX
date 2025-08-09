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

### Files To Remove
- *(none)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

- [ ] 4.0 Harden state-machine transitions to gracefully recover from lost or invalid targets
  - [ ] 4.1 Map current transitions in `StateMachine.gd` and identify failure points.
  - [ ] 4.2 Add validation checks for target references before state changes.
  - [ ] 4.3 Implement fallback logic when targets disappear or become unreachable.

*End of document*
