## Selected content goal
- 2: Add New Items

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
- `Mods/Dimensionfall/Items/Items.json`
- `Mods/Dimensionfall/Items/references.json`
- `Scripts/item_manager.gd`
- `Scripts/InventoryWindow.gd`
- `Scenes/UI/InventoryWindow.tscn`

### Proposed New Files
- None

### Existing Files Modified
- `Mods/Dimensionfall/Items/Items.json` - add medical and survival categories and ten new items
- `Mods/Dimensionfall/Items/references.json` - update references for new items and categories
- `Scripts/item_manager.gd` - register new item categories
- `Scripts/InventoryWindow.gd` - handle filtering for new categories
- `Scenes/UI/InventoryWindow.tscn` - expose medical and survival filters in inventory UI

## Tasks

- [ ] 1.0 Introduce “medical” and “survival” item categories alongside existing “urban,” “nature,” and “industrial.”
- [ ] 1.1 Review existing item category definitions, enums, and data files to locate where categories are registered.
- [ ] 1.2 Add “medical” and “survival” entries to the category enumeration or equivalent configuration.
- [ ] 1.3 Update any look-ups, data loaders, and UI elements (inventory filters, category lists) to include the new categories.
- [ ] 1.4 Adjust documentation or localization files that reference item categories.
- [ ] 1.5 Smoke-test to confirm items can be assigned to the new categories without errors.
- [ ] 2.0 Design two new items for each category (urban, nature, industrial, medical, survival)
- [ ] 2.1 Urban: draft two distinct item concepts with names, descriptions, basic stats (weight, value, durability), and urban-specific properties.
- [ ] 2.2 Nature: draft two items with the above base stats plus nature-specific properties.
- [ ] 2.3 Industrial: draft two items with base stats plus industrial-specific properties.
- [ ] 2.4 Medical: draft two medical items, ensuring relevant properties (e.g., healing amount, dosage).
- [ ] 2.5 Survival: draft two survival items with properties such as durability or environmental resistance.
- [ ] 2.6 Assign the placeholder sprite `9mm.png` to each item.
- [ ] 2.7 Document all ten items in the appropriate design or configuration files.
- [ ] 2.8 Verify each item loads correctly in the game data and appears under its category.

*End of document*
