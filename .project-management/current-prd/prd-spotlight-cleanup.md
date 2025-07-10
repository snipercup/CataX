## 1. Introduction/Overview
This feature will consolidate the two existing spotlight scenes (`spot_light_3d.tscn` and `spot_light_3d_2.tscn`) into a single canonical scene. The goal is to remove redundancy and ensure the player's spotlight uses consistent, well-tuned parameters.

## 2. Goals
- Reduce project clutter by keeping only one spotlight scene.
- Adopt the parameters currently used by the player's spotlight.
- Ensure all references across the project point to the canonical spotlight scene.

## 3. User Stories
- **As a developer**, I want a single spotlight scene with clear naming so that I can easily reuse it in multiple game contexts.
- **As a player**, I want the in-game spotlight to behave consistently so that lighting works as expected during gameplay.

## 4. Functional Requirements
1. Compare `spot_light_3d.tscn` and `spot_light_3d_2.tscn` and determine which has the better default settings.
2. Create a single canonical spotlight scene using the better defaults and applying the parameters from the player's current spotlight setup.
3. Rename the retained spotlight scene if it improves clarity.
4. Update `Scenes/player.tscn` and any other scenes or scripts referencing the old spotlight scenes to use the canonical scene.
5. Remove the redundant spotlight scene from the repository.
6. Verify no remaining references exist to the removed scene.

## 5. Non-Goals (Out of Scope)
- Adding new spotlight features or visual effects.
- Refactoring unrelated lighting or scene code.

## 6. Design Considerations (Optional)
- The canonical scene name should clearly indicate it is the primary 3D spotlight (e.g., `spot_light_3d_main.tscn`).
- Maintain consistent Godot 4.4 conventions and GDScript 4 syntax within scripts.

## 7. Technical Considerations (Optional)
- Ensure compatibility with existing player scripts and scenes after the change.
- Verify removal of the redundant scene does not break automated imports.

## 8. Success Metrics
- Only one spotlight scene exists in the repository.
- All references to the old spotlight scenes are updated and tests pass.

## 9. Open Questions
- Are any other scenes or scripts beyond the player scene referencing the old spotlight scenes?

## 10. Referenced PRD-background files
- `.project-management/current-prd/prd-background/feature-specification.md`: Describes the requirement to keep one canonical spotlight scene and remove the redundant file.
