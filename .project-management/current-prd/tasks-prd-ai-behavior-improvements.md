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
- `Scripts/Mob/MobRangedAttack.gd` – Ranged attack behavior.
- `Scripts/Mob/MobTerminate.gd` – Final state cleanup.
- `Scripts/Mob/state.gd` – Base class for mob states.
- `Tests/Unit/test_mob.gd` – Existing mob tests.
- `Tests/Unit/test_state_transitions.gd` – Tests for signal-driven state changes.
- `Documentation/Game_development/Mob_detection_audit.md` – Assessment of current detection logic and shortcomings.

### Proposed New Files
- _None_

### Existing Files Modified
- `Scripts/Mob/Detection.gd`
- `Scripts/Mob/Mob.gd`
- `Scripts/Mob/MobFollow.gd`
- `Scripts/Mob/StateMachine.gd`
- `Scripts/Mob/MobAttack.gd`
- `Scripts/Mob/MobIdle.gd`
- `Scripts/Mob/MobRangedAttack.gd`
- `Scripts/Mob/MobTerminate.gd`
- `Scripts/Mob/state.gd`
- `Tests/Unit/test_mob.gd`
- `Tests/Unit/test_state_transitions.gd`

### Files To Remove
- _None_

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [x] 1.0 Refine mob detection for efficient and accurate target acquisition.
  - [x] 1.1 Audit current detection logic and document shortcomings in line-of-sight, distance checks, or performance.
- [ ] 3.0 Decouple state transitions by leveraging signals and modular state definitions.
  - [x] 3.1 Analyze existing state machine to map out hard-coded transitions and dependencies.
    - StateMachine instantiates `MobIdle`, `MobFollow`, `MobTerminate`, and conditionally `MobAttack` or `MobRangedAttack`.
    - `MobIdle` → `mobfollow` when target spotted, `mobterminate` when terminated.
    - `MobFollow` → `mobterminate` if terminated, `mobrangedattack` or `mobattack` when target in range, `mobidle` when target reached.
    - `MobAttack` → `mobfollow` when target lost or out of range, `mobterminate` if terminated.
    - `MobRangedAttack` → `mobfollow` if out of range or no line-of-sight, `mobterminate` if terminated.
    - `MobTerminate` is final with no outbound transitions.
  - [x] 3.2 Introduce signal-based events and modularized state classes to allow plug-and-play behavior.
  - [ ] 3.3 Refactor state transitions to respond to signals rather than direct method calls.
  - [x] 3.4 Write unit tests verifying that state changes occur only when the correct signals are emitted.
- [ ] 5.0 Expand unit test coverage for AI detection, pathfinding, and state transitions.
  - [x] 5.4 Add test cases confirming state transitions via signals and modular states.

*End of document*
