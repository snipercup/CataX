## Pre-Feature Development Project Tree
```
.
./Assets
./Assets/Fonts
./Defaults
./Defaults/Blocks
./Defaults/Mobs
./Defaults/Player
./Defaults/Projectiles
./Defaults/Shaders
./Defaults/Sprites
./Documentation
./Documentation/Game_design
./Documentation/Game_development
./Documentation/Modding
./Images
./Images/Icons
./Images/Main menu
./Media
./Mods
./Mods/Backrooms
./Mods/Core
./Mods/Dimensionfall
./Mods/Test
./Scenes
./Scenes/ContentManager
./Scenes/Overmap
./Scenes/UI
./Scripts
./Scripts/Components
./Scripts/Gamedata
./Scripts/Helper
./Scripts/Mob
./Scripts/Runtimedata
./Shaders
./Sounds
./Sounds/Ambience
./Sounds/Music
./Sounds/SFX
./Tests
./Tests/Unit
./Textures
```

## Relevant Files
- `.project-management/current-prd/prd-move-scenes.md`
- `.project-management/current-prd/prd-background/feature-specification.md`

### Proposed New Files
*(none at this stage)*

### Existing Files Modified
- `project.godot`
- `hud.tscn`
- `level_generation.tscn`
- `test_environment.tscn`
- `day_night.tscn`
- `documentation.tscn`
- `front_light.tscn`
- `spot_light_3d.tscn`
- `spot_light_3d_2.tscn`
- `scene_selector.tscn`

### Notes
- Scenes will be moved to subfolders within `Scenes/` such as `Scenes/UI` or `Scenes/Lighting`.
- Use Godot's editor or scripting tools to update references and ensure metadata is regenerated.

## Tasks
- [ ] 1.0 Review `.project-management/current-prd/prd-move-scenes.md` and the list of scenes in `.project-management/current-prd/prd-background/feature-specification.md` to confirm which files need relocation
- [ ] 2.0 Plan destination folders under `Scenes/` (e.g., `Scenes/UI`, `Scenes/Lighting`) for each scene
- [ ] 3.0 Move the scenes to the planned folders while preserving file names
- [ ] 4.0 Update `project.godot` and all scene or script references to use the new paths
- [ ] 5.0 Reimport the moved scenes so `.import` metadata matches the new locations
- [ ] 6.0 Run the GUT tests to ensure no regressions
*End of document*
