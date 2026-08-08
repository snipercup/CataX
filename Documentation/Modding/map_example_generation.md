# Manual example-map generation

`Tools/generate_map_examples.py` generates deterministic variants of maintained map recipes for manual inspection. It delegates map construction, validation, overwrite protection, and atomic publication to `Tools/map_generator.py`; it does not contain a second generator implementation.

Run all commands from the repository root. On the standard Hermes host checkout:

```bash
cd ~/local/dimensionfall/repository
```

## Generate one maintained recipe directly into the mod

Use `Tools/map_generator.py` when you want to select one recipe, preserve its map ID, and publish exactly one map directly into the Dimensionfall mod:

```bash
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_two_level_hill.json \
  Mods/Dimensionfall/Maps/generated_two_level_hill.json
```

The maintained recipe examples are:

| Recipe | Output map | Purpose |
|---|---|---|
| `Tools/examples/map_recipe.json` | `Mods/Dimensionfall/Maps/generated_meadow_prototype.json` | Ground-level palettes, placement operations, scatter, and reusable patterns. |
| `Tools/examples/map_recipe_furniture_outdoor.json` | `Mods/Dimensionfall/Maps/generated_furnished_clearing.json` | Explicit decor plus weighted, conflict-aware tree, rock, and wild-vegetation scatter on supported terrain at logical `z: 0`. |
| `Tools/examples/map_recipe_area_meadow.json` | `Mods/Dimensionfall/Maps/generated_area_meadow.json` | One runtime area definition and a `12×12` terrain-backed `area_rectangle` membership boundary at logical `z: 0`. |
| `Tools/examples/map_recipe_area_entity_clearing.json` | `Mods/Dimensionfall/Maps/generated_area_entity_clearing.json` | A `12×12` terrain-backed area whose weighted stump entity is selected anew by the runtime each time the map is instanced. |
| `Tools/examples/map_recipe_room_semantics.json` | `Mods/Dimensionfall/Maps/generated_room_semantics.json` | Authored `enclosed`, `covered_open`, and `ruin` room labels on terrain without generated walls, doors, roofs, or indoor runtime behavior. |
| `Tools/examples/map_recipe_room_connections.json` | `Mods/Dimensionfall/Maps/generated_room_connections.json` | Existing `door_wood` features with explicit room-to-exterior and room-to-room semantic links, without inferred topology or new runtime door behavior. |
| `Tools/examples/map_recipe_room_boundaries.json` | `Mods/Dimensionfall/Maps/generated_room_boundaries.json` | Existing `brick_wall_00` tiles and connected `door_wood` features explicitly attached to rooms without generated geometry or enclosure-completeness rules. |
| `Tools/examples/map_recipe_two_level_hill.json` | `Mods/Dimensionfall/Maps/generated_two_level_hill.json` | Ground level `z: 0`, raised terrain at `z: 1`, and all four slope rotations. |
| `Tools/examples/map_recipe_two_level_depression.json` | `Mods/Dimensionfall/Maps/generated_two_level_depression.json` | Ground level `z: 0`, lowered terrain at `z: -1`, and all four slope rotations. |

For both multi-level examples, slope rotations use the map editor convention: `0` has its high edge north, `90` east, `180` south, and `270` west. The generator writes those values directly; Godot performs the slope-specific runtime conversion when loading a newly generated map.

When manually testing either multi-level example, check every slope from both directions:

1. approach from the lower-level side;
2. walk up the visible slope and onto the high-side tile;
3. turn around and walk back down;
4. confirm there is no invisible wall or collision plane with a different orientation;
5. repeat for north, east, south, and west high edges.

Automated GUT coverage verifies that conversion, rendering vertices, collision geometry, and navigation-source faces agree on each high edge. A focused integration test also performs the asynchronous bake and verifies bidirectional navigation paths across every orientation. Manual playtesting of the maintained hill and depression has confirmed that the real player controller can walk up and down all four orientations without traversal or invisible-collision problems. Repeat the checklist after changing slope geometry, collision, navigation settings, or player movement behavior.

Copy the corresponding command for the map you want to inspect:

```bash
# Ground-level meadow
python3 Tools/map_generator.py \
  Tools/examples/map_recipe.json \
  Mods/Dimensionfall/Maps/generated_meadow_prototype.json

# Ground-level furnished clearing
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_furniture_outdoor.json \
  Mods/Dimensionfall/Maps/generated_furnished_clearing.json

# Ground-level runtime area meadow
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_area_meadow.json \
  Mods/Dimensionfall/Maps/generated_area_meadow.json

# Ground-level runtime-random area entity clearing
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_area_entity_clearing.json \
  Mods/Dimensionfall/Maps/generated_area_entity_clearing.json

# Ground-level authored room semantics
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_room_semantics.json \
  Mods/Dimensionfall/Maps/generated_room_semantics.json

# Ground-level authored room connections
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_room_connections.json \
  Mods/Dimensionfall/Maps/generated_room_connections.json

# Ground-level authored room boundaries
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_room_boundaries.json \
  Mods/Dimensionfall/Maps/generated_room_boundaries.json

# Two-level hill
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_two_level_hill.json \
  Mods/Dimensionfall/Maps/generated_two_level_hill.json

# Two-level depression
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_two_level_depression.json \
  Mods/Dimensionfall/Maps/generated_two_level_depression.json
```

The output filename should match the recipe's `id`, followed by `.json`. The generator validates the map before publishing it and refuses to replace an existing file. To deliberately regenerate the same map after editing its recipe, add `--overwrite`:

```bash
python3 Tools/map_generator.py \
  Tools/examples/map_recipe_two_level_hill.json \
  Mods/Dimensionfall/Maps/generated_two_level_hill.json \
  --overwrite
```

After generating a map, start or restart Godot and follow the content-editor steps below. Files created directly with `map_generator.py` are not registered in the example runner's cleanup manifest. Remove them explicitly when manual testing is complete:

```bash
rm Mods/Dimensionfall/Maps/generated_meadow_prototype.json
rm Mods/Dimensionfall/Maps/generated_furnished_clearing.json
rm Mods/Dimensionfall/Maps/generated_area_meadow.json
rm Mods/Dimensionfall/Maps/generated_area_entity_clearing.json
rm Mods/Dimensionfall/Maps/generated_room_semantics.json
rm Mods/Dimensionfall/Maps/generated_room_connections.json
rm Mods/Dimensionfall/Maps/generated_room_boundaries.json
rm Mods/Dimensionfall/Maps/generated_two_level_hill.json
rm Mods/Dimensionfall/Maps/generated_two_level_depression.json
```

Only run the removal command for a file you actually generated. These maintained IDs are intended for development examples; do not overwrite a map with the same ID if it has been repurposed as project content.

## Safe first run

Generate three variants in a temporary directory:

```bash
python3 Tools/generate_map_examples.py \
  --output-dir /tmp/dimensionfall-map-examples
```

The default recipe is `Tools/examples/map_recipe.json`. Each variant receives:

- a unique ID and matching filename ending in `_example_001`, `_example_002`, and so on;
- a sequential seed, beginning with the recipe's seed unless `--seed` is supplied;
- complete 32 x 32 map data validated before publication.

Inspect the generated files with the validator if desired:

```bash
python3 Tools/map_validator.py /tmp/dimensionfall-map-examples
```

## Choose the number of variants and starting seed

Generate five reproducible variants using seeds `1000` through `1004`:

```bash
python3 Tools/generate_map_examples.py \
  --output-dir /tmp/dimensionfall-map-examples \
  --variants 5 \
  --seed 1000
```

Running the same complete recipe with the same starting seed produces the same map JSON. Changing the seed changes seeded tile scatter, furniture scatter, palette selection, and random rotations.

## Inspect generated maps in the content editor

Place examples in the core mod's map directory:

```bash
python3 Tools/generate_map_examples.py \
  --output-dir Mods/Dimensionfall/Maps \
  --variants 3 \
  --seed 1000
```

Launch Godot after generation and run the Dimensionfall project.
In the running project, navigate to:

```text
Content Manager
  → Content Editor
  → select the Dimensionfall mod
  → Expand the Maps category if it is still collapsed
  → open a generated map by doubleclicking it in the map list
  → View Map in the editor, click `save and test` to test it manually
```

If Godot was already running when files were generated, restart it so mod content is loaded again. The existing map-editor preview displays generated map JSON; the Python tool does not create a separate image or HTML preview.

For the maintained furnished clearing, confirm that the editor shows a garden bench at `[16, 16]`, an unlit campfire at `[15, 16]`, and a potted plant at `[17, 16]`. It deterministically scatters 24 trees or burned stumps, then 16 rocks or wild-vegetation features, over the 16×16 clearing while leaving those three authored features untouched. The maintainer inspected the clearing in the editor with `save and test` after the dedicated AI sprites were installed and confirmed that the rock and wild-vegetation furniture spawn without issues. `rock_field_00` uses `ai_rock_32_32.png`, and `wild_vegetation_00` uses `ai_vegetation_32_32.png`. The recipe intentionally leaves `itemgroups` empty and does not exercise container contents, multi-cell occupancy, or cross-level support rules.

For the maintained area meadow, confirm that the area list contains `meadow_clearing` and the editor highlights exactly the `12×12` rectangle from `[10, 10]` through `[21, 21]` at logical `z: 0`. The definition has a `100` percent spawn chance and replaces that connected membership cluster with `grass_dirt_00`; use `save and test` to confirm the runtime applies the area without affecting outside terrain. The example deliberately contains no entities, rooms, walls, doors, or building semantics.

For the maintained area entity clearing, confirm the same `[10, 10]` through `[21, 21]` membership boundary for `stump_clearing`. The JSON deliberately contains no pre-baked furniture features: every instancing uses the established area rule to make a fresh weighted selection between its `burned_tree_stump` entry and the implicit no-spawn weight. Restart and instance the map multiple times with **save and test**; confirm stump positions can vary between runs, remain inside the membership boundary, preserve the membership rotation when spawned, and never alter outside terrain. Do not commit the generated inspection map unless it is explicitly promoted to project content.

For the maintained room-semantics map, inspect `generated_room_semantics` in the content editor, save it, close it, and re-open it. Confirm that `office` (`enclosed`), `garage_bay` (`covered_open`), and `ruined_store` (`ruin`) labels persist without load errors. The office and garage intentionally share adjacent `concrete_00` terrain, so do not infer room boundaries from floor material. Map preview and **save and test** should only be used to confirm persistence and normal loading in this slice: it does not yet create walls, roofs, doors, lighting, weather, or indoor gameplay behavior.

For the maintained room-connections map, open `generated_room_connections`, save it, close it, and re-open it. Confirm that `office_front_door` remains an `office`→`exterior` link and `office_to_garage` remains an `office`→`garage_bay` link. In map preview and **save and test**, verify both existing `door_wood` features load and retain normal open/close interaction. This metadata must not create walls, roofs, lighting, weather, automatic enclosure, or a different door runtime behavior.

For the maintained room-boundaries map, open `generated_room_boundaries`, save it, close it, and re-open it. Confirm the four existing `brick_wall_00` cells and both existing `door_wood` features remain present, and that the root `room_boundaries` list persists with four `wall_tile` and three `door_furniture` records. The garage and ruin deliberately do not declare full perimeters; **save and test** should confirm normal loading and existing door interaction only, not new enclosure, collision, navigation, lighting, weather, or indoor behavior.

Dimensionfall also looks for a same-named `.png` map sprite during startup. The runner intentionally generates map JSON only, so Godot currently logs a non-fatal missing-resource error for that sprite. This does not prevent the JSON map from loading or the map editor's tile-grid preview from rendering it.

## Generate from specific recipes

Pass one or more recipe paths before the options. The runner generates the requested number of variants for every recipe:

```bash
python3 Tools/generate_map_examples.py \
  Tools/examples/map_recipe.json \
  --output-dir /tmp/dimensionfall-map-examples \
  --variants 2 \
  --seed 500
```

For example, generate one cleanup-managed hill and one cleanup-managed depression directly in the mod folder:

```bash
python3 Tools/generate_map_examples.py \
  Tools/examples/map_recipe_two_level_hill.json \
  Tools/examples/map_recipe_two_level_depression.json \
  --output-dir Mods/Dimensionfall/Maps \
  --variants 1
```

This produces:

```text
Mods/Dimensionfall/Maps/generated_two_level_hill_example_001.json
Mods/Dimensionfall/Maps/generated_two_level_depression_example_001.json
```

Use `map_generator.py` for one exact recipe output. Use `generate_map_examples.py` when you want multiple seeds, multiple recipes in one command, or manifest-based cleanup.

Use different tile and furniture databases when testing another mod's furniture recipe:

```bash
python3 Tools/generate_map_examples.py \
  path/to/recipe.json \
  --output-dir /tmp/dimensionfall-map-examples \
  --tiles path/to/Tiles.json
```

The example runner infers `Furniture/Furniture.json` beside the selected `Tiles` directory. For a one-map invocation whose furniture database lives elsewhere, use `Tools/map_generator.py --furniture path/to/Furniture.json`.

## Overwrite protection

Existing output files are protected by default. A repeated command using the same IDs reports an error instead of replacing them.

To deliberately regenerate those files, add `--overwrite`:

```bash
python3 Tools/generate_map_examples.py \
  --output-dir /tmp/dimensionfall-map-examples \
  --variants 3 \
  --seed 1000 \
  --overwrite
```

An overwritten file that was not originally created by this runner is not claimed by its cleanup manifest and will not be deleted by `--clean`.

## Safe cleanup

The runner records newly created output filenames and SHA-256 digests in:

```text
.dimensionfall-map-examples-manifest
```

The manifest has no `.json` extension, so it is not treated as a map. Cleanup removes only recorded map files whose contents still match their generated SHA-256 digest:

```bash
python3 Tools/generate_map_examples.py \
  --output-dir /tmp/dimensionfall-map-examples \
  --clean
```

Remove examples installed for editor inspection with:

```bash
python3 Tools/generate_map_examples.py \
  --output-dir Mods/Dimensionfall/Maps \
  --clean
```

Unrelated maps in the output directory are left untouched. A generated path that has since been changed or replaced is also preserved. If the manifest is missing, cleanup removes nothing. If it is malformed, cleanup stops rather than guessing which files are safe to delete.

## Useful checks

Show all command options:

```bash
python3 Tools/generate_map_examples.py --help
```

Run the focused Godot slope geometry and baked-navigation regression suites:

```bash
godot --headless --path . \
  -s addons/gut/gut_cmdln.gd \
  -gtest=Tests/Unit/test_chunk_slope_rotation.gd \
  -gtest=Tests/Unit/test_chunk_slope_navigation.gd \
  -gexit
```

Validate all generated maps in a temporary output directory:

```bash
python3 Tools/map_validator.py /tmp/dimensionfall-map-examples
```

Confirm generated map dimensions and populated levels:

```bash
python3 - <<'PY'
import json
from pathlib import Path

for path in sorted(Path("/tmp/dimensionfall-map-examples").glob("*.json")):
    data = json.loads(path.read_text(encoding="utf-8"))
    populated = [index for index, level in enumerate(data["levels"]) if level]
    print(
        path.name,
        f"{data['mapwidth']}x{data['mapheight']}",
        f"ground entries={len(data['levels'][10])}",
        f"populated levels={populated}",
    )
PY
```

## Current limitations

- Variants change the recipe seed; they do not synthesize new recipe operations.
- Generated maps support terrain, explicit known single-cell furniture, deterministic weighted furniture scatter, and runtime-compatible rectangular area memberships at explicit logical levels. Areas can also declare weighted runtime `furniture`, `mob`, `mobgroup`, or `itemgroup` entities, so an area field can vary each time its map is instanced. The maintained clearing uses dedicated AI-generated rock and wild-vegetation sprites. Itemgroup contents, multi-tile or tall features, automatic support inference, polygonal areas, rooms, buildings, semantic roads, and multi-level templates are not supported yet.
- The maps can be inspected with the existing content-editor preview, but the runner does not launch Godot or inject maps into an already-running editor session.
- Installing examples under `Mods/Dimensionfall/Maps` makes them available to the content editor, but does not automatically reference them from overmap-area generation.
