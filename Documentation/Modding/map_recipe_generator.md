# Recipe-driven map generator

`Tools/map_generator.py` converts a compact JSON recipe into a complete Dimensionfall map JSON file. Dimensionfall maps have fixed dimensions of 32 x 32 tiles and 21 possible logical levels from `z: -10` through `z: 10`. Every populated level has exactly 1024 entries; unused levels remain `[]`.

## Usage

Run from the repository root:

```sh
python3 Tools/map_generator.py \
  Tools/examples/map_recipe.json \
  /tmp/generated_meadow_prototype.json
python3 Tools/map_validator.py /tmp/generated_meadow_prototype.json
```

The output filename must be `<id>.json`, matching the map loader's filename-derived ID. Existing output is protected. Pass `--overwrite` only when replacement is intended. Use `--tiles PATH` to validate tile IDs against a tile database other than `Mods/Dimensionfall/Tiles/Tiles.json`. Furniture operations validate against `Furniture/Furniture.json` beside the selected `Tiles` directory by default; use `--furniture PATH` when that database is elsewhere.

For batch generation of deterministic seed variants and instructions for inspecting them in Godot's content editor, see [`map_example_generation.md`](map_example_generation.md).

## Recipe format

The root must be a JSON object with these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Map ID using only letters, numbers, `_`, and `-`. |
| `name` | non-empty string | Display name. |
| `description` | non-empty string | Map description. |
| `seed` | integer | Fixed seed used by tile and furniture palettes, random rotations, scatter, and pattern cells. Recipe input only; the map format does not store it. |
| `base_tile` | tile object | Legacy-mode tile initially placed in every cell at `z: 0`. Required unless `levels` is used. |
| `palette` | object | Named weighted tile sets that tile objects can reference. Optional; defaults to `{}`. |
| `furniture_palette` | object | Named weighted furniture sets used by `furniture_scatter`. Optional; defaults to `{}`. |
| `areas` | array | Strict runtime area definitions referenced by `area_rectangle`. Optional; defaults to `[]`. |
| `patterns` | object | Named arrays of relative tile placements used by `pattern` operations. Optional; defaults to `{}`. |
| `regions` | array | Legacy filled rectangles. Optional; defaults to `[]`. |
| `operations` | array | Ordered placement operations. Optional; defaults to `[]`. |
| `levels` | non-empty array | Explicit grouped level definitions. Cannot be combined with root `base_tile`, `regions`, or `operations`. |

A recipe does not define map dimensions: all generated maps are 32 x 32. Top-down `[x, y]` coordinates start at the top-left. Logical `z` is vertical elevation, not a third element in `[x, y]`. Every shape must fit entirely within the map; operations are never silently clipped.

A tile object has exactly one of:

- `id`: a raw tile ID from the selected `Tiles.json`; or
- `palette`: the name of a root-level palette.

It may also include an optional `rotation` when using `id`. Rotation is `0`, `90`, `180`, `270`, or `"random"`. Operation tiles may be `null`, which writes the project's empty-tile representation, `{}`.

Palette entries are objects with `id`, optional positive integer `weight` (default `1`), and optional `rotation`. Palette names may contain only letters, numbers, underscores, and hyphens. Palette selection uses the same seeded random-number generator as scatter, furniture scatter, and random rotation, so the same complete recipe and seed produce identical output. Changing a recipe from a raw tile to a palette reference may change later random choices because palette selection consumes random numbers.

```json
{
  "palette": {
    "ground": [
      {"id": "grass_plain_01", "weight": 8, "rotation": "random"},
      {"id": "grass_flowers_00", "weight": 2, "rotation": "random"}
    ],
    "path": [
      {"id": "dirt_light_00", "weight": 3},
      {"id": "grass_dirt_00", "weight": 1, "rotation": "random"}
    ]
  },
  "base_tile": {"palette": "ground"}
}
```

Legacy `regions` are applied first in array order, followed by `operations` in array order. Pattern cells are expanded in their definition order at the position of the invoking operation. Later tile placements on the same logical level overwrite earlier cells, including the complete `feature` of an earlier furnished tile. A furniture operation instead rejects a cell that already has a feature. `regions` remain supported for version-one recipes and use the same filled-rectangle placement implementation as `rectangle` operations.

## Logical levels

Map level-array index `10` is logical ground level `z: 0`. The conversion is:

```text
level-array index = logical z + 10
logical z = level-array index - 10
```

Valid logical levels are integers from `-10` through `10`. Booleans are not integers for recipe purposes. A populated level contains 1024 row-major cells, while a level containing no non-empty tiles is serialized as unused `[]`.

There are two mutually exclusive authoring modes.

### Legacy-compatible root layout

Existing recipes continue to use root `base_tile`, `regions`, and `operations`. The base tile fills `z: 0`. Every root region and operation accepts optional `z`; omission means `z: 0`. Targeting a previously unused level starts that level as empty cells before applying the placement.

```json
{
  "base_tile": {"id": "grass_plain_01"},
  "operations": [
    {
      "type": "pattern",
      "pattern": "wildflower_cluster",
      "at": [16, 12],
      "z": 1,
      "rotation": 90
    }
  ]
}
```

Root `regions` are still processed before root `operations`, even when entries target different logical levels. RNG consumption follows this exact processing order.

### Grouped multi-level layout

For substantial multi-level maps, use a root `levels` array. Every entry requires one unique logical `z` and may contain `base_tile`, `regions`, and `operations`. The entry's base tile, when present, fills that level before its regions and operations. Without a base tile, the level starts empty.

```json
{
  "levels": [
    {
      "z": 0,
      "base_tile": {"id": "grass_plain_01"}
    },
    {
      "z": 1,
      "operations": [
        {
          "type": "rectangle",
          "x": 10,
          "y": 10,
          "width": 12,
          "height": 12,
          "tile": {"id": "grass_plain_01"}
        }
      ]
    }
  ]
}
```

Grouped entries are processed in declaration order. Within each entry, regions precede operations. This declaration order also defines deterministic RNG consumption across levels. Nested regions and operations inherit the entry's `z` and must not repeat a `z` field. Root `base_tile`, `regions`, and `operations` cannot coexist with `levels`; this rejects ambiguous merge and overwrite ordering.

Reusable pattern definitions remain two-dimensional. A root pattern operation selects its target with `z`, while a grouped pattern operation inherits the enclosing level. Multi-level pattern and template composition is outside the current schema.

## Reusable cell patterns

`patterns` maps a name to a non-empty array of relative tile placements. Pattern names follow the same naming rules as palettes. Every cell has an integer `[x, y]` offset in `at` and a `tile`; offsets may be negative, and tiles may use raw IDs, palettes, rotations, or `null` just like operation tiles.

Pattern definitions do not consume random numbers. An invoked pattern consumes randomness in cell-array order only when a cell uses a palette or `"random"` tile rotation. Unused definitions therefore do not change generated output.

```json
{
  "patterns": {
    "wildflower_cluster": [
      {"at": [0, 0], "tile": {"palette": "flowers"}},
      {"at": [1, 0], "tile": {"palette": "flowers"}},
      {"at": [-1, 1], "tile": {"palette": "flowers"}}
    ]
  }
}
```

## Furniture palettes

`furniture_palette` maps a name to a non-empty weighted array of known furniture entries. Entries have `id`, optional positive integer `weight` (default `1`), and optional editor-facing `rotation` (`0`, `90`, `180`, `270`, or `"random"`). Furniture palette names use the same letters/numbers/underscore/hyphen rule as tile palettes. Every entry is validated against the selected furniture database, including unused palette definitions.

```json
{
  "furniture_palette": {
    "clearing_trees": [
      {"id": "Tree_00", "weight": 4, "rotation": "random"},
      {"id": "PineTree_00", "weight": 3, "rotation": "random"},
      {"id": "WillowTree_00", "weight": 1, "rotation": "random"},
      {"id": "burned_tree_stump", "weight": 2, "rotation": "random"}
    ]
  }
}
```

Definitions themselves consume no randomness. An invoked `furniture_scatter` first samples eligible cells, in row-major candidate order, and then selects one palette entry and resolves any random rotation for each sampled cell in the sample order. This is part of the shared recipe RNG stream: moving, adding, or removing an earlier RNG-consuming operation can change later selections.

## Placement operations

Every operation requires a `type`. Unknown operation types and fields are errors. At the recipe root, every operation accepts optional logical `z` and defaults to `0`. Inside a grouped level, the operation inherits `z` and must omit the field.

## Runtime areas and tile membership

Dimensionfall's existing area system has two linked serialized forms:

1. the map-level `areas` array defines a runtime spawn/transformation rule; and
2. a terrain tile's `areas` array records membership as `{"id": "...", "rotation": 0}`.

At runtime, `Helper.map_manager.process_areas_in_map()` selects definitions by `spawn_chance`, then applies each selected definition to connected clusters of matching tile memberships on every populated level. The editor displays these memberships and permits multiple *different* area IDs on one tile, so recipe generation preserves that supported overlay behavior. It rejects a duplicate membership of the same area ID on the same cell.

Recipe area definitions require exactly `id`, `spawn_chance`, `rotate_random`, `pick_one`, `tiles`, and `entities`. Area IDs use letters, numbers, `_`, and `-`; `spawn_chance` is an integer from `0` through `100`; `rotate_random` and `pick_one` are booleans. `tiles` is a non-empty array of `{ "id", "count" }` entries whose IDs are known tiles or the runtime's `"null"` sentinel. `entities` is an array of `{ "id", "type", "count" }` entries. The generator accepts only the existing runtime entity types—`furniture`, `mob`, `mobgroup`, and `itemgroup`—and validates each ID against its core catalog before publishing a map.

```json
{
  "areas": [
    {
      "id": "meadow_clearing",
      "spawn_chance": 100,
      "rotate_random": false,
      "pick_one": false,
      "tiles": [{"id": "grass_dirt_00", "count": 1}],
      "entities": []
    }
  ]
}
```

### Runtime entity variation

An area entity is a runtime rule, not a pre-generated feature. For every processed membership tile, `map_manager` adds an implicit no-spawn entry weighted by the total `tiles` weight, then selects one declared entity by `count`. As a result, the generated JSON boundary is deterministic, but an entity-bearing field can differ each time the map is instanced. Do not replace this with `furniture_scatter` when per-instance variation is desired: scatter intentionally writes the same seeded features into every generated map.

Entity `count` values must be positive integers in recipes. The generator enforces that stricter authoring rule; the standalone validator accepts positive numeric legacy weights so existing authored maps continue to match the runtime's weighted-picker contract. The supported types and ID catalogs are:

| Type | Catalog | Runtime feature result |
|---|---|---|
| `furniture` | `Furniture/Furniture.json` | `{ "type", "id", "rotation" }` |
| `mob` | `Mobs/Mobs.json` | `{ "type", "id", "rotation" }` |
| `mobgroup` | `Mobgroups/Mobgroups.json` | `{ "type", "id", "rotation" }` |
| `itemgroup` | `Itemgroups/Itemgroups.json` | `{ "type": "itemgroup", "itemgroups": ["id"], "rotation" }` |

When `rotate_random` is false, a selected entity uses the membership's editor-facing rotation. When it is true, runtime chooses a quarter turn. Entity selection remains runtime-owned and is never pre-baked by the Python generator.

```json
{
  "id": "stump_clearing",
  "spawn_chance": 100,
  "rotate_random": false,
  "pick_one": false,
  "tiles": [{"id": "grass_dirt_00", "count": 100}],
  "entities": [{"id": "burned_tree_stump", "type": "furniture", "count": 1}]
}
```

### `area_rectangle`

Adds one area membership to every terrain tile in a filled rectangle. Fields are `type`, `area`, `x`, `y`, positive `width`, positive `height`, optional root-level `z`, and optional editor-facing `rotation`. The rotation defaults to `0` and accepts `0`, `90`, `180`, or `270`.

```json
{
  "type": "area_rectangle",
  "area": "meadow_clearing",
  "x": 10,
  "y": 10,
  "width": 12,
  "height": 12,
  "z": 0,
  "rotation": 0
}
```

The referenced top-level area must exist and every target cell must already contain terrain at the selected logical level. A membership operation does not replace terrain, features, or other distinct area memberships, and consumes no RNG. Coordinates are preflighted against the complete `32×32` map, so the operation cannot be clipped or partially applied.

## Authored room semantics

Rooms are authored semantic labels; they are not inferred from floor material, wall topology, door placement, or roof coverage. A recipe may define a root `rooms` array whose entries contain exactly an `id` and `kind`:

```json
{
  "rooms": [
    {"id": "office", "kind": "enclosed"},
    {"id": "garage_bay", "kind": "covered_open"},
    {"id": "ruined_store", "kind": "ruin"}
  ]
}
```

Supported kinds are:

| Kind | Authored meaning |
|---|---|
| `enclosed` | A conventional room intended to be physically enclosed once geometry generation is added. |
| `covered_open` | A roofed but intentionally open space, such as a garage without a garage door. |
| `ruin` | A semantic room that may deliberately have holes or open wall sections. |

Tile membership uses `rooms` as a one-element string array, for example `{"id": "concrete_00", "rooms": ["garage_bay"]}`. A terrain tile may have exactly one room label, while it may still carry multiple runtime `areas` memberships. This makes floor material and area behavior independent from room semantics: adjacent rooms may share one floor material, and one floor-like area can span several rooms.

### `room_rectangle`

Adds one authored room label to every terrain tile in a filled rectangle. Fields are `type`, `room`, `x`, `y`, positive `width`, positive `height`, and optional root-level `z`. It has no rotation because it is semantic metadata, not a spatial transform.

```json
{
  "type": "room_rectangle",
  "room": "garage_bay",
  "x": 12,
  "y": 7,
  "width": 10,
  "height": 8,
  "z": 0
}
```

The referenced root room must exist. Every target cell must already contain terrain, and room membership is exclusive: an operation cannot overlap another room label or partially apply. Room definitions and membership consume no RNG.

This slice preserves `rooms` through `DMap`/content-editor save-load paths and validates them independently. It does **not** infer walls, roofs, enclosure, weather, lighting, or indoor gameplay.

### `room_connections`

`room_connections` explicitly records what existing door furniture connects; the generator never infers it from adjacent floor material, area membership, walls, roofs, or door rotation. Each root entry contains exactly `id`, `at`, `z`, `from`, and `to`:

```json
{
  "room_connections": [
    {
      "id": "office_front_door",
      "at": [11, 10],
      "z": 0,
      "from": {"kind": "room", "id": "office"},
      "to": {"kind": "exterior"}
    },
    {
      "id": "office_to_garage",
      "at": [12, 10],
      "z": 0,
      "from": {"kind": "room", "id": "office"},
      "to": {"kind": "room", "id": "garage_bay"}
    }
  ]
}
```

`id` must be unique and use the normal definition-name characters. `at` is exactly `[x, y]` within the `32×32` map and `z` is a required logical level from `-10` through `10`. Endpoints use one of two exact forms:

```json
{"kind": "room", "id": "office"}
{"kind": "exterior"}
```

Room IDs must exist in root `rooms`; the two endpoints must be distinct; and one door coordinate may have only one connection. The target tile must already exist at the declared level and contain a catalog-recognized door-capable furniture feature—for example, `door_wood`, whose existing runtime implementation owns open/closed state and collision behavior.

Connections are semantic metadata only. They preserve their authored `from`/`to` order but do not create a new door feature, alter existing door behavior, infer enclosure, generate geometry, or introduce an indoor/outdoor runtime state. `DMap` preserves valid links through content-editor save/load and removes links that name deleted rooms.

### `room_boundaries`

`room_boundaries` explicitly attaches an existing physical wall tile or connected door opening to one authored room. It does not derive a perimeter from rooms, floor material, wall rotation, or neighboring geometry. A legacy/partial record contains `id`, `room`, `at`, `z`, and `element`; it may add `side` when directional evidence is needed:

```json
{
  "room_boundaries": [
    {
      "id": "office_north_wall",
      "room": "office",
      "at": [8, 7],
      "z": 0,
      "element": "wall_tile",
      "side": "south"
    },
    {
      "id": "office_front_opening",
      "room": "office",
      "at": [11, 10],
      "z": 0,
      "element": "door_furniture"
    }
  ]
}
```

`id` is unique and uses normal definition-name characters. `room` must name a root room, `at` is an in-bounds `[x, y]`, and `z` is a required logical level from `-10` through `10`. `element` is exactly one of:

| Element | Existing target requirement |
|---|---|
| `wall_tile` | The target terrain ID is in the tile catalog and has the `Wall` category; it must be cardinally adjacent to a tile labelled with the named room. |
| `door_furniture` | The target terrain tile contains catalog-recognized door-capable furniture and a `room_connections` entry at the same `[x, y, z]` names the room. |

A room cannot name the same target coordinate twice, but one wall tile may deliberately bound different rooms through separate records. `side`, when present, is `north`, `east`, `south`, or `west`. For `wall_tile`, it points from the wall tile toward its room; for `door_furniture`, it points outward from the room tile through that door.

An `enclosed` room may opt in to strict completeness by adding `"boundary_validation": "complete"` to its root definition. For such a room, every exposed cardinal edge of every labelled room tile must have exactly one directed boundary record. Its records therefore require `side`: a wall must point to the matching room edge, and a door must start on the matching room tile and retain its required `room_connections` endpoint. Missing, wrongly oriented, duplicate, or non-exposed records are rejected. `covered_open` and `ruin` rooms cannot opt in and continue to allow partial boundary evidence.

Boundary metadata preserves existing terrain, furniture, rotation, collision, and runtime door behavior. `DMap` preserves it through content-editor save/load and removes records naming deleted rooms. It does not create walls or openings, infer a door from rotation, change navigation, or add indoor/outdoor effects.

### `buildings`

`buildings` groups existing authored room evidence into one explicit, rectangular single-level building footprint. It does not generate terrain, walls, doors, roofs, furniture, tile-local memberships, or indoor runtime state:

```json
{
  "buildings": [
    {
      "id": "office_building",
      "rooms": ["office"],
      "footprint": {"x": 7, "y": 7, "width": 4, "height": 4},
      "z": 0
    }
  ]
}
```

Each record has required `id`, `rooms`, `footprint`, and `z`, plus optional `access_validation`, `interior_rooms`, and `open_space_rooms`. `id` is unique; `rooms` is a nonempty list of unique known room IDs; `footprint` has exactly non-negative integer `x`/`y` plus positive integer `width`/`height`, fully inside the 32×32 map; and `z` is a required logical level from `-10` through `10`. Footprints on the same logical z must not overlap, though they may touch.

Every owned room must have membership only at the building level and wholly inside its footprint. At least one owned room must be an `enclosed` room with `"boundary_validation": "complete"`. Its same-level `room_boundaries` and any same-level `room_connections` naming it must also lie inside the footprint. This makes the record a strict ownership/containment contract for already-authored physical evidence, not a claim that every footprint cell is occupied, roofed, or indoors.

A building may opt into authored access completeness with `"access_validation": "complete"`:

```json
{"id": "office_building", "rooms": ["office"], "footprint": {"x": 7, "y": 7, "width": 4, "height": 4}, "z": 0, "access_validation": "complete"}
```

For that building, every owned room must have a path to `exterior` through same-z authored `room_connections`. A room-to-exterior connection seeds the path; a room-to-room connection propagates it only when both endpoint rooms belong to the same building. Links to rooms outside the building do not satisfy the rule. This validates semantic authored access, not physical walkability: it does not infer door adjacency, rotation, collision, navigation, or player traversal.

A building may explicitly classify a nonempty subset of its owned rooms as interior with `interior_rooms`:

```json
{"id": "office_building", "rooms": ["office"], "footprint": {"x": 7, "y": 7, "width": 4, "height": 4}, "z": 0, "interior_rooms": ["office"]}
```

Every declared interior room must be a unique, owned, known room whose authored kind is `enclosed` and whose `boundary_validation` is `complete`. The contract never infers interiors from floor material, walls, doors, access links, roof/ceiling records, or geometry. It deliberately excludes `covered_open` and `ruin`; those retain their authored semantic meanings without being classified as interior.

A building may explicitly classify a nonempty subset of its owned rooms as open space with `open_space_rooms`:

```json
{"id": "office_building", "rooms": ["office", "garage_bay"], "footprint": {"x": 7, "y": 7, "width": 5, "height": 4}, "z": 0, "interior_rooms": ["office"], "open_space_rooms": ["garage_bay"]}
```

Every declared open-space room must be unique, owned, known, and authored as `covered_open` or `ruin`. It must not overlap `interior_rooms`. This makes a roofed/open-front garage or damaged annex explicit without treating it as an interior. The contract does not infer open space from missing walls, absent roofs, exterior access, terrain material, or geometry, and it neither generates nor changes physical openings.

`DMap` preserves building records through editor save/load and removes records whose room list, declared interior rooms, or declared open-space rooms become stale. The standalone validator performs strict shape, containment, same-level overlap, complete-enclosed-room, opted-in access, and authored interior/open-space classification checks.

### `building_surfaces`

`building_surfaces` declares authored overhead semantics for an existing validated building footprint without creating roof or ceiling geometry:

```json
{
  "building_surfaces": [
    {"id": "office_roof", "building": "office_building", "kind": "roof", "z": 1},
    {"id": "office_ceiling", "building": "office_building", "kind": "ceiling", "z": 1}
  ]
}
```

Each record has exactly `id`, `building`, `kind`, and `z`. `id` is unique; `building` must name a root `buildings` record; and `kind` is exactly `roof` or `ceiling`. A building may have at most one record of each kind. `z` is the logical level immediately above the building footprint (`building.z + 1`), so surface semantics inherit the footprint bounds without duplicating coordinates.

`roof` and `ceiling` are separate authored classifications and may both be present for one building. They do not place tiles on their `z`, create a roof or ceiling mesh, imply collision/support, change lighting/weather, mark rooms indoors, or make overhead cells occupied. `DMap` preserves valid records and removes surfaces whose referenced building is deleted; generator and standalone validation enforce the strict reference, uniqueness, and z relationship.

### `building_compositions`

`building_compositions` is an opt-in, data-only assertion that an existing building contains the named authored overhead classifications:

```json
{
  "building_compositions": [
    {
      "id": "office_complete_overhead",
      "building": "office_building",
      "required_surfaces": ["roof", "ceiling"]
    }
  ]
}
```

Each record has exactly `id`, `building`, and nonempty `required_surfaces`. `id` is unique; one composition may target each building; `building` must name an existing root `buildings` record; and every required surface kind must be unique and exactly `roof` or `ceiling`. Each named kind must have a matching valid `building_surfaces` record for the same building. This is opt-in: a building without a composition remains valid, and composition does not require all supported kinds unless its author lists them.

Compositions add no geometry or runtime behavior. They only validate authored cross-record consistency; they do not infer indoor status, surface coverage, support, or the presence of any roof/ceiling tiles or meshes. `DMap` preserves valid records and removes ones that reference deleted buildings.

No generalized templates, polygons, multi-level building records, furniture anchors, or generation operations are introduced.

### `set`

Places one tile. Fields: `type`, `x`, `y`, `tile`, and optional root-level `z`.

```json
{"type": "set", "x": 16, "y": 15, "tile": {"id": "grass_flowers_01"}}
```

### `rectangle`

Fills a rectangle. Fields: `type`, `x`, `y`, positive `width`, positive `height`, `tile`, and optional root-level `z`.

```json
{"type": "rectangle", "x": 10, "y": 9, "width": 12, "height": 14, "tile": {"id": "grass_plain_01"}}
```

### `rectangle_outline`

Places only the rectangle border and uses the same fields as `rectangle`. If width or height is `1`, every cell in the resulting one-cell-wide shape is border.

```json
{"type": "rectangle_outline", "x": 10, "y": 9, "width": 12, "height": 14, "tile": {"id": "grass_dirt_00"}}
```

### `line`

Places an inclusive, one-tile-wide line between integer `[x, y]` endpoints. Fields: `type`, `from`, `to`, `tile`, and optional root-level `z`. Lines use the integer Bresenham algorithm, so horizontal, vertical, diagonal, steep, and reversed lines are deterministic.

```json
{"type": "line", "from": [0, 16], "to": [31, 16], "tile": {"id": "dirt_light_00"}}
```

### `scatter`

Selects unique cells in a rectangular `region` using the recipe's seeded random-number generator. Fields: `type`, `region`, exactly one of `count` or `density`, `tile`, and optional root-level `z`.

- `count` is an integer from zero through the number of cells in the region.
- `density` is a number from `0` through `1`; the placement count is `floor(region area × density)`.
- Selected cells replace their existing tiles.
- The same complete recipe and seed produce the same selection and output.

```json
{
  "type": "scatter",
  "region": {"x": 0, "y": 0, "width": 32, "height": 32},
  "density": 0.1,
  "tile": {"id": "grass_flowers_00", "rotation": "random"}
}
```

### `pattern`

Places every cell from a named pattern relative to an anchor. Fields: `type`, `pattern`, `at`, optional root-level `z`, and optional `rotation`. Rotation defaults to `0` and accepts fixed clockwise quarter turns: `0`, `90`, `180`, or `270`.

Offsets rotate around the anchor: `90` maps `[x, y]` to `[-y, x]`. The generator preflights the complete expansion and rejects the operation if any resulting cell is outside the map; patterns are never clipped or partially applied.

```json
{
  "type": "pattern",
  "pattern": "wildflower_cluster",
  "at": [16, 12],
  "rotation": 90
}
```

### `furniture`

Embeds one known single-cell furniture feature in an existing terrain tile. Fields: `type`, `x`, `y`, `id`, optional root-level `z`, and optional `rotation`. Rotation defaults to `0` and accepts fixed editor-facing quarter turns: `0`, `90`, `180`, or `270`.

```json
{
  "type": "furniture",
  "x": 16,
  "y": 16,
  "z": 0,
  "id": "bench_garden",
  "rotation": 90
}
```

The target cell must already contain a terrain tile on the selected logical level and must not already contain a feature. The generator validates `id` against the selected furniture database and writes the existing map/editor representation:

```json
{
  "id": "grass_dirt_00",
  "feature": {
    "type": "furniture",
    "id": "bench_garden",
    "rotation": 90,
    "itemgroups": []
  }
}
```

The operation consumes no randomness. Repeating a furniture operation on the same cell is a conflict error. A later tile operation deliberately replaces the complete tile dictionary and therefore removes an earlier feature, following the established ordered tile-overwrite behavior.

The serialized feature has no logical-level, static/movable, state, or mode field. `Chunk.process_level_data()` derives world height from the containing level-array index, and runtime furniture data selects the static or physics spawner from the referenced furniture definition's `moveable` property. Blueprint `mode` belongs to saved runtime furniture state and is not part of a newly generated map feature.

### `furniture_scatter`

Places a bounded number of single-cell furniture features selected from a named `furniture_palette`. Fields: `type`, `region`, `palette`, exactly one of `count` or `density`, and optional root-level `z`.

- `count` is an integer from zero through the geometric region area.
- `density` is a number from `0` through `1`; the requested placement count is `floor(region area × density)`.
- Eligible cells must already contain terrain on the target logical level and must not already have a feature.
- If the requested count exceeds the remaining eligible cells, generation fails before mutating the scatter operation's target cells.
- Candidate coordinates are enumerated in row-major order, then sampled without replacement with the recipe RNG. Each sampled cell selects one weighted furniture entry and resolves its rotation in sample order.
- Scatter embeds the same `feature` object as explicit `furniture`; it does not infer footprints, itemgroups, or adjacent-level occupancy.

```json
{
  "type": "furniture_scatter",
  "region": {"x": 8, "y": 8, "width": 16, "height": 16},
  "z": 0,
  "count": 24,
  "palette": "clearing_trees"
}
```

## Validation and limitations

The generator rejects unknown fields at every recipe level, root-level dimension fields, malformed or out-of-bounds placements, logical levels outside `-10` through `10`, duplicate grouped levels, ambiguous root/grouped layouts, malformed tile or furniture databases, unknown tile and furniture IDs, malformed area definitions or memberships, duplicate area IDs or same-ID tile memberships, unsupported area cells, feature conflicts, scatter requests that exceed eligible cells, invalid rotations, invalid Unicode, and non-object recipes. It validates generated data with `Tools/map_validator.py` before publishing the output. The validator independently requires exactly 21 level arrays and exactly 1024 entries in every populated level, and structurally validates embedded furniture fields, IDs, rotations, itemgroup arrays, and area-reference arrays.

The output uses 21 levels; logical `z: 0` is row-major grid index `10`. It sets `categories` to `[]`, `weight` to `1000`, and all four connections to `"ground"`. It omits `areas`, matching `DMap.get_data()` when the area list is empty.

The generator currently creates explicit, known, single-cell furniture features, deterministic weighted furniture scatter over eligible terrain, strict runtime-compatible rectangular area memberships at explicit logical levels, and authored room labels through terrain-backed `room_rectangle` operations. Areas can additionally declare catalog-validated weighted runtime `furniture`, `mob`, `mobgroup`, and `itemgroup` entities; selection occurs when the map is instanced rather than during Python generation. Room labels are semantic only and do not yet create or infer geometry. The core mod defines `rock_field_00` and `wild_vegetation_00` for outdoor composition, using the dedicated AI-generated sprites `ai_rock_32_32.png` and `ai_vegetation_32_32.png`. It does not yet support furniture itemgroup contents, multiple features per cell, multi-tile or tall-object occupancy, automatic support inference, polygonal areas, walls, doors, buildings, roads as semantic objects, towns, nested or multi-level patterns, or shape-based templates.

The maintained area examples are `Tools/examples/map_recipe_area_meadow.json` and `Tools/examples/map_recipe_area_entity_clearing.json`; the maintained room example is `Tools/examples/map_recipe_room_semantics.json`. The maintained furniture example is `Tools/examples/map_recipe_furniture_outdoor.json`. Maintained structural examples are available at `Tools/examples/map_recipe_two_level_hill.json` and `Tools/examples/map_recipe_two_level_depression.json`. They use `grass_ramp_00`, whose tile definition has `shape: "slope"`.

Slope rotations in recipes use the same values shown by the map editor:

| Rotation | High edge |
|---:|---|
| `0` | north |
| `90` | east |
| `180` | south |
| `270` | west |

The generator preserves these editor-facing values in map JSON. When a newly generated map is loaded, `Chunk.get_block_rotation()` applies the slope's shape-specific conversion before rendered mesh, collision, and navigation geometry use the internal orientation. Do not pre-convert recipe rotations to the internal `calculate_slope_vertices()` mapping.

`Tests/Unit/test_chunk_slope_rotation.gd` verifies all four editor rotations against the converted runtime rotation and confirms matching high edges in rendered mesh vertices, convex collision geometry, and navigation-source faces. `Tests/Unit/test_chunk_slope_navigation.gd` performs the real asynchronous bake and confirms that every orientation has a queryable path from low to high and from high to low. The Python example test separately confirms that the authored high-side tile and lower-level low-side tile are occupied. Manual playtesting of both maintained maps has also confirmed that the real player controller walks up and down all four slope orientations without traversal or invisible-collision problems.
