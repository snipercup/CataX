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

The output filename must be `<id>.json`, matching the map loader's filename-derived ID. Existing output is protected. Pass `--overwrite` only when replacement is intended. Use `--tiles PATH` to validate tile IDs against a tile database other than `Mods/Dimensionfall/Tiles/Tiles.json`.

For batch generation of deterministic seed variants and instructions for inspecting them in Godot's content editor, see [`map_example_generation.md`](map_example_generation.md).

## Recipe format

The root must be a JSON object with these fields:

| Field | Type | Meaning |
| --- | --- | --- |
| `id` | string | Map ID using only letters, numbers, `_`, and `-`. |
| `name` | non-empty string | Display name. |
| `description` | non-empty string | Map description. |
| `seed` | integer | Fixed seed used by palettes, random tile rotations, scatter, and pattern cells. Recipe input only; the map format does not store it. |
| `base_tile` | tile object | Legacy-mode tile initially placed in every cell at `z: 0`. Required unless `levels` is used. |
| `palette` | object | Named weighted tile sets that tile objects can reference. Optional; defaults to `{}`. |
| `patterns` | object | Named arrays of relative tile placements used by `pattern` operations. Optional; defaults to `{}`. |
| `regions` | array | Legacy filled rectangles. Optional; defaults to `[]`. |
| `operations` | array | Ordered placement operations. Optional; defaults to `[]`. |
| `levels` | non-empty array | Explicit grouped level definitions. Cannot be combined with root `base_tile`, `regions`, or `operations`. |

A recipe does not define map dimensions: all generated maps are 32 x 32. Top-down `[x, y]` coordinates start at the top-left. Logical `z` is vertical elevation, not a third element in `[x, y]`. Every shape must fit entirely within the map; operations are never silently clipped.

A tile object has exactly one of:

- `id`: a raw tile ID from the selected `Tiles.json`; or
- `palette`: the name of a root-level palette.

It may also include an optional `rotation` when using `id`. Rotation is `0`, `90`, `180`, `270`, or `"random"`. Operation tiles may be `null`, which writes the project's empty-tile representation, `{}`.

Palette entries are objects with `id`, optional positive integer `weight` (default `1`), and optional `rotation`. Palette names may contain only letters, numbers, underscores, and hyphens. Palette selection uses the same seeded random-number generator as scatter and random rotation, so the same complete recipe and seed produce identical output. Changing a recipe from a raw tile to a palette reference may change later random choices because palette selection consumes random numbers.

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

Legacy `regions` are applied first in array order, followed by `operations` in array order. Pattern cells are expanded in their definition order at the position of the invoking operation. Later placements on the same logical level overwrite earlier cells, including repeated offsets inside one pattern. `regions` remain supported for version-one recipes and use the same filled-rectangle placement implementation as `rectangle` operations.

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

## Placement operations

Every operation requires a `type`. Unknown operation types and fields are errors. At the recipe root, every operation accepts optional logical `z` and defaults to `0`. Inside a grouped level, the operation inherits `z` and must omit the field.

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

## Validation and limitations

The generator rejects unknown fields at every recipe level, root-level dimension fields, malformed or out-of-bounds placements, logical levels outside `-10` through `10`, duplicate grouped levels, ambiguous root/grouped layouts, malformed tile databases, unknown tile IDs, invalid rotations, invalid Unicode, and non-object recipes. It validates generated data with `Tools/map_validator.py` before publishing the output. The validator independently requires exactly 21 level arrays and exactly 1024 entries in every populated level.

The output uses 21 levels; logical `z: 0` is row-major grid index `10`. It sets `categories` to `[]`, `weight` to `1000`, and all four connections to `"ground"`. It omits `areas`, matching `DMap.get_data()` when the area list is empty.

The generator does not yet create features, furniture, areas, roads as semantic objects, buildings, towns, nested or multi-level patterns, or shape-based templates. It does not infer support or transition validity from stacked tiles. Structural validity and the presence of slope tiles do not yet guarantee walkability, reachability, or gameplay quality.

Maintained structural examples are available at `Tools/examples/map_recipe_two_level_hill.json` and `Tools/examples/map_recipe_two_level_depression.json`. They use `grass_ramp_00`, whose tile definition has `shape: "slope"`.

Slope rotations in recipes use the same values shown by the map editor:

| Rotation | High edge |
|---:|---|
| `0` | north |
| `90` | east |
| `180` | south |
| `270` | west |

The generator preserves these editor-facing values in map JSON. When a newly generated map is loaded, `Chunk.get_block_rotation()` applies the slope's shape-specific 90-degree conversion before rendered mesh, collision, and navigation geometry use the internal orientation. Do not pre-convert recipe rotations to the internal `calculate_slope_vertices()` mapping. The maintained examples exercise these known slope endpoints; they are not a general-purpose transition validator.
