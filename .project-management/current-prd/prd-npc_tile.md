# NPC Tile Brushcomposer Feature

## Overview
Add a new `npc_tile` to the map editor brush composer to mark coordinates where an NPC can spawn. This tile uses the same placeholder icon as the existing `null_tile` and integrates with existing map data.

## Requirements
1. **Brush Composer Button** – Place a button for `npc_tile` next to the `null_tile` button in `mapeditor_brushcomposer.tscn`. Use `res://Scenes/ContentManager/Mapeditor/Images/nulltile_32.png` as the icon.
2. **Painting Rules**
   - `npc_tile` can coexist with regular tiles but cannot share a coordinate with `mob`, `mobgroup`, `furniture`, or `itemgroup` entries. Painting `npc_tile` over one of these removes the previous entity.
   - Painting a `mob`, `mobgroup`, `furniture`, or `itemgroup` over an existing `npc_tile` removes the `npc_tile`.
   - Only one `npc_tile` is allowed per coordinate, though there is no overall limit on the map.
3. **Map Data Storage** – Store `npc_tile` coordinates within each map tile’s data structure (no separate list). Save this through `DMap`/`DMaps` when exporting the map.
4. **Processing Behavior** – During map load, `map_manager.gd` prints a statement for each processed `npc_tile` and then removes it from the map data.

## Acceptance Criteria
- The npc_tile button appears beside the null_tile button in the brush composer UI.
- Users can paint npc_tile positions that follow the painting rules above.
- Map JSON embeds npc_tile data with other tile attributes and saves correctly through DMap/DMaps.
- map_manager prints a message when npc_tile data is processed, and npc_tile entries do not persist after processing.
