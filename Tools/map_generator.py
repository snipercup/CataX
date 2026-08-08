#!/usr/bin/env python3
"""Generate a Dimensionfall map JSON file from a compact recipe."""

from __future__ import annotations

import argparse
import json
import os
import random
import re
import sys
import tempfile
from pathlib import Path
from typing import Any

try:
    from .map_validator import MapValidator
except ImportError:  # Direct execution from Tools/.
    from map_validator import MapValidator


LEVEL_COUNT = 21
POPULATED_LEVEL_INDEX = 10
MIN_LOGICAL_Z = -POPULATED_LEVEL_INDEX
MAX_LOGICAL_Z = LEVEL_COUNT - POPULATED_LEVEL_INDEX - 1
MAP_WIDTH = 32
MAP_HEIGHT = 32
DEFAULT_CONNECTIONS = {
    "north": "ground",
    "east": "ground",
    "south": "ground",
    "west": "ground",
}
# Recipe rotations use the same editor-facing values stored in map JSON. Keep
# them unchanged here; Chunk.get_block_rotation() applies shape-specific runtime
# conversion when a newly generated map is loaded.
VALID_ROTATIONS = (0, 90, 180, 270)
TILE_FIELDS = {"id", "palette", "rotation"}
PALETTE_FIELDS = {"id", "weight", "rotation"}
FURNITURE_PALETTE_FIELDS = {"id", "weight", "rotation"}
DEFINITION_NAME_PATTERN = re.compile(r"[A-Za-z0-9_-]+")
REGION_FIELDS = {"x", "y", "z", "width", "height", "tile"}
SET_FIELDS = {"type", "x", "y", "z", "tile"}
RECTANGLE_FIELDS = {"type", "x", "y", "z", "width", "height", "tile"}
LINE_FIELDS = {"type", "from", "to", "z", "tile"}
SCATTER_FIELDS = {"type", "region", "z", "tile", "count", "density"}
SCATTER_REGION_FIELDS = {"x", "y", "width", "height"}
PATTERN_CELL_FIELDS = {"at", "tile"}
PATTERN_OPERATION_FIELDS = {"type", "pattern", "at", "z", "rotation"}
FURNITURE_OPERATION_FIELDS = {"type", "x", "y", "z", "id", "rotation"}
FURNITURE_SCATTER_FIELDS = {"type", "region", "z", "palette", "count", "density"}
AREA_RECTANGLE_FIELDS = {"type", "area", "x", "y", "z", "width", "height", "rotation"}
AREA_DEFINITION_FIELDS = {
    "id",
    "spawn_chance",
    "rotate_random",
    "pick_one",
    "tiles",
    "entities",
}
AREA_TILE_FIELDS = {"id", "count"}
AREA_ENTITY_FIELDS = {"id", "type", "count"}
AREA_ENTITY_TYPES = {"furniture", "mob", "mobgroup", "itemgroup"}
ROOM_DEFINITION_FIELDS = {"id", "kind"}
ROOM_KINDS = {"enclosed", "covered_open", "ruin"}
ROOM_RECTANGLE_FIELDS = {"type", "room", "x", "y", "z", "width", "height"}
ROOM_CONNECTION_FIELDS = {"id", "at", "z", "from", "to"}
ROOM_CONNECTION_ENDPOINT_FIELDS = {"kind", "id"}
ROOM_CONNECTION_ENDPOINT_KINDS = {"room", "exterior"}
ROOM_BOUNDARY_FIELDS = {"id", "room", "at", "z", "element"}
ROOM_BOUNDARY_ELEMENTS = {"wall_tile", "door_furniture"}
TILE_OPERATION_TYPES = {"set", "rectangle", "rectangle_outline", "line", "scatter"}
LEVEL_FIELDS = {"z", "base_tile", "regions", "operations"}
RECIPE_FIELDS = {
    "id",
    "name",
    "description",
    "seed",
    "base_tile",
    "palette",
    "furniture_palette",
    "areas",
    "rooms",
    "room_connections",
    "room_boundaries",
    "patterns",
    "regions",
    "operations",
    "levels",
}


class RecipeError(ValueError):
    """Raised when a map recipe is invalid."""


def _validate_unicode(value: str, context: str) -> None:
    try:
        value.encode("utf-8")
    except UnicodeEncodeError as error:
        raise RecipeError(f"{context} must contain valid Unicode") from error


def load_recipe(path: Path) -> dict[str, Any]:
    with Path(path).open(encoding="utf-8") as handle:
        recipe = json.load(handle)
    if not isinstance(recipe, dict):
        raise RecipeError("recipe must be a JSON object")
    return recipe


def write_map(
    recipe_path: Path,
    output_path: Path,
    tiles_path: Path,
    overwrite: bool = False,
    furnitures_path: Path | None = None,
) -> None:
    output_path = Path(output_path)
    if output_path.exists() and not overwrite:
        raise FileExistsError(
            f"output already exists: {output_path}; use --overwrite to replace it"
        )

    generated = generate_map(
        load_recipe(Path(recipe_path)),
        Path(tiles_path),
        furnitures_path=furnitures_path,
    )
    expected_name = f"{generated['id']}.json"
    if output_path.name != expected_name:
        raise RecipeError(
            f"output must be named {expected_name} so the filename matches the map ID"
        )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    serialized = json.dumps(generated, indent="\t", ensure_ascii=False) + "\n"

    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            dir=output_path.parent,
            prefix=f".{output_path.name}.",
            delete=False,
        ) as temporary:
            temporary.write(serialized)
            temporary_path = Path(temporary.name)

        validator = MapValidator()
        validator.validate_map(str(temporary_path))
        if validator.errors:
            raise RecipeError(
                "generated map failed validation: " + "; ".join(validator.errors)
            )

        if overwrite:
            os.replace(temporary_path, output_path)
            temporary_path = None
        else:
            try:
                os.link(temporary_path, output_path)
            except FileExistsError as error:
                raise FileExistsError(
                    f"output already exists: {output_path}; use --overwrite to replace it"
                ) from error
    finally:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)


def _tile_ids(tiles_path: Path) -> set[str]:
    with tiles_path.open(encoding="utf-8") as handle:
        tile_data = json.load(handle)
    if not isinstance(tile_data, list):
        raise RecipeError("tile database must be a JSON array")
    return {
        tile["id"]
        for tile in tile_data
        if isinstance(tile, dict) and isinstance(tile.get("id"), str)
    }


def _wall_tile_ids(tiles_path: Path) -> set[str]:
    with tiles_path.open(encoding="utf-8") as handle:
        tile_data = json.load(handle)
    if not isinstance(tile_data, list):
        raise RecipeError("tile database must be a JSON array")
    return {
        entry["id"]
        for entry in tile_data
        if (
            isinstance(entry, dict)
            and isinstance(entry.get("id"), str)
            and isinstance(entry.get("categories"), list)
            and "Wall" in entry["categories"]
        )
    }


def _furniture_ids(furnitures_path: Path) -> set[str]:
    return _content_ids(furnitures_path, "furniture")


def _door_furniture_ids(furnitures_path: Path) -> set[str]:
    with furnitures_path.open(encoding="utf-8") as handle:
        furniture_data = json.load(handle)
    if not isinstance(furniture_data, list):
        raise RecipeError("furniture database must be a JSON array")
    return {
        entry["id"]
        for entry in furniture_data
        if (
            isinstance(entry, dict)
            and isinstance(entry.get("id"), str)
            and isinstance(entry.get("Function"), dict)
            and isinstance(entry["Function"].get("door"), str)
            and entry["Function"]["door"] != "None"
        )
    }


def _content_ids(content_path: Path, content_name: str) -> set[str]:
    with content_path.open(encoding="utf-8") as handle:
        content_data = json.load(handle)
    if not isinstance(content_data, list):
        raise RecipeError(f"{content_name} database must be a JSON array")
    return {
        entry["id"]
        for entry in content_data
        if isinstance(entry, dict) and isinstance(entry.get("id"), str)
    }


def _contains_furniture_operations(recipe: dict[str, Any]) -> bool:
    if "furniture_palette" in recipe:
        return True
    operation_groups = [recipe.get("operations")]
    levels = recipe.get("levels")
    if isinstance(levels, list):
        operation_groups.extend(
            level.get("operations")
            for level in levels
            if isinstance(level, dict)
        )
    return any(
        isinstance(operation, dict)
        and operation.get("type") in {"furniture", "furniture_scatter"}
        for operations in operation_groups
        if isinstance(operations, list)
        for operation in operations
    )


def _contains_area_entities(recipe: dict[str, Any]) -> bool:
    areas = recipe.get("areas")
    return isinstance(areas, list) and any(
        isinstance(area, dict) and area.get("entities")
        for area in areas
    )


def _validate_furniture_palette_entry(
    entry: Any,
    known_furnitures: set[str],
    context: str,
) -> dict[str, Any]:
    if not isinstance(entry, dict):
        raise RecipeError(f"{context} must be an object")
    unknown_fields = sorted(set(entry) - FURNITURE_PALETTE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    furniture_id = entry.get("id")
    if not isinstance(furniture_id, str) or not furniture_id.strip():
        raise RecipeError(f"{context}.id must be a non-empty string")
    _validate_unicode(furniture_id, f"{context}.id")
    if furniture_id not in known_furnitures:
        raise RecipeError(f"{context}.id references unknown furniture '{furniture_id}'")
    weight = entry.get("weight", 1)
    if type(weight) is not int or weight <= 0:
        raise RecipeError(f"{context}.weight must be a positive integer")
    rotation = entry.get("rotation", 0)
    if rotation != "random" and (
        type(rotation) is not int or rotation not in VALID_ROTATIONS
    ):
        raise RecipeError(f"{context}.rotation must be 0, 90, 180, 270, or 'random'")
    return {"id": furniture_id, "weight": weight, "rotation": rotation}


def _validate_furniture_palette(
    furniture_palette: Any, known_furnitures: set[str]
) -> dict[str, list[dict[str, Any]]]:
    if not isinstance(furniture_palette, dict):
        raise RecipeError("furniture_palette must be an object")
    validated: dict[str, list[dict[str, Any]]] = {}
    for name, entries in furniture_palette.items():
        if not isinstance(name, str) or not name.strip():
            raise RecipeError("furniture palette names must be non-empty strings")
        _validate_unicode(name, f"furniture_palette.{name}")
        if DEFINITION_NAME_PATTERN.fullmatch(name) is None:
            raise RecipeError(
                f"furniture palette name '{name}' may contain only letters, numbers, "
                "underscores, and hyphens"
            )
        if not isinstance(entries, list) or not entries:
            raise RecipeError(f"furniture_palette.{name} must be a non-empty array")
        validated[name] = [
            _validate_furniture_palette_entry(
                entry, known_furnitures, f"furniture_palette.{name}[{index}]"
            )
            for index, entry in enumerate(entries)
        ]
    return validated


def _validate_palette_entry(
    entry: Any,
    known_tiles: set[str],
    context: str,
) -> dict[str, Any]:
    if not isinstance(entry, dict):
        raise RecipeError(f"{context} must be an object")
    unknown_fields = sorted(set(entry) - PALETTE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    tile_spec = {field: entry[field] for field in ("id", "rotation") if field in entry}
    tile_id, rotation = _validate_tile_spec(tile_spec, known_tiles, context)
    weight = entry.get("weight", 1)
    if type(weight) is not int or weight <= 0:
        raise RecipeError(f"{context}.weight must be a positive integer")
    return {"id": tile_id, "rotation": rotation, "weight": weight}


def _validate_palette(
    palette: Any,
    known_tiles: set[str],
) -> dict[str, list[dict[str, Any]]]:
    if not isinstance(palette, dict):
        raise RecipeError("palette must be an object")
    validated: dict[str, list[dict[str, Any]]] = {}
    for name, entries in palette.items():
        if not isinstance(name, str) or not name.strip():
            raise RecipeError("palette names must be non-empty strings")
        _validate_unicode(name, f"palette.{name}")
        if DEFINITION_NAME_PATTERN.fullmatch(name) is None:
            raise RecipeError(
                f"palette name '{name}' may contain only letters, numbers, "
                "underscores, and hyphens"
            )
        if not isinstance(entries, list) or not entries:
            raise RecipeError(f"palette.{name} must be a non-empty array")
        validated[name] = [
            _validate_palette_entry(entry, known_tiles, f"palette.{name}[{index}]")
            for index, entry in enumerate(entries)
        ]
    return validated


def _validate_pattern_offset(value: Any, context: str) -> tuple[int, int]:
    if (
        not isinstance(value, list)
        or len(value) != 2
        or any(type(coordinate) is not int for coordinate in value)
    ):
        raise RecipeError(f"{context} must be a two-integer array")
    return value[0], value[1]


def _validate_patterns(
    patterns: Any,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
) -> dict[str, list[dict[str, Any]]]:
    if not isinstance(patterns, dict):
        raise RecipeError("patterns must be an object")
    validated: dict[str, list[dict[str, Any]]] = {}
    for name, cells in patterns.items():
        if not isinstance(name, str) or not name.strip():
            raise RecipeError("pattern names must be non-empty strings")
        _validate_unicode(name, f"patterns.{name}")
        if DEFINITION_NAME_PATTERN.fullmatch(name) is None:
            raise RecipeError(
                f"pattern name '{name}' may contain only letters, numbers, "
                "underscores, and hyphens"
            )
        if not isinstance(cells, list) or not cells:
            raise RecipeError(f"patterns.{name} must be a non-empty array")
        validated_cells: list[dict[str, Any]] = []
        for index, cell in enumerate(cells):
            context = f"patterns.{name}[{index}]"
            if not isinstance(cell, dict):
                raise RecipeError(f"{context} must be an object")
            unknown_fields = sorted(set(cell) - PATTERN_CELL_FIELDS)
            if unknown_fields:
                raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
            if "at" not in cell:
                raise RecipeError(f"{context}.at is required")
            if "tile" not in cell:
                raise RecipeError(f"{context}.tile is required")
            offset = _validate_pattern_offset(cell["at"], f"{context}.at")
            _validate_tile_spec(
                cell["tile"],
                known_tiles,
                f"{context}.tile",
                allow_empty=True,
                palette=palette,
            )
            validated_cells.append({"at": offset, "tile": cell["tile"]})
        validated[name] = validated_cells
    return validated


def _validate_tile_spec(
    spec: Any,
    known_tiles: set[str],
    context: str,
    *,
    allow_empty: bool = False,
    palette: dict[str, list[dict[str, Any]]] | None = None,
) -> tuple[str | None, int | str]:
    if spec is None and allow_empty:
        return None, 0
    if not isinstance(spec, dict):
        empty_hint = " or null" if allow_empty else ""
        raise RecipeError(f"{context} must be an object{empty_hint}")
    unknown_fields = sorted(set(spec) - TILE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    has_id = "id" in spec
    has_palette = "palette" in spec
    if has_id == has_palette:
        raise RecipeError(f"{context} must define exactly one of id or palette")
    if has_palette:
        if "rotation" in spec:
            raise RecipeError(f"{context}.rotation cannot be used with palette")
        palette_name = spec.get("palette")
        if not isinstance(palette_name, str) or not palette_name.strip():
            raise RecipeError(f"{context}.palette must be a non-empty string")
        _validate_unicode(palette_name, f"{context}.palette")
        if palette is None or palette_name not in palette:
            raise RecipeError(
                f"{context}.palette references unknown palette '{palette_name}'"
            )
        return None, 0
    tile_id = spec.get("id")
    if not isinstance(tile_id, str) or not tile_id.strip():
        raise RecipeError(f"{context}.id must be a non-empty string")
    _validate_unicode(tile_id, f"{context}.id")
    if tile_id not in known_tiles:
        raise RecipeError(f"{context}.id references unknown tile '{tile_id}'")
    rotation = spec.get("rotation", 0)
    if rotation != "random" and (
        type(rotation) is not int or rotation not in VALID_ROTATIONS
    ):
        raise RecipeError(f"{context}.rotation must be 0, 90, 180, 270, or 'random'")
    return tile_id, rotation


def _select_weighted_palette_entry(
    entries: list[dict[str, Any]], rng: random.Random
) -> dict[str, Any]:
    total_weight = sum(entry["weight"] for entry in entries)
    selection = rng.randrange(total_weight)
    cumulative = 0
    for entry in entries:
        cumulative += entry["weight"]
        if selection < cumulative:
            return entry
    return entries[-1]


def _make_tile(
    spec: Any,
    rng: random.Random,
    known_tiles: set[str],
    context: str,
    *,
    allow_empty: bool = False,
    palette: dict[str, list[dict[str, Any]]] | None = None,
) -> dict[str, Any]:
    tile_id, rotation = _validate_tile_spec(
        spec, known_tiles, context, allow_empty=allow_empty, palette=palette
    )
    if isinstance(spec, dict) and "palette" in spec:
        if palette is None:
            raise RecipeError(
                f"{context}.palette references unknown palette '{spec['palette']}'"
            )
        entry = _select_weighted_palette_entry(palette[spec["palette"]], rng)
        tile_id = entry["id"]
        rotation = entry["rotation"]
    if tile_id is None:
        return {}
    if rotation == "random":
        rotation = rng.choice(VALID_ROTATIONS)
    tile: dict[str, Any] = {"id": tile_id}
    if rotation:
        tile["rotation"] = rotation
    return tile


def _coordinate(value: Any, context: str, maximum: int) -> int:
    if type(value) is not int or not 0 <= value < maximum:
        raise RecipeError(f"{context} must be an integer between 0 and {maximum - 1}")
    return value


def _logical_z(value: Any, context: str) -> int:
    if type(value) is not int or not MIN_LOGICAL_Z <= value <= MAX_LOGICAL_Z:
        raise RecipeError(
            f"{context} must be an integer between {MIN_LOGICAL_Z} and {MAX_LOGICAL_Z}"
        )
    return value


def _level_index(logical_z: int) -> int:
    return logical_z + POPULATED_LEVEL_INDEX


def _new_empty_level() -> list[dict[str, Any]]:
    return [{} for _ in range(MAP_WIDTH * MAP_HEIGHT)]


def _get_or_create_level(
    levels: list[list[dict[str, Any]]], logical_z: int
) -> list[dict[str, Any]]:
    index = _level_index(logical_z)
    if not levels[index]:
        levels[index] = _new_empty_level()
    return levels[index]


def _apply_set(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - SET_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    x = _coordinate(operation.get("x"), f"{context}.x", MAP_WIDTH)
    y = _coordinate(operation.get("y"), f"{context}.y", MAP_HEIGHT)
    level[y * MAP_WIDTH + x] = _make_tile(
        operation.get("tile"),
        rng,
        known_tiles,
        f"{context}.tile",
        allow_empty=True,
        palette=palette,
    )


def _rectangle_dimensions(spec: dict[str, Any], context: str) -> dict[str, int]:
    dimensions: dict[str, int] = {}
    for field in ("x", "y", "width", "height"):
        value = spec.get(field)
        minimum = 0 if field in ("x", "y") else 1
        if type(value) is not int or value < minimum:
            qualifier = "non-negative" if minimum == 0 else "positive"
            raise RecipeError(f"{context}.{field} must be a {qualifier} integer")
        dimensions[field] = value
    if (
        dimensions["x"] + dimensions["width"] > MAP_WIDTH
        or dimensions["y"] + dimensions["height"] > MAP_HEIGHT
    ):
        raise RecipeError(f"{context} extends outside the {MAP_WIDTH}x{MAP_HEIGHT} map")
    return dimensions


def _apply_rectangle(
    level: list[dict[str, Any]],
    spec: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    context: str,
    fields: set[str],
) -> None:
    unknown_fields = sorted(set(spec) - fields)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    dimensions = _rectangle_dimensions(spec, context)
    for y in range(dimensions["y"], dimensions["y"] + dimensions["height"]):
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"]):
            level[y * MAP_WIDTH + x] = _make_tile(
                spec.get("tile"),
                rng,
                known_tiles,
                f"{context}.tile",
                allow_empty=True,
                palette=palette,
            )


def _apply_rectangle_outline(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - RECTANGLE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    dimensions = _rectangle_dimensions(operation, context)
    left = dimensions["x"]
    right = left + dimensions["width"] - 1
    top = dimensions["y"]
    bottom = top + dimensions["height"] - 1
    for y in range(top, bottom + 1):
        for x in range(left, right + 1):
            if x in (left, right) or y in (top, bottom):
                level[y * MAP_WIDTH + x] = _make_tile(
                    operation.get("tile"),
                    rng,
                    known_tiles,
                    f"{context}.tile",
                    allow_empty=True,
                    palette=palette,
                )


def _point(value: Any, context: str) -> tuple[int, int]:
    if not isinstance(value, list) or len(value) != 2:
        raise RecipeError(f"{context} must be a two-integer array")
    return (
        _coordinate(value[0], f"{context}[0]", MAP_WIDTH),
        _coordinate(value[1], f"{context}[1]", MAP_HEIGHT),
    )


def _apply_line(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - LINE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    x, y = _point(operation.get("from"), f"{context}.from")
    target_x, target_y = _point(operation.get("to"), f"{context}.to")
    delta_x = abs(target_x - x)
    step_x = 1 if x < target_x else -1
    delta_y = -abs(target_y - y)
    step_y = 1 if y < target_y else -1
    error = delta_x + delta_y
    while True:
        level[y * MAP_WIDTH + x] = _make_tile(
            operation.get("tile"),
            rng,
            known_tiles,
            f"{context}.tile",
            allow_empty=True,
            palette=palette,
        )
        if x == target_x and y == target_y:
            break
        doubled_error = 2 * error
        if doubled_error >= delta_y:
            error += delta_y
            x += step_x
        if doubled_error <= delta_x:
            error += delta_x
            y += step_y


def _apply_scatter(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - SCATTER_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    region = operation.get("region")
    if not isinstance(region, dict):
        raise RecipeError(f"{context}.region must be an object")
    unknown_region_fields = sorted(set(region) - SCATTER_REGION_FIELDS)
    if unknown_region_fields:
        raise RecipeError(
            f"unknown {context}.region field '{unknown_region_fields[0]}'"
        )
    dimensions = _rectangle_dimensions(region, f"{context}.region")
    has_count = "count" in operation
    has_density = "density" in operation
    if has_count == has_density:
        raise RecipeError(f"{context} must define exactly one of count or density")
    area = dimensions["width"] * dimensions["height"]
    if has_count:
        count = operation["count"]
        if type(count) is not int or not 0 <= count <= area:
            raise RecipeError(
                f"{context}.count must be an integer between 0 and {area}"
            )
    else:
        density = operation["density"]
        if type(density) not in (int, float) or not 0 <= density <= 1:
            raise RecipeError(f"{context}.density must be a number between 0 and 1")
        count = int(area * density)
    _validate_tile_spec(
        operation.get("tile"),
        known_tiles,
        f"{context}.tile",
        allow_empty=True,
        palette=palette,
    )
    candidates = [
        y * MAP_WIDTH + x
        for y in range(dimensions["y"], dimensions["y"] + dimensions["height"])
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"])
    ]
    for level_index in rng.sample(candidates, count):
        level[level_index] = _make_tile(
            operation.get("tile"),
            rng,
            known_tiles,
            f"{context}.tile",
            allow_empty=True,
            palette=palette,
        )


def _rotate_offset(x: int, y: int, rotation: int) -> tuple[int, int]:
    if rotation == 90:
        return -y, x
    if rotation == 180:
        return -x, -y
    if rotation == 270:
        return y, -x
    return x, y


def _apply_pattern(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    patterns: dict[str, list[dict[str, Any]]],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - PATTERN_OPERATION_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    pattern_name = operation.get("pattern")
    if not isinstance(pattern_name, str) or not pattern_name.strip():
        raise RecipeError(f"{context}.pattern must be a non-empty string")
    _validate_unicode(pattern_name, f"{context}.pattern")
    if pattern_name not in patterns:
        raise RecipeError(
            f"{context}.pattern references unknown pattern '{pattern_name}'"
        )
    anchor_x, anchor_y = _point(operation.get("at"), f"{context}.at")
    rotation = operation.get("rotation", 0)
    if type(rotation) is not int or rotation not in VALID_ROTATIONS:
        raise RecipeError(f"{context}.rotation must be 0, 90, 180, or 270")

    placements: list[tuple[int, int, Any]] = []
    for index, cell in enumerate(patterns[pattern_name]):
        cell_x, cell_y = cell["at"]
        offset_x, offset_y = _rotate_offset(cell_x, cell_y, rotation)
        x = anchor_x + offset_x
        y = anchor_y + offset_y
        if not 0 <= x < MAP_WIDTH or not 0 <= y < MAP_HEIGHT:
            raise RecipeError(
                f"{context} places patterns.{pattern_name}[{index}] outside the "
                f"{MAP_WIDTH}x{MAP_HEIGHT} map at [{x}, {y}]"
            )
        placements.append((x, y, cell["tile"]))

    for index, (x, y, tile_spec) in enumerate(placements):
        level[y * MAP_WIDTH + x] = _make_tile(
            tile_spec,
            rng,
            known_tiles,
            f"{context}.pattern.{pattern_name}[{index}].tile",
            allow_empty=True,
            palette=palette,
        )


def _apply_furniture(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    known_furnitures: set[str],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - FURNITURE_OPERATION_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    x = _coordinate(operation.get("x"), f"{context}.x", MAP_WIDTH)
    y = _coordinate(operation.get("y"), f"{context}.y", MAP_HEIGHT)
    furniture_id = operation.get("id")
    if not isinstance(furniture_id, str) or not furniture_id.strip():
        raise RecipeError(f"{context}.id must be a non-empty string")
    _validate_unicode(furniture_id, f"{context}.id")
    if furniture_id not in known_furnitures:
        raise RecipeError(
            f"{context}.id references unknown furniture '{furniture_id}'"
        )
    rotation = operation.get("rotation", 0)
    if type(rotation) is not int or rotation not in VALID_ROTATIONS:
        raise RecipeError(f"{context}.rotation must be 0, 90, 180, or 270")
    tile = level[y * MAP_WIDTH + x]
    if not isinstance(tile.get("id"), str) or not tile["id"]:
        raise RecipeError(
            f"{context} requires supporting terrain at [{x}, {y}] on its target level"
        )
    if "feature" in tile:
        raise RecipeError(
            f"{context} conflicts with an existing feature at [{x}, {y}] on its target level"
        )
    tile["feature"] = {
        "type": "furniture",
        "id": furniture_id,
        "rotation": rotation,
        "itemgroups": [],
    }


def _apply_furniture_scatter(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    rng: random.Random,
    furniture_palette: dict[str, list[dict[str, Any]]],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - FURNITURE_SCATTER_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    region = operation.get("region")
    if not isinstance(region, dict):
        raise RecipeError(f"{context}.region must be an object")
    unknown_region_fields = sorted(set(region) - SCATTER_REGION_FIELDS)
    if unknown_region_fields:
        raise RecipeError(
            f"unknown {context}.region field '{unknown_region_fields[0]}'"
        )
    dimensions = _rectangle_dimensions(region, f"{context}.region")
    palette_name = operation.get("palette")
    if not isinstance(palette_name, str) or not palette_name.strip():
        raise RecipeError(f"{context}.palette must be a non-empty string")
    _validate_unicode(palette_name, f"{context}.palette")
    if palette_name not in furniture_palette:
        raise RecipeError(
            f"{context}.palette references unknown furniture palette '{palette_name}'"
        )
    has_count = "count" in operation
    has_density = "density" in operation
    if has_count == has_density:
        raise RecipeError(f"{context} must define exactly one of count or density")
    area = dimensions["width"] * dimensions["height"]
    if has_count:
        count = operation["count"]
        if type(count) is not int or not 0 <= count <= area:
            raise RecipeError(
                f"{context}.count must be an integer between 0 and {area}"
            )
    else:
        density = operation["density"]
        if type(density) not in (int, float) or not 0 <= density <= 1:
            raise RecipeError(f"{context}.density must be a number between 0 and 1")
        count = int(area * density)
    candidates = [
        y * MAP_WIDTH + x
        for y in range(dimensions["y"], dimensions["y"] + dimensions["height"])
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"])
        if isinstance(level[y * MAP_WIDTH + x].get("id"), str)
        and level[y * MAP_WIDTH + x]["id"]
        and "feature" not in level[y * MAP_WIDTH + x]
    ]
    if count > len(candidates):
        raise RecipeError(
            f"{context} requests {count} placements but only {len(candidates)} eligible cells remain"
        )
    for level_index in rng.sample(candidates, count):
        entry = _select_weighted_palette_entry(furniture_palette[palette_name], rng)
        rotation = entry["rotation"]
        if rotation == "random":
            rotation = rng.choice(VALID_ROTATIONS)
        level[level_index]["feature"] = {
            "type": "furniture",
            "id": entry["id"],
            "rotation": rotation,
            "itemgroups": [],
        }


def _validate_recipe_areas(
    areas: Any,
    known_tiles: set[str],
    known_area_entity_ids: dict[str, set[str]],
) -> list[dict[str, Any]]:
    if not isinstance(areas, list):
        raise RecipeError("areas must be an array")
    validated: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for index, area in enumerate(areas):
        context = f"areas[{index}]"
        if not isinstance(area, dict):
            raise RecipeError(f"{context} must be an object")
        unknown_fields = sorted(set(area) - AREA_DEFINITION_FIELDS)
        if unknown_fields:
            raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
        missing_fields = sorted(AREA_DEFINITION_FIELDS - set(area))
        if missing_fields:
            raise RecipeError(f"{context} is missing required field '{missing_fields[0]}'")
        area_id = area["id"]
        if not isinstance(area_id, str) or not area_id.strip():
            raise RecipeError(f"{context}.id must be a non-empty string")
        _validate_unicode(area_id, f"{context}.id")
        if DEFINITION_NAME_PATTERN.fullmatch(area_id) is None:
            raise RecipeError(
                f"{context}.id may contain only letters, numbers, underscores, and hyphens"
            )
        if area_id in seen_ids:
            raise RecipeError(f"duplicate area ID '{area_id}'")
        seen_ids.add(area_id)
        if type(area["spawn_chance"]) is not int or not 0 <= area["spawn_chance"] <= 100:
            raise RecipeError(f"{context}.spawn_chance must be an integer between 0 and 100")
        for field in ("rotate_random", "pick_one"):
            if type(area[field]) is not bool:
                raise RecipeError(f"{context}.{field} must be a boolean")
        if not isinstance(area["tiles"], list) or not area["tiles"]:
            raise RecipeError(f"{context}.tiles must be a non-empty array")
        validated_tiles: list[dict[str, Any]] = []
        for tile_index, tile in enumerate(area["tiles"]):
            tile_context = f"{context}.tiles[{tile_index}]"
            if not isinstance(tile, dict):
                raise RecipeError(f"{tile_context} must be an object")
            unknown_tile_fields = sorted(set(tile) - AREA_TILE_FIELDS)
            if unknown_tile_fields:
                raise RecipeError(f"unknown {tile_context} field '{unknown_tile_fields[0]}'")
            if set(tile) != AREA_TILE_FIELDS:
                raise RecipeError(f"{tile_context} must define id and count")
            tile_id = tile["id"]
            if not isinstance(tile_id, str) or not tile_id.strip():
                raise RecipeError(f"{tile_context}.id must be a non-empty string")
            if tile_id != "null" and tile_id not in known_tiles:
                raise RecipeError(f"{tile_context}.id references unknown tile '{tile_id}'")
            if type(tile["count"]) is not int or tile["count"] <= 0:
                raise RecipeError(f"{tile_context}.count must be a positive integer")
            validated_tiles.append({"id": tile_id, "count": tile["count"]})
        if not isinstance(area["entities"], list):
            raise RecipeError(f"{context}.entities must be an array")
        validated_entities: list[dict[str, Any]] = []
        for entity_index, entity in enumerate(area["entities"]):
            entity_context = f"{context}.entities[{entity_index}]"
            if not isinstance(entity, dict):
                raise RecipeError(f"{entity_context} must be an object")
            unknown_entity_fields = sorted(set(entity) - AREA_ENTITY_FIELDS)
            if unknown_entity_fields:
                raise RecipeError(f"unknown {entity_context} field '{unknown_entity_fields[0]}'")
            if set(entity) != AREA_ENTITY_FIELDS:
                raise RecipeError(f"{entity_context} must define id, type, and count")
            if not isinstance(entity["id"], str) or not entity["id"].strip():
                raise RecipeError(f"{entity_context}.id must be a non-empty string")
            if not isinstance(entity["type"], str) or not entity["type"].strip():
                raise RecipeError(f"{entity_context}.type must be a non-empty string")
            entity_type = entity["type"]
            if entity_type not in AREA_ENTITY_TYPES:
                raise RecipeError(f"{entity_context}.type has unsupported type '{entity_type}'")
            entity_id = entity["id"]
            if entity_id not in known_area_entity_ids[entity_type]:
                raise RecipeError(
                    f"{entity_context}.id references unknown {entity_type} '{entity_id}'"
                )
            if type(entity["count"]) is not int or entity["count"] <= 0:
                raise RecipeError(f"{entity_context}.count must be a positive integer")
            validated_entities.append(
                {"id": entity_id, "type": entity_type, "count": entity["count"]}
            )
        validated.append(
            {
                "id": area_id,
                "spawn_chance": area["spawn_chance"],
                "rotate_random": area["rotate_random"],
                "pick_one": area["pick_one"],
                "tiles": validated_tiles,
                "entities": validated_entities,
            }
        )
    return validated


def _validate_recipe_rooms(rooms: Any) -> list[dict[str, str]]:
    if not isinstance(rooms, list):
        raise RecipeError("rooms must be an array")
    validated: list[dict[str, str]] = []
    seen_ids: set[str] = set()
    for index, room in enumerate(rooms):
        context = f"rooms[{index}]"
        if not isinstance(room, dict):
            raise RecipeError(f"{context} must be an object")
        unknown_fields = sorted(set(room) - ROOM_DEFINITION_FIELDS)
        if unknown_fields:
            raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
        if set(room) != ROOM_DEFINITION_FIELDS:
            raise RecipeError(f"{context} must define id and kind")
        room_id = room["id"]
        if not isinstance(room_id, str) or not room_id.strip():
            raise RecipeError(f"{context}.id must be a non-empty string")
        _validate_unicode(room_id, f"{context}.id")
        if DEFINITION_NAME_PATTERN.fullmatch(room_id) is None:
            raise RecipeError(
                f"{context}.id may contain only letters, numbers, underscores, and hyphens"
            )
        if room_id in seen_ids:
            raise RecipeError(f"duplicate room ID '{room_id}'")
        seen_ids.add(room_id)
        kind = room["kind"]
        if not isinstance(kind, str) or kind not in ROOM_KINDS:
            raise RecipeError(f"{context}.kind has unsupported kind '{kind}'")
        validated.append({"id": room_id, "kind": kind})
    return validated


def _validate_room_connection_endpoint(
    endpoint: Any, context: str, known_room_ids: set[str]
) -> dict[str, str]:
    if not isinstance(endpoint, dict):
        raise RecipeError(f"{context} must be an object")
    kind = endpoint.get("kind")
    if kind not in ROOM_CONNECTION_ENDPOINT_KINDS:
        raise RecipeError(f"{context}.kind has unsupported kind '{kind}'")
    expected_fields = {"kind", "id"} if kind == "room" else {"kind"}
    unknown_fields = sorted(set(endpoint) - expected_fields)
    if unknown_fields:
        raise RecipeError(f"{context} must define only kind")
    if set(endpoint) != expected_fields:
        raise RecipeError(f"{context} must define {'kind and id' if kind == 'room' else 'only kind'}")
    if kind == "exterior":
        return {"kind": "exterior"}
    room_id = endpoint["id"]
    if not isinstance(room_id, str) or not room_id.strip():
        raise RecipeError(f"{context}.id must be a non-empty string")
    if room_id not in known_room_ids:
        raise RecipeError(f"{context}.id references unknown room '{room_id}'")
    return {"kind": "room", "id": room_id}


def _validate_recipe_room_connections(
    connections: Any, known_room_ids: set[str]
) -> list[dict[str, Any]]:
    if not isinstance(connections, list):
        raise RecipeError("room_connections must be an array")
    validated: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for index, connection in enumerate(connections):
        context = f"room_connections[{index}]"
        if not isinstance(connection, dict):
            raise RecipeError(f"{context} must be an object")
        unknown_fields = sorted(set(connection) - ROOM_CONNECTION_FIELDS)
        if unknown_fields:
            raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
        if set(connection) != ROOM_CONNECTION_FIELDS:
            raise RecipeError(f"{context} must define id, at, z, from, and to")
        connection_id = connection["id"]
        if not isinstance(connection_id, str) or not connection_id.strip():
            raise RecipeError(f"{context}.id must be a non-empty string")
        _validate_unicode(connection_id, f"{context}.id")
        if DEFINITION_NAME_PATTERN.fullmatch(connection_id) is None:
            raise RecipeError(f"{context}.id may contain only letters, numbers, underscores, and hyphens")
        if connection_id in seen_ids:
            raise RecipeError(f"duplicate room connection ID '{connection_id}'")
        seen_ids.add(connection_id)
        at = connection["at"]
        if (
            not isinstance(at, list)
            or len(at) != 2
            or any(type(value) is not int for value in at)
            or not 0 <= at[0] < MAP_WIDTH
            or not 0 <= at[1] < MAP_HEIGHT
        ):
            raise RecipeError(f"{context}.at must be within map bounds as a two-integer array")
        z = connection["z"]
        if type(z) is not int or not MIN_LOGICAL_Z <= z <= MAX_LOGICAL_Z:
            raise RecipeError(f"{context}.z must be an integer from -10 through 10")
        from_endpoint = _validate_room_connection_endpoint(
            connection["from"], f"{context}.from", known_room_ids
        )
        to_endpoint = _validate_room_connection_endpoint(
            connection["to"], f"{context}.to", known_room_ids
        )
        if from_endpoint == to_endpoint:
            raise RecipeError(f"{context} must connect distinct endpoints")
        validated.append({
            "id": connection_id,
            "at": at,
            "z": z,
            "from": from_endpoint,
            "to": to_endpoint,
        })
    return validated


def _validate_room_connection_targets(
    connections: list[dict[str, Any]],
    levels: list[list[dict[str, Any]]],
    door_furniture_ids: set[str],
) -> None:
    seen_targets: set[tuple[int, int, int]] = set()
    for index, connection in enumerate(connections):
        context = f"room_connections[{index}]"
        x, y = connection["at"]
        z = connection["z"]
        target = (z, x, y)
        if target in seen_targets:
            raise RecipeError(f"{context} duplicates door target at z {z} [{x}, {y}]")
        seen_targets.add(target)
        level = levels[_level_index(z)]
        tile = level[y * MAP_WIDTH + x] if level else {}
        feature = tile.get("feature") if isinstance(tile, dict) else None
        if (
            not isinstance(tile.get("id"), str)
            or not tile["id"]
            or not isinstance(feature, dict)
            or feature.get("type") != "furniture"
            or feature.get("id") not in door_furniture_ids
        ):
            raise RecipeError(f"{context} must reference door-capable furniture at z {z} [{x}, {y}]")


def _validate_recipe_room_boundaries(
    boundaries: Any, known_room_ids: set[str]
) -> list[dict[str, Any]]:
    if not isinstance(boundaries, list):
        raise RecipeError("room_boundaries must be an array")
    validated: list[dict[str, Any]] = []
    seen_ids: set[str] = set()
    for index, boundary in enumerate(boundaries):
        context = f"room_boundaries[{index}]"
        if not isinstance(boundary, dict):
            raise RecipeError(f"{context} must be an object")
        unknown_fields = sorted(set(boundary) - ROOM_BOUNDARY_FIELDS)
        if unknown_fields:
            raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
        if set(boundary) != ROOM_BOUNDARY_FIELDS:
            raise RecipeError(f"{context} must define id, room, at, z, and element")
        boundary_id = boundary["id"]
        if not isinstance(boundary_id, str) or not boundary_id.strip():
            raise RecipeError(f"{context}.id must be a non-empty string")
        _validate_unicode(boundary_id, f"{context}.id")
        if DEFINITION_NAME_PATTERN.fullmatch(boundary_id) is None:
            raise RecipeError(f"{context}.id may contain only letters, numbers, underscores, and hyphens")
        if boundary_id in seen_ids:
            raise RecipeError(f"duplicate room boundary ID '{boundary_id}'")
        seen_ids.add(boundary_id)
        room_id = boundary["room"]
        if not isinstance(room_id, str) or not room_id.strip():
            raise RecipeError(f"{context}.room must be a non-empty string")
        if room_id not in known_room_ids:
            raise RecipeError(f"{context}.room references unknown room '{room_id}'")
        at = boundary["at"]
        if (
            not isinstance(at, list)
            or len(at) != 2
            or any(type(value) is not int for value in at)
            or not 0 <= at[0] < MAP_WIDTH
            or not 0 <= at[1] < MAP_HEIGHT
        ):
            raise RecipeError(f"{context}.at must be within map bounds as a two-integer array")
        z = boundary["z"]
        if type(z) is not int or not MIN_LOGICAL_Z <= z <= MAX_LOGICAL_Z:
            raise RecipeError(f"{context}.z must be an integer from -10 through 10")
        element = boundary["element"]
        if element not in ROOM_BOUNDARY_ELEMENTS:
            raise RecipeError(f"{context}.element has unsupported element '{element}'")
        validated.append({
            "id": boundary_id,
            "room": room_id,
            "at": at,
            "z": z,
            "element": element,
        })
    return validated


def _room_connection_names_room(connection: dict[str, Any], room_id: str) -> bool:
    return any(
        endpoint.get("kind") == "room" and endpoint.get("id") == room_id
        for endpoint in (connection["from"], connection["to"])
    )


def _wall_tile_bounds_room(x: int, y: int, room_id: str, level: list[dict[str, Any]]) -> bool:
    for delta_x, delta_y in ((0, -1), (1, 0), (0, 1), (-1, 0)):
        neighbor_x = x + delta_x
        neighbor_y = y + delta_y
        if not 0 <= neighbor_x < MAP_WIDTH or not 0 <= neighbor_y < MAP_HEIGHT:
            continue
        neighbor = level[neighbor_y * MAP_WIDTH + neighbor_x]
        if isinstance(neighbor, dict) and neighbor.get("rooms") == [room_id]:
            return True
    return False


def _validate_room_boundary_targets(
    boundaries: list[dict[str, Any]],
    levels: list[list[dict[str, Any]]],
    wall_tile_ids: set[str],
    door_furniture_ids: set[str],
    room_connections: list[dict[str, Any]],
) -> None:
    seen_room_targets: set[tuple[str, int, int, int]] = set()
    for index, boundary in enumerate(boundaries):
        context = f"room_boundaries[{index}]"
        room_id = boundary["room"]
        x, y = boundary["at"]
        z = boundary["z"]
        target = (room_id, z, x, y)
        if target in seen_room_targets:
            raise RecipeError(f"{context} duplicates boundary target for room '{room_id}' at z {z} [{x}, {y}]")
        seen_room_targets.add(target)
        level = levels[_level_index(z)]
        tile = level[y * MAP_WIDTH + x] if level else {}
        if not isinstance(tile, dict) or not isinstance(tile.get("id"), str) or not tile["id"]:
            raise RecipeError(f"{context} requires existing terrain at z {z} [{x}, {y}]")
        if boundary["element"] == "wall_tile":
            if tile["id"] not in wall_tile_ids:
                raise RecipeError(f"{context} must reference a Wall-category tile at z {z} [{x}, {y}]")
            if not _wall_tile_bounds_room(x, y, room_id, level):
                raise RecipeError(f"{context} wall tile must be cardinally adjacent to room '{room_id}'")
            continue
        feature = tile.get("feature")
        if (
            not isinstance(feature, dict)
            or feature.get("type") != "furniture"
            or feature.get("id") not in door_furniture_ids
        ):
            raise RecipeError(f"{context} must reference door-capable furniture at z {z} [{x}, {y}]")
        if not any(
            connection["at"] == [x, y]
            and connection["z"] == z
            and _room_connection_names_room(connection, room_id)
            for connection in room_connections
        ):
            raise RecipeError(f"{context} must match a room connection for room '{room_id}'")


def _apply_area_rectangle(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    known_area_ids: set[str],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - AREA_RECTANGLE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    area_id = operation.get("area")
    if not isinstance(area_id, str) or not area_id.strip():
        raise RecipeError(f"{context}.area must be a non-empty string")
    if area_id not in known_area_ids:
        raise RecipeError(f"{context}.area references unknown area '{area_id}'")
    dimensions = _rectangle_dimensions(operation, context)
    rotation = operation.get("rotation", 0)
    if type(rotation) is not int or rotation not in VALID_ROTATIONS:
        raise RecipeError(f"{context}.rotation must be 0, 90, 180, or 270")
    for y in range(dimensions["y"], dimensions["y"] + dimensions["height"]):
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"]):
            tile = level[y * MAP_WIDTH + x]
            if not isinstance(tile.get("id"), str) or not tile["id"]:
                raise RecipeError(f"{context} requires supporting terrain at [{x}, {y}]")
            existing_areas = tile.get("areas", [])
            if any(reference.get("id") == area_id for reference in existing_areas):
                raise RecipeError(f"{context} duplicates area '{area_id}' at [{x}, {y}]")
    for y in range(dimensions["y"], dimensions["y"] + dimensions["height"]):
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"]):
            level[y * MAP_WIDTH + x].setdefault("areas", []).append(
                {"id": area_id, "rotation": rotation}
            )


def _apply_room_rectangle(
    level: list[dict[str, Any]],
    operation: dict[str, Any],
    known_room_ids: set[str],
    context: str,
) -> None:
    unknown_fields = sorted(set(operation) - ROOM_RECTANGLE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
    room_id = operation.get("room")
    if not isinstance(room_id, str) or not room_id.strip():
        raise RecipeError(f"{context}.room must be a non-empty string")
    if room_id not in known_room_ids:
        raise RecipeError(f"{context}.room references unknown room '{room_id}'")
    dimensions = _rectangle_dimensions(operation, context)
    for y in range(dimensions["y"], dimensions["y"] + dimensions["height"]):
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"]):
            tile = level[y * MAP_WIDTH + x]
            if not isinstance(tile.get("id"), str) or not tile["id"]:
                raise RecipeError(f"{context} requires supporting terrain at [{x}, {y}]")
            if tile.get("rooms"):
                raise RecipeError(f"{context} duplicates room membership at [{x}, {y}]")
    for y in range(dimensions["y"], dimensions["y"] + dimensions["height"]):
        for x in range(dimensions["x"], dimensions["x"] + dimensions["width"]):
            level[y * MAP_WIDTH + x]["rooms"] = [room_id]


def _target_z(
    spec: dict[str, Any], context: str, inherited_z: int | None
) -> int:
    if inherited_z is not None:
        if "z" in spec:
            raise RecipeError(
                f"{context}.z must be omitted because the enclosing level defines z"
            )
        return inherited_z
    return _logical_z(spec.get("z", 0), f"{context}.z")


def _apply_layout(
    levels: list[list[dict[str, Any]]],
    regions: Any,
    operations: Any,
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    patterns: dict[str, list[dict[str, Any]]],
    known_furnitures: set[str],
    furniture_palette: dict[str, list[dict[str, Any]]],
    known_area_ids: set[str],
    known_room_ids: set[str],
    context_prefix: str = "",
    inherited_z: int | None = None,
) -> None:
    regions_context = f"{context_prefix}regions"
    if not isinstance(regions, list):
        raise RecipeError(f"{regions_context} must be an array")
    for index, region in enumerate(regions):
        context = f"{regions_context}[{index}]"
        if not isinstance(region, dict):
            raise RecipeError(f"{context} must be an object")
        logical_z = _target_z(region, context, inherited_z)
        level = _get_or_create_level(levels, logical_z)
        _apply_rectangle(
            level, region, rng, known_tiles, palette, context, REGION_FIELDS
        )

    operations_context = f"{context_prefix}operations"
    if not isinstance(operations, list):
        raise RecipeError(f"{operations_context} must be an array")
    for index, operation in enumerate(operations):
        context = f"{operations_context}[{index}]"
        if not isinstance(operation, dict):
            raise RecipeError(f"{context} must be an object")
        logical_z = _target_z(operation, context, inherited_z)
        level = _get_or_create_level(levels, logical_z)
        operation_type = operation.get("type")
        if operation_type in TILE_OPERATION_TYPES and "tile" not in operation:
            raise RecipeError(f"{context}.tile is required")
        if operation_type == "set":
            _apply_set(level, operation, rng, known_tiles, palette, context)
        elif operation_type == "rectangle":
            _apply_rectangle(
                level, operation, rng, known_tiles, palette, context, RECTANGLE_FIELDS
            )
        elif operation_type == "rectangle_outline":
            _apply_rectangle_outline(
                level, operation, rng, known_tiles, palette, context
            )
        elif operation_type == "line":
            _apply_line(level, operation, rng, known_tiles, palette, context)
        elif operation_type == "scatter":
            _apply_scatter(level, operation, rng, known_tiles, palette, context)
        elif operation_type == "pattern":
            _apply_pattern(
                level, operation, rng, known_tiles, palette, patterns, context
            )
        elif operation_type == "furniture":
            _apply_furniture(level, operation, known_furnitures, context)
        elif operation_type == "furniture_scatter":
            _apply_furniture_scatter(
                level, operation, rng, furniture_palette, context
            )
        elif operation_type == "area_rectangle":
            _apply_area_rectangle(level, operation, known_area_ids, context)
        elif operation_type == "room_rectangle":
            _apply_room_rectangle(level, operation, known_room_ids, context)
        else:
            raise RecipeError(
                f"{context}.type has unknown operation '{operation_type}'"
            )


def _generate_levels(
    recipe: dict[str, Any],
    rng: random.Random,
    known_tiles: set[str],
    palette: dict[str, list[dict[str, Any]]],
    patterns: dict[str, list[dict[str, Any]]],
    known_furnitures: set[str],
    furniture_palette: dict[str, list[dict[str, Any]]],
    known_area_ids: set[str],
    known_room_ids: set[str],
) -> list[list[dict[str, Any]]]:
    levels: list[list[dict[str, Any]]] = [[] for _ in range(LEVEL_COUNT)]
    if "levels" not in recipe:
        ground_level = _get_or_create_level(levels, 0)
        for index in range(MAP_WIDTH * MAP_HEIGHT):
            ground_level[index] = _make_tile(
                recipe.get("base_tile"),
                rng,
                known_tiles,
                "base_tile",
                palette=palette,
            )
        _apply_layout(
            levels,
            recipe.get("regions", []),
            recipe.get("operations", []),
            rng,
            known_tiles,
            palette,
            patterns,
            known_furnitures,
            furniture_palette,
            known_area_ids,
            known_room_ids,
        )
        return levels

    conflicting_fields = [
        field for field in ("base_tile", "regions", "operations") if field in recipe
    ]
    if conflicting_fields:
        raise RecipeError(
            f"recipe.{conflicting_fields[0]} cannot be combined with recipe.levels"
        )
    level_specs = recipe["levels"]
    if not isinstance(level_specs, list) or not level_specs:
        raise RecipeError("levels must be a non-empty array")

    validated_specs: list[tuple[int, dict[str, Any]]] = []
    seen_z: set[int] = set()
    for index, level_spec in enumerate(level_specs):
        context = f"levels[{index}]"
        if not isinstance(level_spec, dict):
            raise RecipeError(f"{context} must be an object")
        unknown_fields = sorted(set(level_spec) - LEVEL_FIELDS)
        if unknown_fields:
            raise RecipeError(f"unknown {context} field '{unknown_fields[0]}'")
        if "z" not in level_spec:
            raise RecipeError(f"{context}.z is required")
        logical_z = _logical_z(level_spec["z"], f"{context}.z")
        if logical_z in seen_z:
            raise RecipeError(f"{context}.z duplicates logical level {logical_z}")
        seen_z.add(logical_z)
        validated_specs.append((logical_z, level_spec))

    for index, (logical_z, level_spec) in enumerate(validated_specs):
        context = f"levels[{index}]"
        level = _get_or_create_level(levels, logical_z)
        if "base_tile" in level_spec:
            for tile_index in range(MAP_WIDTH * MAP_HEIGHT):
                level[tile_index] = _make_tile(
                    level_spec["base_tile"],
                    rng,
                    known_tiles,
                    f"{context}.base_tile",
                    palette=palette,
                )
        _apply_layout(
            levels,
            level_spec.get("regions", []),
            level_spec.get("operations", []),
            rng,
            known_tiles,
            palette,
            patterns,
            known_furnitures,
            furniture_palette,
            known_area_ids,
            known_room_ids,
            context_prefix=f"{context}.",
            inherited_z=logical_z,
        )

    for index, level in enumerate(levels):
        if level and not any(level):
            levels[index] = []
    return levels


def generate_map(
    recipe: dict[str, Any],
    tiles_path: Path,
    *,
    furnitures_path: Path | None = None,
) -> dict[str, Any]:
    """Validate a recipe and return map data matching DMap's saved format."""
    if not isinstance(recipe, dict):
        raise RecipeError("recipe must be a JSON object")
    unknown_fields = sorted(set(recipe) - RECIPE_FIELDS)
    if unknown_fields:
        raise RecipeError(f"unknown recipe field '{unknown_fields[0]}'")

    required_strings = ("id", "name", "description")
    for field in required_strings:
        if not isinstance(recipe.get(field), str) or not recipe[field].strip():
            raise RecipeError(f"{field} must be a non-empty string")
        _validate_unicode(recipe[field], field)
    if re.fullmatch(r"[A-Za-z0-9_-]+", recipe["id"]) is None:
        raise RecipeError(
            "id may contain only letters, numbers, underscores, and hyphens"
        )

    seed = recipe.get("seed")
    if type(seed) is not int:
        raise RecipeError("seed must be an integer")
    known_tiles = _tile_ids(Path(tiles_path))
    content_root = Path(tiles_path).parent.parent
    known_furnitures: set[str] = set()
    requires_furniture_catalog = (
        _contains_furniture_operations(recipe)
        or _contains_area_entities(recipe)
        or "room_connections" in recipe
        or "room_boundaries" in recipe
    )
    if requires_furniture_catalog:
        if furnitures_path is None:
            furnitures_path = content_root / "Furniture" / "Furniture.json"
        known_furnitures = _furniture_ids(Path(furnitures_path))
    door_furniture_ids: set[str] = set()
    if "room_connections" in recipe or "room_boundaries" in recipe:
        if furnitures_path is None:
            raise RecipeError("room connections or boundaries require a furniture database")
        door_furniture_ids = _door_furniture_ids(Path(furnitures_path))
    wall_tile_ids = _wall_tile_ids(Path(tiles_path)) if "room_boundaries" in recipe else set()
    known_area_entity_ids: dict[str, set[str]] = {
        "furniture": known_furnitures,
        "mob": set(),
        "mobgroup": set(),
        "itemgroup": set(),
    }
    if _contains_area_entities(recipe):
        known_area_entity_ids.update(
            {
                "mob": _content_ids(content_root / "Mobs" / "Mobs.json", "mob"),
                "mobgroup": _content_ids(
                    content_root / "Mobgroups" / "Mobgroups.json", "mobgroup"
                ),
                "itemgroup": _content_ids(
                    content_root / "Itemgroups" / "Itemgroups.json", "itemgroup"
                ),
            }
        )
    palette = _validate_palette(recipe.get("palette", {}), known_tiles)
    furniture_palette = _validate_furniture_palette(
        recipe.get("furniture_palette", {}), known_furnitures
    )
    patterns = _validate_patterns(recipe.get("patterns", {}), known_tiles, palette)
    areas = _validate_recipe_areas(
        recipe.get("areas", []), known_tiles, known_area_entity_ids
    )
    known_area_ids = {area["id"] for area in areas}
    rooms = _validate_recipe_rooms(recipe.get("rooms", []))
    known_room_ids = {room["id"] for room in rooms}
    room_connections = _validate_recipe_room_connections(
        recipe.get("room_connections", []), known_room_ids
    )
    room_boundaries = _validate_recipe_room_boundaries(
        recipe.get("room_boundaries", []), known_room_ids
    )
    rng = random.Random(seed)
    levels = _generate_levels(
        recipe,
        rng,
        known_tiles,
        palette,
        patterns,
        known_furnitures,
        furniture_palette,
        known_area_ids,
        known_room_ids,
    )
    _validate_room_connection_targets(room_connections, levels, door_furniture_ids)
    _validate_room_boundary_targets(
        room_boundaries,
        levels,
        wall_tile_ids,
        door_furniture_ids,
        room_connections,
    )

    generated = {
        "id": recipe["id"],
        "name": recipe["name"],
        "description": recipe["description"],
        "categories": [],
        "weight": 1000,
        "mapwidth": MAP_WIDTH,
        "mapheight": MAP_HEIGHT,
        "levels": levels,
        "connections": DEFAULT_CONNECTIONS.copy(),
    }
    if areas:
        generated["areas"] = areas
    if rooms:
        generated["rooms"] = rooms
    if room_connections:
        generated["room_connections"] = room_connections
    if room_boundaries:
        generated["room_boundaries"] = room_boundaries
    return generated


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("recipe", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--overwrite", action="store_true")
    parser.add_argument(
        "--tiles",
        type=Path,
        default=(
            Path(__file__).resolve().parents[1]
            / "Mods"
            / "Dimensionfall"
            / "Tiles"
            / "Tiles.json"
        ),
        help="tile database path (defaults to the core Dimensionfall tile database)",
    )
    parser.add_argument(
        "--furniture",
        type=Path,
        help=(
            "furniture database path (defaults to Furniture/Furniture.json next "
            "to the selected Tiles directory)"
        ),
    )
    args = parser.parse_args(argv)
    try:
        write_map(
            args.recipe,
            args.output,
            args.tiles,
            args.overwrite,
            args.furniture,
        )
    except (RecipeError, OSError, json.JSONDecodeError) as error:
        parser.exit(2, f"error: {error}\n")
    print(f"Generated {args.output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
