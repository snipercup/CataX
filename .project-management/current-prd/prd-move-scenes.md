## 1. Introduction/Overview
The project currently stores several scenes directly under the repository root. This makes it harder to locate assets and goes against recommended Godot practices for organized project structure. The goal of this feature is to move specific scene files into appropriate subfolders under `Scenes/` while updating all references so the project continues to work without errors.

## 2. Goals
- Keep the repository organized by moving scenes to logical subfolders.
- Ensure no broken references exist after relocation.
- Maintain compatibility with existing scripts and project settings.

## 3. User Stories
- *As a developer*, I want scenes grouped into logical folders so I can find and manage them quickly.
- *As a developer*, I want all references updated automatically so that moving scenes does not break the game or editor.

## 4. Functional Requirements
1. The system must move these scenes to subfolders under `Scenes/`:
   - `hud.tscn`
   - `level_generation.tscn`
   - `test_environment.tscn`
   - `day_night.tscn`
   - `documentation.tscn`
   - `front_light.tscn`
   - `spot_light_3d.tscn`
   - `spot_light_3d_2.tscn`
   - `scene_selector.tscn`
2. The system must update all references to these scenes, including:
   - `project.godot` resource paths
   - any script or scene file referencing these scenes
3. All Godot import metadata (`.tscn.import` or `.gd`) should reflect the new paths.
4. Running the GUT tests after relocation must produce the same passing results as before.

## 5. Non-Goals
- No changes to scene contents or gameplay logic.
- No adjustments to UI beyond updated paths.

## 6. Design Considerations
- Folder names should follow Godot conventions (e.g., `Scenes/UI`, `Scenes/Lighting`).
- Keep file names unchanged for clarity.

## 7. Technical Considerations
- Scripts referencing the moved scenes should use `load()` or exported `PackedScene` variables with updated paths.
- Ensure `project.godot` uses `res://` paths consistent with the new locations.

## 8. Success Metrics
- All scenes load correctly when opened in the editor and at runtime.
- GUT tests pass with no new failures.

## 9. Open Questions
- Which subfolders should each scene belong to specifically? (UI vs. Lighting, etc.)

## 10. Referenced PRD-background files
- [`.project-management/current-prd/prd-background/feature-specification.md`](../prd-background/feature-specification.md) – lists the scenes to move and the requirement to update references.
