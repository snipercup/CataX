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
- Reference *existing* project files here

### Proposed New Files
- `Scripts/Mob/Pathfinder.gd` - Handle dynamic pathfinding and obstacle avoidance.
- `Scripts/Mob/DashAction.gd` - Encapsulate dash behavior and cooldown logic.
- `/Tests/Unit/test_mob_pathfinding.gd` - Unit tests for improved pathfinding.
- `/Tests/Unit/test_mob_detection.gd` - Unit tests for multi-sense detection logic.
- `/Tests/Unit/test_mob_dash.gd` - Tests for dash mechanic and collisions.

### Existing Files Modified
- `Scripts/Mob/MobFollow.gd` - Update pathfinding algorithm for dynamic targets.
- `Scripts/target_manager.gd` - Support re-path requests and target updates.
- `Scripts/Mob/Detection.gd` - Balance line-of-sight, hearing, and sensing.
- `Scripts/Mob/StateMachine.gd` - Validate transitions and add fallbacks.
- `Scripts/Mob/Mob.gd` - Integrate dash state and movement hooks.
- `/Tests/Unit/test_mob.gd` - Adjust expectations for new behaviors.
- `/Tests/Unit/test_state_transitions.gd` - Cover recovery from lost targets.

### Files To Remove
- *(none)*

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

- [ ] 1.0 Refine mob pathfinding for dynamic targets and obstacle avoidance
  - [ ] 1.1 Review `MobFollow.gd` to document current pathfinding and collision data.
  - [ ] 1.2 Implement dynamic path recalculation when targets move or obstacles appear.
  - [ ] 1.3 Introduce tile cost modifiers for hazards and high-traffic areas.
  - [ ] 1.4 Validate pathfinding with moving-target scenarios and profile performance.
- [ ] 2.0 Improve target detection logic to balance line-of-sight, hearing, and sensing ranges
  - [ ] 2.1 Analyze `Detection.gd` to unify sight, hearing, and sensing thresholds.
  - [ ] 2.2 Implement configurable ranges and decay for each sense.
  - [ ] 2.3 Merge sense data into a unified threat score to select targets.
  - [ ] 2.4 Add debug visualizations for detection ranges.
- [ ] 3.0 Implement a reliable dash mechanic with proper trigger, cooldown, and collision handling
  - [ ] 3.1 Define dash trigger conditions and inputs for AI-controlled mobs.
  - [ ] 3.2 Create dash state with configurable speed and duration.
  - [ ] 3.3 Handle collision detection during dash and resolve impacts.
  - [ ] 3.4 Implement cooldown timer and integrate with stamina or energy systems.
- [ ] 4.0 Harden state-machine transitions to gracefully recover from lost or invalid targets
  - [ ] 4.1 Map current transitions in `StateMachine.gd` and identify failure points.
  - [ ] 4.2 Add validation checks for target references before state changes.
  - [ ] 4.3 Implement fallback states when targets disappear or become unreachable.
  - [ ] 4.4 Write logging and telemetry to diagnose rare transition errors.
- [ ] 5.0 Introduce automated tests covering mob detection, movement, and attack transitions
  - [ ] 5.1 Create unit tests for detection logic including line-of-sight, hearing, and sensing.
  - [ ] 5.2 Add integration tests simulating pathfinding with moving targets and obstacles.
  - [ ] 5.3 Write scenario tests verifying dash initiation, collision, and cooldown.
  - [ ] 5.4 Integrate new tests into CI and monitor coverage.

*End of document*
