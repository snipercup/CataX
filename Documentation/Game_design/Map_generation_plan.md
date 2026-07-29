You have now completed the **foundation, minimal generator, general placement-primitives, and manual evaluation-harness milestones**. The project can generate and batch-test structurally valid, visually recognizable 32×32 outdoor Dimensionfall maps from compact recipes, but it cannot yet place gameplay features or buildings.

## Overall goal

The long-term objective is a map-authoring pipeline where an agent describes a map at a meaningful design level rather than manually writing thousands of JSON entries.

```text
Map concept
    ↓
Compact recipe
    ↓
Deterministic generator
    ↓
Complete Dimensionfall map JSON
    ↓
Automated validation and tests
    ↓
Godot/editor smoke test
    ↓
Playable map
```

For example, the eventual recipe should express concepts such as:

```text
Create a forest settlement with:
- a road entering from the west
- three small buildings around a square
- a pond to the southeast
- trees around the perimeter
- indoor and outdoor areas
```

The generator should handle the mechanical work:

* converting top-down coordinates and logical z values to level and tile-array indices;
* producing all 1024 entries per populated level;
* inserting valid tile and furniture IDs;
* generating metadata;
* creating areas and connections;
* enforcing horizontal and vertical bounds;
* creating and validating transitions between logical levels;
* producing deterministic output;
* rejecting invalid designs before they reach Godot.

The agent remains responsible for map intent and composition. The generator remains responsible for correctness.

---

# Current state

## 1. Agent guidance: complete

`AGENTS.md` was revised to work well with Hermes rather than relying on Codex-specific or TaskMaster-specific behavior.

The repository guidance is now intended to be:

* tool-independent;
* repository-specific;
* suitable for multiple Hermes profiles;
* focused on project structure, coding standards, validation, and safe editing;
* free of personal Docker, worktree, Kanban, and model configuration details.

This gives the map-making agents a stable set of repository instructions.

## 2. Existing-map sanitation: complete

The project now sanitizes malformed tile data when maps are serialized.

Corrupt or incomplete tile dictionaries—particularly entries missing a valid tile ID—are converted to the established empty-tile representation:

```json
{}
```

A GUT test was added around this behavior.

This protects existing and generated maps from lingering malformed tile entries.

## 3. Map validator improvements: complete

`Tools/map_validator.py` now understands the fixed Dimensionfall map dimensions.

It rejects:

* `mapwidth` values other than `32`;
* `mapheight` values other than `32`;
* populated levels with fewer than 1024 entries;
* populated levels with more than 1024 entries.

It continues accepting unused levels represented as:

```json
[]
```

The validator successfully caught the original invalid generated prototype:

```text
width: 12
height: 8
level 10 entries: 96
```

That is an important milestone because the validator now independently enforces the structural assumptions used by the generator.

## 4. Recipe-driven generator prototype: complete

The merged work added:

```text
Tools/map_generator.py
Tools/examples/map_recipe.json
Tools/tests/test_map_generator.py
Documentation/Modding/map_recipe_generator.md
```

The generator currently supports:

* map ID;
* display name;
* description;
* deterministic integer seed;
* one populated level at level-array index 10;
* a base tile covering the entire map;
* ordered rectangular regions;
* ordered `set`, `rectangle`, `rectangle_outline`, `line`, and `scatter` operations;
* inclusive Bresenham line rasterization;
* deterministic scatter by count or density;
* root-level reusable cell-pattern definitions;
* ordered pattern placement at an anchor with fixed quarter-turn rotation;
* root-level weighted tile palettes referenced by base tiles and placement operations;
* fixed tile rotations;
* deterministic random rotations;
* `null` region tiles that produce `{}`;
* tile-ID validation against the tile database;
* strict rejection of unknown recipe fields;
* region bounds validation;
* output filename validation;
* overwrite protection;
* generation to a temporary file;
* validation before publication;
* atomic replacement of the target file.

It always produces:

```text
mapwidth: 32
mapheight: 32
populated level size: 1024
unused levels: []
```

## 5. Generator and validator tests: complete for version 1

The current Python test suite contains 44 tests and passes.

Coverage includes:

* fixed 32×32 dimensions;
* exactly 1024 entries;
* deterministic generation;
* rectangular overlays;
* single-cell placement;
* filled and outlined rectangles, including thin outlines;
* horizontal, vertical, and diagonal lines;
* deterministic scatter by count and density;
* operation ordering and overwrite behavior;
* operation field, type, coordinate, bounds, and scatter-argument validation;
* empty-tile representation;
* unknown fields;
* invalid IDs;
* unknown tile IDs;
* palette references, weighted deterministic selection, and malformed palette rejection;
* reusable pattern expansion, rotation, ordering, determinism, compatibility, and validation;
* invalid metadata;
* malformed tile databases;
* out-of-bounds placement;
* output filename mismatch;
* overwrite protection;
* validator rejection of bad dimensions;
* validator rejection of short and long levels;
* acceptance of unused empty levels;
* acceptance of correctly generated maps.

This is sufficient coverage for the prototype’s present capabilities.

## 6. Repository ownership and remotes: complete

Your working repository is now your fork:

```text
origin:
https://github.com/snipercup/CataX.git

upstream:
https://github.com/Dimensionfall/Dimensionfall.git
```

That gives you control over the generator roadmap without depending on every experimental stage being accepted upstream immediately.

Your working directory remains:

```bash
~/hermes/dimensionfall/workspace/Dimensionfall-test-runner
```

## 7. Manual example generation and evaluation: complete

The project now includes:

```text
Tools/generate_map_examples.py
Tools/tests/test_generate_map_examples.py
Documentation/Modding/map_example_generation.md
```

The runner generates one or more deterministic seed variants from maintained recipes, delegates validation and atomic publication to the existing generator, and can place outputs directly in a mod's `Maps` directory for content-editor inspection. It validates the complete batch and rejects duplicate output paths before publication. Newly created outputs and their SHA-256 digests are recorded in a non-JSON manifest so cleanup removes only unchanged runner-owned files.

Ten focused tests cover variant IDs, complete map shape, determinism, CLI generation and cleanup, overwrite ownership, changed-file preservation, malformed recipes, duplicate outputs, and failed-publication safety.

---

# What the generator cannot do yet

The current recipe language is intentionally minimal. It cannot yet express most meaningful maps.

It does not currently support:

* nested, shape-based, or multi-level pattern composition;
* circles or irregular regions;
* terrain blending;
* multiple populated vertical levels;
* features or furniture;
* areas or rooms;
* doors;
* buildings;
* roads as semantic objects;
* map-edge connection placement;
* reusable templates;
* towns or settlements;
* biome rules;
* walkability checks;
* accessibility or connectivity checks;
* encounters, creatures, items, or spawn points;
* standalone image or HTML previews outside Godot; generated map JSON can already be opened with the existing content-editor map preview;
* importing an existing map into a recipe;
* regeneration while preserving hand-authored changes.

At present, it can create a recognizable outdoor terrain layout with paths, bounded clearings, and scattered variation. It cannot yet create a credible playable location because it has no furniture, semantic areas, buildings, or gameplay content.

---

# Progress tracking

This document is the roadmap source of truth. Keep it current at milestone boundaries rather than recording a chronological activity log:

* use `planned`, `next`, `in progress`, or `complete` for each phase;
* mark a phase complete only after its success criterion and listed validation pass;
* when a phase changes, update its delivered list, current capabilities and limitations, test count, recommended next task, and the one-view summary together;
* keep temporary implementation notes and command output out of this document;
* preserve detailed operation contracts in `Documentation/Modding/map_recipe_generator.md` and tests rather than duplicating them here.

---

# Roadmap

## Phase 1 — Structural safety

**Status: complete**

Goals:

* sanitize malformed map data;
* understand the real map structure;
* improve validator coverage;
* establish agent guidance.

Delivered:

* sanitation in `DMap`;
* GUT sanitation test;
* improved validator;
* Hermes-oriented `AGENTS.md`.

## Phase 2 — Minimal deterministic generator

**Status: complete**

Goals:

* define a compact recipe;
* generate one valid ground level;
* validate before writing;
* test determinism and failure cases.

Delivered:

* recipe format version 1;
* generator CLI;
* fixed 32×32 output;
* base tile plus rectangular overlays;
* tile validation;
* 16 Python tests;
* documentation and example.

## Phase 3 — General placement primitives

**Status: complete**

Delivered:

* ordered `operations` applied after legacy `regions`;
* `set`, filled `rectangle`, and `rectangle_outline` placement;
* inclusive one-cell-wide lines using the integer Bresenham algorithm;
* deterministic scatter using exactly one of `count` or `density`;
* strict bounds with no silent clipping;
* unknown-field and unknown-operation rejection;
* shared placement logic for legacy regions and rectangle operations;
* an outdoor example with a path, bounded clearing, and scattered flowers;
* focused tests and recipe documentation.

### Success criterion

A recipe can generate a visually recognizable outdoor layout containing:

* a base terrain;
* one path;
* one bounded clearing;
* some deterministic scattered variation.

No furniture or buildings yet. This criterion is met by `Tools/examples/map_recipe.json`.

## Phase 4A — Manual example generation and evaluation harness

**Status: complete**

Delivered:

* a Python CLI that reuses the existing generator rather than duplicating it;
* one-command generation of multiple deterministic seed variants;
* unique map IDs and matching filenames;
* configurable recipe, tile database, output directory, variant count, and starting seed;
* overwrite protection inherited from the generator;
* a non-JSON ownership manifest with SHA-256 identity checks and exact-file cleanup;
* direct output to a mod's `Maps` directory for inspection in the existing content-editor preview;
* focused tests and a manual tester guide with example commands.

### Success criterion

A developer can run one documented command, launch Godot, and inspect at least three deterministic generated variants in the content editor without manually editing recipes or renaming output files. Cleanup leaves unrelated maps untouched.

## Phase 4B — Tile palettes and reusable patterns

**Status: complete**

Raw tile IDs are cumbersome and encourage agents to invent invalid identifiers. Introduce semantic recipe-level palettes.

Example:

```json
{
  "palette": {
    "ground": [
      {
        "id": "grass_plain_01",
        "weight": 8
      },
      {
        "id": "grass_flowers_00",
        "weight": 2
      }
    ],
    "path": [
      {
        "id": "dirt_light_00",
        "weight": 3
      },
      {
        "id": "grass_dirt_00",
        "weight": 1
      }
    ]
  }
}
```

Delivered:

* root-level semantic tile palettes;
* weighted deterministic selection;
* palette references from `base_tile`, legacy `regions`, and every placement operation;
* strict palette validation and known tile-ID checking;
* updated example recipe using palettes for ground, clearing, paths, and flowers.
* named reusable cell patterns with signed offsets;
* anchored pattern operations with fixed quarter-turn rotation;
* strict pattern-definition, reference, field, and expanded-bounds validation;
* deterministic cell-order expansion using existing tile and palette semantics;
* updated example recipe reusing one flower-cluster pattern at three orientations.

### Success criterion

The generator can create terrain that looks varied without requiring a recipe entry for every cell.

This criterion is met by weighted palettes, deterministic scatter, and reusable cell patterns. Richer nested and shape-based composition belongs in Phase 8 rather than extending this foundation phase indefinitely.

## Phase 4C — Vertical levels and 3D placement foundations

**Status: next; requires schema and runtime investigation**

Dimensionfall maps already contain 21 level arrays. Level-array index `10` is logical elevation `0`, with valid logical elevations from `-10` through `+10`:

```text
level-array index = logical z + 10
logical z = level-array index - 10
```

Existing maps use this structure for hills, holes, craters, underground locations, and multi-story buildings. The generator needs a shared vertical-coordinate contract before features, rooms, buildings, and templates are added.

Goals:

* add recipe-level logical `z` coordinates while preserving top-down `[x, y]` coordinates;
* default omitted `z` to `0` so existing recipes remain compatible;
* support multiple populated level arrays;
* allow every placement operation and pattern invocation to target a logical level;
* investigate a per-level recipe structure for substantial multi-level maps;
* define per-level base-tile and empty-level behavior;
* map logical elevations `-10` through `+10` to level-array indices `0` through `20`;
* preserve exactly 1024 entries in every populated level and `[]` for unused levels;
* define deterministic operation and RNG ordering across levels;
* validate horizontal bounds, vertical bounds, duplicate level definitions, and complete pattern expansion;
* investigate slope, stair, support, collision, and traversal semantics before enforcing gameplay rules.

Recommended compatibility form for individual placement:

```json
{
  "type": "pattern",
  "pattern": "wildflower_cluster",
  "at": [16, 12],
  "z": 1,
  "rotation": 90
}
```

For larger recipes, prefer grouping content by logical level rather than repeating `z` on every operation:

```json
{
  "levels": [
    {
      "z": 0,
      "base_tile": {"palette": "ground"},
      "operations": []
    },
    {
      "z": 1,
      "operations": []
    }
  ]
}
```

The detailed schema must define whether legacy root-level placement can coexist with a `levels` entry for `z: 0`. Ambiguous ordering must be rejected unless an explicit merge contract is adopted.

Initial structural validation:

* `z` is an integer from `-10` through `+10`;
* converted level indices remain within `0` through `20`;
* the output always contains exactly 21 level arrays;
* every populated level contains exactly 1024 row-major tile entries;
* unused levels remain `[]`;
* every operation and expanded pattern remains horizontally and vertically in bounds;
* duplicate or ambiguous per-level definitions are rejected;
* identical recipes and seeds produce identical output across every populated level.

Runtime investigation must determine:

* how tiles with `shape: "slope"` connect adjacent logical levels;
* how slope and stair rotation determines lower and upper endpoints;
* whether transitions require corresponding tiles on both levels;
* how floors, walls, roofs, ceilings, and intentional air gaps occupy stacked levels;
* whether support is determined by tile presence, collision shape, or another runtime rule;
* which transition, support, and reachability checks can be reproduced reliably in Python.

Reference fixtures should include existing hills, depressions, deep craters, buildings, and underground maps such as `field_grass_hill_00`, `field_grass_hole_00`, `crater_small`, `two_story_house`, and `underground_lab`.

### Success criterion

Generate and validate one two-level hill and one two-level depression from recipes. Each map has correctly sized populated levels, preserves unused levels as `[]`, uses valid transition tiles, loads in Godot, and permits runtime traversal between generated elevations.

## Phase 5 — Features and furniture

**Status: planned; requires schema investigation**

This is where generated maps start becoming playable rather than merely visual.

The agent should first determine:

* how features are represented;
* how furniture or objects are stored;
* whether objects belong directly to tiles or separate arrays;
* how rotation and state are encoded;
* how IDs are validated;
* whether occupied tiles require supporting terrain;
* how multi-tile objects work;
* whether tall features occupy or block cells on adjacent logical levels.

Likely recipe concepts:

```json
{
  "features": [
    {
      "template": "tree",
      "at": [5, 8],
      "z": 0
    },
    {
      "template": "bench",
      "at": [15, 13],
      "z": 0,
      "rotation": 90
    }
  ]
}
```

Necessary validation:

* known feature IDs;
* horizontal and vertical bounds;
* occupied-cell conflicts;
* support rules on the target logical level;
* conflicts with incompatible geometry above or below;
* prohibited overlap;
* deterministic scatter;
* placement failure reporting.

### Success criterion

Generate an outdoor map with trees, rocks, vegetation, and simple interactable or decorative objects. The first example may remain at `z: 0`, but the feature schema and validation must support explicit logical levels from its first version.

## Phase 6 — Areas, rooms, and buildings

**Status: planned**

The generator needs semantic areas before it can create convincing buildings.

Capabilities:

* named, level-aware rectangular or polygonal areas;
* room boundaries;
* floors and walls;
* doors and openings;
* indoor/outdoor designation;
* area metadata;
* reusable building footprints;
* furniture anchors;
* multi-level building geometry using logical z coordinates;
* occupied-floor, wall, ceiling, roof, and intentional-air-space semantics;
* vertical transition anchors.

Example concept:

```json
{
  "buildings": [
    {
      "template": "small_cabin",
      "origin": {
        "at": [10, 9],
        "z": 0
      },
      "entrance": "south",
      "area_id": "cabin_1"
    }
  ]
}
```

Important checks:

* every room has an entrance;
* doors connect compatible cells;
* walls do not block all access;
* area definitions match physical boundaries;
* upper geometry has valid support according to the runtime rules established in Phase 4C;
* occupied floors have valid, unobstructed vertical transitions;
* stairs and slopes connect valid destinations on adjacent logical levels;
* roofs, ceilings, and walls do not incorrectly occupy walkable interior cells;
* furniture remains inside intended rooms.

### Success criterion

Generate one small, enterable building that loads correctly and has a reachable interior. The generated structure must exercise vertical geometry and include at least two reachable occupied floors, valid support, a working vertical transition, and correctly scoped rooms and furniture.

## Phase 7 — Roads and map connections

**Status: planned**

The prototype currently puts placeholder connection values in the output. These need to become meaningful.

Capabilities:

* entrances on map edges;
* road endpoints;
* path routing between anchors;
* north/east/south/west connection metadata;
* guaranteed connection between entry points and important locations;
* bridge or obstacle handling where supported.

Validation should determine:

* whether every declared connection has a corresponding traversable edge;
* whether important map areas are reachable;
* whether roads terminate correctly;
* whether edge tiles match adjacent-map expectations.

### Success criterion

Generate a map with one or more working edge connections and a traversable road to its main feature.

## Phase 8 — Templates and compositional generation

**Status: planned**

Once primitives and object placement work, add reusable templates.

This phase owns richer composition deferred from Phase 4B, including nested patterns, shape-based definitions, complex automatic rotation, and multi-level template composition.

Possible templates:

```text
small cabin
large house
shop
warehouse
crossroads
road bend
pond
farm plot
forest clearing
camp
ruin
village square
```

Templates should be:

* parameterized;
* deterministic;
* validated independently;
* composable;
* able to expose anchors such as entrances, road connections, floors, roofs, and vertical transitions;
* able to contain level-relative sections using `dz` offsets;
* validated across their complete three-dimensional extent before placement.

Example:

```json
{
  "placements": [
    {
      "template": "village_square",
      "origin": {
        "at": [16, 16],
        "z": 0
      },
      "rotation": 0
    },
    {
      "template": "small_house",
      "anchor": "square.north",
      "entrance_facing": "south"
    }
  ]
}
```

Multi-level templates should describe relative level sections rather than embedding absolute level-array indices:

```json
{
  "template": "small_cabin",
  "levels": [
    {"dz": 0, "operations": []},
    {"dz": 1, "operations": []},
    {"dz": 2, "operations": []}
  ]
}
```

Placement resolves each section with `absolute z = origin z + dz`. Rotation must transform horizontal offsets and transition orientation without changing `dz`.

### Success criterion

Create a small settlement by composing templates rather than manually specifying every wall, road, object, and populated level. Templates can include validated multi-level structures and expose usable horizontal and vertical anchors.

## Phase 9 — Semantic map recipes

**Status: long-term target**

At this point the agent should be able to write recipes in terms of design intent:

```json
{
  "biome": "temperate_forest",
  "layout": {
    "type": "small_settlement",
    "entry": "west",
    "center": "village_square"
  },
  "requirements": [
    "three houses",
    "one workshop",
    "a pond southeast of the square",
    "a road connecting west and east",
    "dense trees around the outer border"
  ]
}
```

The generator or a planning layer would translate those requirements into:

* anchors;
* templates;
* primitives;
* logical levels and vertical transitions;
* placement constraints;
* routing;
* validation.

This may eventually involve two distinct stages:

```text
High-level design
       ↓
Expanded concrete recipe
       ↓
Map generator
       ↓
Map JSON
```

Keeping planning separate from final generation would make failures easier to inspect.

## Phase 10 — Quality and gameplay validation

**Status: long-term requirement**

Structural validity is not enough. Generated maps eventually need higher-level checks:

* all required locations and occupied floors are reachable;
* edge connections are usable;
* doors are not blocked;
* buildings have interiors;
* every vertical transition has a valid destination;
* stairs, ramps, and transition endpoints are not blocked;
* upper geometry has valid support according to established runtime rules;
* no feature intersects incompatible geometry above or below;
* roofs and ceilings do not occupy walkable interior cells incorrectly;
* required underground sections have a route to the surface;
* all generated logical elevations remain within `-10` through `+10`;
* paths do not end unexpectedly;
* important objects are accessible;
* no impossible overlaps occur;
* minimum walkable-space requirements are met;
* map density remains within useful ranges;
* visual variety is adequate;
* deterministic regeneration works.

Some checks can be implemented in Python. Others may need Godot or project runtime logic.

### Final success criterion

An agent can create a new playable, potentially multi-level map from a concise design request, run all relevant checks, and produce a map that needs refinement rather than structural repair.

---

# Recommended immediate next task

The next contribution should begin **Phase 4C vertical-level schema and 3D placement foundations**.

First inspect the runtime, content editor, tile definitions, and representative existing maps to document the authoritative logical-z, slope, stair, support, and transition behavior. Use logical `z` values from `-10` through `+10`, map `z: 0` to level-array index `10`, and keep `[x, y]` as the top-down coordinate format.

Then add the smallest backwards-compatible multi-level recipe contract: omitted `z` continues targeting logical level `0`; explicit per-level content can populate additional levels; every populated level contains exactly 1024 entries; unused levels remain `[]`; and all existing operations and pattern invocations use the same level-aware placement path. Reject ambiguous duplicate level definitions, invalid z values, and expansions outside horizontal or vertical bounds.

Keep this contribution focused on terrain and structural generation. Do not add furniture, semantic areas, buildings, roads, towns, nested patterns, or broad gameplay validation. Do not invent support rules that are not confirmed by the runtime.

Add focused tests for z/index conversion, legacy compatibility, multiple populated levels, determinism and RNG ordering across levels, per-level operation ordering, invalid and duplicate z definitions, horizontal and vertical bounds, exact level sizes, and unused-level preservation. Generate one two-level hill and one two-level depression, validate both maps, inspect them in the content editor, verify traversal in Godot, and run `git diff --check`.

Do not commit or push unless explicitly requested.

---

# Current position in one view

```text
[Complete] Hermes-compatible repository guidance
[Complete] Existing map sanitation
[Complete] Fixed-size map validation
[Complete] Minimal JSON recipe format
[Complete] Deterministic 32×32 generator
[Complete] Base tile and rectangle overlays
[Complete] General tile-placement primitives
[Complete] Manual example generation and evaluation harness
[Complete] Generator and validator test suite
[Complete] Documentation and recognizable outdoor example
[Complete] Development moved to snipercup/CataX

[Complete] Palettes, reusable cell patterns, and deterministic variation
[Next]     Vertical-level schema and 3D placement foundations
[Planned]  Features and furniture
[Planned]  Level-aware areas and buildings
[Planned]  Roads and map connections
[Planned]  Multi-level reusable templates and richer composition
[Planned]  Semantic map planning
[Planned]  3D connectivity and gameplay validation
[Target]   Agent-generated playable maps
```

You are no longer experimenting with whether maps can be generated safely. That part is established. The project is now at the point of expanding the generator’s vocabulary until it can express an actual location.

