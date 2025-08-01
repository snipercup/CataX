## Selected maintenance goal
- 15 - Add new items

## Pre-Feature Development Project Tree
```
.
├── AGENTS.md
├── Assets
│   └── Fonts
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
├── Images
│   ├── Icons
│   └── Main menu
├── ItemProtosets.tres
├── LICENSE
├── LevelGenerator.gd
├── LevelGenerator.gd.uid
├── LevelManager.gd
├── LevelManager.gd.uid
├── Main_menu_buttons.tres
├── Media
│   ├── Catax_basic.png
│   ├── Catax_basic.png.import
│   ├── Catax_basic_zoomed_out.png
│   ├── Catax_basic_zoomed_out.png.import
│   ├── Catax_content_editor.png
│   ├── Catax_content_editor.png.import
│   ├── Catax_crafting_editor.png
│   ├── Catax_crafting_editor.png.import
│   ├── Catax_furniture_editor.png
│   ├── Catax_furniture_editor.png.import
│   ├── Catax_item_editor.png
│   ├── Catax_item_editor.png.import
│   ├── Catax_itemgroup_editor.png
```

## Relevant Files
- Mods/Dimensionfall/Items/Items.json
- Mods/Dimensionfall/Items/references.json

### Proposed New Files
- Documentation/Modding/new_item_categories.md - Document the new categories and items.

### Existing Files Modified
- Mods/Dimensionfall/Items/Items.json - Add definitions for new items.
- Mods/Dimensionfall/Items/references.json - Update references for new items.

### Notes
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks
- [ ] 1.0 Audit current item data
  - [ ] 1.1 Review `Items.json` structure and required fields
  - [ ] 1.2 Verify existing categories and item references
  - [ ] 1.3 Analyze `references.json` for dependency links
- [ ] 2.0 Extend item category list
  - [ ] 2.1 Decide two new categories fitting the game setting
  - [ ] 2.2 Add categories to documentation and any enum lists
- [ ] 3.0 Design ten new item concepts
  - [ ] 3.1 Draft two items per category with descriptions and properties
  - [ ] 3.2 Create sprites or placeholders for each item
- [ ] 4.0 Implement JSON updates
  - [ ] 4.1 Insert new item definitions into `Items.json`
  - [ ] 4.2 Update `references.json` with item entries
  - [ ] 4.3 Validate JSON formatting and schema
- [ ] 5.0 Validate and document
  - [ ] 5.1 Run unit tests to ensure item loading works
  - [ ] 5.2 Document categories and items in `/Documentation`
  - [ ] 5.3 Check in-game references for new items
