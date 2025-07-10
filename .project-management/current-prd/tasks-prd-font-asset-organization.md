## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Apple ][.ttf
├── Apple ][.ttf.import
├── Defaults
│   ├── Blocks
│   ├── Mobs
│   ├── Player
│   ├── Projectiles
│   ├── Shaders
│   └── Sprites
├── Documentation
│   ├── Game_design
│   ├── Game_development
│   └── Modding
├── FeatureList.md
├── Glitch.ttf
├── Glitch.ttf.import
├── Images
│   ├── Icons
```

## Relevant Files
- `Apple ][.ttf` and `Apple ][.ttf.import`
- `Roboto-Bold.ttf` and `Roboto-Bold.ttf.import`
- `Glitch.ttf` and `Glitch.ttf.import`
- `hud.tscn`
- `Scenes/InventoryWindow.tscn`
- `Scenes/UI/CraftingMenu.tscn`
- `scene_selector.tscn`
- `Main_menu_buttons.tres`

### Proposed New Files
- None (only relocating existing assets)

### Existing Files Modified
- `Apple ][.ttf` and `.import` - moved to `Assets/Fonts/`
- `Roboto-Bold.ttf` and `.import` - moved to `Assets/Fonts/`
- `Glitch.ttf` and `.import` - moved to `Assets/Fonts/`
- Scenes referencing these fonts (listed above) updated to new paths

### Notes
- Preserve original file names to avoid breaking references.
- Keep `.import` files beside their fonts so Godot re-imports correctly.
- After relocation, run `godot --headless --import` to rebuild resources.

## Tasks
- [x] 1.0 Create `Assets/Fonts/` directory at project root
- [x] 2.0 Move existing font files and their `.import` metadata into the new folder
- [x] 3.0 Update font references in all listed scenes and resources
- [x] 4.0 Search the project to ensure no old font paths remain
- [x] 5.0 Re-import assets with Godot to verify successful relocation
*End of document*
