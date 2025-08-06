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
- `Scripts/Mob/DetectionConfig.gd` – Configurable detection parameters.
- `Scripts/Mob/ObstacleDetector.gd` – Dynamic obstacle awareness.
- `Scripts/Mob/PathSmoother.gd` – Path smoothing utilities.
- `Tests/Unit/test_detection.gd` – Unit tests for detection edge cases.
- `Tests/Unit/test_pathfinding.gd` – Tests for dynamic obstacle avoidance and smoothing.
- `Tests/Unit/test_state_transitions.gd` – Tests for signal-driven state changes.
- `Tests/Unit/test_combat_behavior.gd` – Tests for adaptive combat responses.

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
  - [ ] 1.2 Introduce configurable detection parameters (e.g., range, angle, priority) and update code to use them.
  - [ ] 1.3 Add optimizations or caching (e.g., spatial partitioning) to reduce detection overhead.
  - [ ] 1.4 Implement new unit tests validating correct detection in edge cases (obstructions, multiple targets, range limits).
- [ ] 2.0 Enhance pathfinding to include dynamic obstacle avoidance and smoother movement.
  - [ ] 2.1 Evaluate current pathfinding algorithm; identify spots for dynamic obstacle hooks.
  - [ ] 2.2 Implement detection of moving obstacles and re-routing logic when paths become blocked.
  - [ ] 2.3 Add path smoothing (e.g., Bezier curves or corner-cutting) for more natural movement.
  - [ ] 2.4 Create test scenarios ensuring agents successfully navigate around dynamic obstacles and follow smoothed paths.
- [ ] 3.0 Decouple state transitions by leveraging signals and modular state definitions.
  - [ ] 3.1 Analyze existing state machine to map out hard-coded transitions and dependencies.
  - [ ] 3.2 Introduce signal-based events and modularized state classes to allow plug-and-play behavior.
  - [ ] 3.3 Refactor state transitions to respond to signals rather than direct method calls.
  - [ ] 3.4 Write unit tests verifying that state changes occur only when the correct signals are emitted.
- [ ] 4.0 Introduce adaptive combat behaviors that respond to mob stats and player distance.
  - [ ] 4.1 Define thresholds for mob health, attack power, and player distance that trigger behavior changes.
  - [ ] 4.2 Implement logic that adjusts tactics (e.g., retreat, ranged attack, flank) based on these thresholds.
  - [ ] 4.3 Add configuration hooks so combat behaviors can be tuned per mob type.
  - [ ] 4.4 Create test cases ensuring mobs react appropriately under various stat and distance scenarios.
- [ ] 5.0 Expand unit test coverage for AI detection, pathfinding, and state transitions.
  - [ ] 5.1 Identify untested or under-tested code paths in detection, pathfinding, and state modules.
  - [ ] 5.2 Write additional unit tests for detection, including negative and edge cases.
  - [ ] 5.3 Implement integration tests verifying pathfinding with dynamic obstacles and smoothed paths.
  - [ ] 5.4 Add test cases confirming state transitions via signals and modular states.
  - [ ] 5.5 Run coverage tools and establish target thresholds for continuous integration.

*End of document*
