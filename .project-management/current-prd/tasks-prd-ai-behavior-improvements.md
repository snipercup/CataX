## Selected maintenance goal
- 12 – AI Behavior Improvements

## Pre-Feature Development Project Tree
```
.
├── Assets
│    └── Fonts
├── Defaults
│    ├── Blocks
│    ├── Mobs
│    ├── Player
│    ├── Projectiles
│    ├── Shaders
│    └── Sprites
├── Documentation
│    ├── Game_design
│    ├── Game_development
│    └── Modding
├── Images
│    ├── Icons
│    └── Main menu
├── Media
├── Mods
│    ├── Backrooms
│    ├── Core
│    ├── Dimensionfall
│    └── Test
├── Scenes
│    ├── ContentManager
│    ├── Overmap
│    └── UI
├── Scripts
│    ├── Components
│    ├── Gamedata
│    ├── Helper
│    ├── Mob
│    └── Runtimedata
├── Shaders
├── Sounds
│    ├── Ambience
│    ├── Music
│    └── SFX
├── Tests
│    └── Unit
└── Textures
```

## Relevant Files
- `Scripts/Mob/Detection.gd` – Handles mob detection logic.
- `Scripts/Mob/StateMachine.gd` – Defines mob state transitions.
- `Scripts/Mob/Mob.gd` – Base mob functionality.
- `Scripts/Mob/MobFollow.gd` – Current pathfinding behavior.
- `Scripts/Mob/MobIdle.gd` – Idle behavior when no target.
- `Scripts/Mob/MobAttack.gd` – Combat actions.
- `Tests/Unit/test_mob.gd` – Existing mob tests.

### Proposed New Files
- `Tests/Unit/test_state_transitions.gd` – Tests for signal-driven state changes.

### Existing Files Modified
- `Scripts/Mob/Detection.gd`
- `Scripts/Mob/Mob.gd`
- `Scripts/Mob/MobFollow.gd`
- `Scripts/Mob/StateMachine.gd`
- `Scripts/Mob/MobAttack.gd`
- `Scripts/Mob/MobIdle.gd`
- `Tests/Unit/test_mob.gd`

### Files To Remove
- _None_

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Refine mob detection for efficient and accurate target acquisition.
  - [ ] 1.1 Audit current detection logic and document shortcomings in line-of-sight, distance checks, or performance.
- [ ] 3.0 Decouple state transitions by leveraging signals and modular state definitions.
  - [ ] 3.1 Analyze existing state machine to map out hard-coded transitions and dependencies.
  - [ ] 3.2 Introduce signal-based events and modularized state classes to allow plug-and-play behavior.
  - [ ] 3.3 Refactor state transitions to respond to signals rather than direct method calls.
  - [ ] 3.4 Write unit tests verifying that state changes occur only when the correct signals are emitted.
- [ ] 5.0 Expand unit test coverage for AI detection, pathfinding, and state transitions.
  - [ ] 5.4 Add test cases confirming state transitions via signals and modular states.

*End of document*
