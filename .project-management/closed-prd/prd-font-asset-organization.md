## 1. Introduction/Overview
The project currently stores font files in the root directory. To keep assets organized, a dedicated `Assets/Fonts/` directory should be created. The three font files (`Apple ][.ttf`, `Roboto-Bold.ttf`, and `Glitch.ttf`) along with their `.import` metadata will be moved into this directory. All scenes and resources referencing these fonts must be updated to use the new paths.

## 2. Goals
- Maintain a clean and structured project hierarchy by relocating fonts to `Assets/Fonts/`.
- Ensure all existing scenes and resources continue to load fonts correctly after relocation.

## 3. User Stories
- **As a developer**, I want font assets grouped in a dedicated folder so that project maintenance is straightforward.
- **As a contributor**, I expect scenes to reference fonts using consistent paths, avoiding broken links.

## 4. Functional Requirements
1. Create a new folder `Assets/Fonts/` at the project root.
2. Move `Apple ][.ttf`, `Roboto-Bold.ttf`, `Glitch.ttf` and their corresponding `.import` files into `Assets/Fonts/`.
3. Update all font references to use the new paths:
   - `hud.tscn`
   - `Scenes/InventoryWindow.tscn`
   - `Scenes/UI/CraftingMenu.tscn`
   - `scene_selector.tscn`
   - `Main_menu_buttons.tres`
4. Verify no other files reference the old font paths.
5. Preserve the original file names during relocation.

## 5. Non-Goals (Out of Scope)
- Adding or removing font files beyond the three specified.
- Modifying game logic or UI layout.
- Updating project configuration files.

## 6. Design Considerations
- Keep font names unchanged to avoid breaking UID links defined in Godot scenes.
- Ensure `.import` files remain beside their font counterparts so Godot re-imports correctly.

## 7. Technical Considerations
- After moving fonts, run Godot's import step (`godot --headless --import`) to regenerate cached resources.
- Use search tools (e.g., `grep`) to confirm all scenes reference the new directory.

## 8. Success Metrics
- Project builds successfully with all scenes loading their fonts from `Assets/Fonts/`.
- No broken references detected when running the game or importing assets.

## 9. Open Questions
- None identified from current information.

## 10. Referenced PRD-background files
- `.project-management/current-prd/prd-background/feature-specification.md` – describes the requirement to relocate fonts and update references.
