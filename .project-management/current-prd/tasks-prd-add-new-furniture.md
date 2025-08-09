## Selected content goal
- 3 - Add New Furniture

## Pre-Feature Development Project Tree
```
.
Assets
Assets/Fonts
Defaults
Defaults/Blocks
Defaults/Mobs
Defaults/Player
Defaults/Projectiles
Defaults/Shaders
Defaults/Sprites
Documentation
Documentation/Game_design
Documentation/Game_development
Documentation/Modding
Images
Images/Icons
Images/Main menu
Media
Mods
Mods/Backrooms
Mods/Core
Mods/Dimensionfall
Mods/Test
Scenes
Scenes/ContentManager
Scenes/Overmap
Scenes/UI
Scripts
Scripts/Components
Scripts/Gamedata
Scripts/Helper
Scripts/Mob
Scripts/Runtimedata
Shaders
Sounds
Sounds/Ambience
Sounds/Music
Sounds/SFX
Tests
Tests/Unit
Textures
```

## Relevant Files
- Existing project files that will be touched during implementation.

### Existing Files Modified
- `Mods/Dimensionfall/Furniture/Furniture.json` - Add ten new furniture definitions spanning five categories.

### Files To Remove
- None.

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

- [x] 1.0 Establish two new furniture categories
- [x] 1.1 Brainstorm and select two complementary category names that fit alongside Urban, Nature, and Industrial.
- [x] 2.0 Draft ten new furniture definitions
- [x] 2.1 For each of the five categories (Urban, Nature, Industrial, and the two new ones), outline two distinct furniture items.
- [x] 2.2 Assign a unique `id` to every furniture definition.
- [x] 2.3 Provide each furniture definition with a descriptive `name`.
- [x] 2.4 Specify the `moveable` field (true/false) for each definition.
- [x] 2.5 Confirm the definitions adhere to the expected data format and integrate properly with the existing furniture catalog.

*End of document*
