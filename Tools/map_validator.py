import json
import os
import sys
import argparse
from typing import List, Dict, Any, Set

MAP_WIDTH = 32
MAP_HEIGHT = 32
LEVEL_COUNT = 21
POPULATED_LEVEL_TILE_COUNT = MAP_WIDTH * MAP_HEIGHT
ROOM_KINDS = {'enclosed', 'covered_open', 'ruin'}
ROOM_BOUNDARY_VALIDATIONS = {'complete'}
CARDINAL_SIDES = {
    'north': (0, -1),
    'east': (1, 0),
    'south': (0, 1),
    'west': (-1, 0),
}
OPPOSITE_SIDES = {'north': 'south', 'east': 'west', 'south': 'north', 'west': 'east'}
ROOM_CONNECTION_FIELDS = {'id', 'at', 'z', 'from', 'to'}
ROOM_CONNECTION_ENDPOINT_KINDS = {'room', 'exterior'}
ROOM_BOUNDARY_FIELDS = {'id', 'room', 'at', 'z', 'element', 'side'}
ROOM_BOUNDARY_ELEMENTS = {'wall_tile', 'door_furniture'}
BUILDING_FIELDS = {'id', 'rooms', 'footprint', 'z', 'access_validation', 'interior_rooms', 'open_space_rooms', 'room_partition_validation', 'overhead_validation'}
BUILDING_REQUIRED_FIELDS = {'id', 'rooms', 'footprint', 'z'}
BUILDING_ACCESS_VALIDATIONS = {'complete'}
BUILDING_ROOM_PARTITION_VALIDATIONS = {'complete'}
BUILDING_OVERHEAD_VALIDATIONS = {'complete'}
BUILDING_FOOTPRINT_FIELDS = {'x', 'y', 'width', 'height'}
BUILDING_SURFACE_FIELDS = {'id', 'building', 'kind', 'z'}
BUILDING_SURFACE_KINDS = {'roof', 'ceiling'}
BUILDING_COMPOSITION_FIELDS = {'id', 'building', 'required_surfaces'}

class MapValidationError(Exception):
    """Custom exception for map validation errors."""
    pass

class MapValidator:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.files_processed = 0

    def add_error(self, file_path: str, message: str):
        self.errors.append(f"[{file_path}] ERROR: {message}")

    def add_warning(self, file_path: str, message: str):
        self.warnings.append(f"[{file_path}] WARNING: {message}")

    def _door_furniture_ids(self):
        furniture_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            'Mods', 'Dimensionfall', 'Furniture', 'Furniture.json'
        )
        try:
            with open(furniture_path, 'r', encoding='utf-8') as handle:
                furniture_data = json.load(handle)
        except (OSError, json.JSONDecodeError):
            return set()
        if not isinstance(furniture_data, list):
            return set()
        return {
            entry['id']
            for entry in furniture_data
            if (
                isinstance(entry, dict)
                and isinstance(entry.get('id'), str)
                and isinstance(entry.get('Function'), dict)
                and isinstance(entry['Function'].get('door'), str)
                and entry['Function']['door'] != 'None'
            )
        }

    def _wall_tile_ids(self):
        tile_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            'Mods', 'Dimensionfall', 'Tiles', 'Tiles.json'
        )
        try:
            with open(tile_path, 'r', encoding='utf-8') as handle:
                tile_data = json.load(handle)
        except (OSError, json.JSONDecodeError):
            return set()
        if not isinstance(tile_data, list):
            return set()
        return {
            entry['id']
            for entry in tile_data
            if (
                isinstance(entry, dict)
                and isinstance(entry.get('id'), str)
                and isinstance(entry.get('categories'), list)
                and 'Wall' in entry['categories']
            )
        }

    def validate_map(self, file_path: str):
        """Validates a single map JSON file."""
        if not os.path.exists(file_path):
            self.add_error(file_path, "File does not exist.")
            return

        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except json.JSONDecodeError as e:
            self.add_error(file_path, f"Invalid JSON format: {str(e)}")
            return
        except Exception as e:
            self.add_error(file_path, f"Failed to read file: {str(e)}")
            return

        # Skip non-map metadata files like references.json
        if os.path.basename(file_path) == "references.json":
            return

        self.files_processed += 1
        
        # 1. Check Top-Level Required Fields (areas is now optional)
        required_fields = ['id', 'levels']
        for field in required_fields:
            if field not in data:
                self.add_error(file_path, f"Missing required top-level field: '{field}'")
                return # Cannot proceed with deeper validation if core structure is missing

        map_id = data['id']
        levels = data['levels']
        areas = data.get('areas', [])
        if not isinstance(areas, list):
            self.add_error(file_path, "top-level areas must be an array.")
            areas = []
        rooms = data.get('rooms', [])
        if not isinstance(rooms, list):
            self.add_error(file_path, "top-level rooms must be an array.")
            rooms = []
        room_connections = data.get('room_connections', [])
        if not isinstance(room_connections, list):
            self.add_error(file_path, "top-level room_connections must be an array.")
            room_connections = []
        room_boundaries = data.get('room_boundaries', [])
        if not isinstance(room_boundaries, list):
            self.add_error(file_path, "top-level room_boundaries must be an array.")
            room_boundaries = []
        buildings = data.get('buildings', [])
        if not isinstance(buildings, list):
            self.add_error(file_path, "top-level buildings must be an array.")
            buildings = []
        building_surfaces = data.get('building_surfaces', [])
        if not isinstance(building_surfaces, list):
            self.add_error(file_path, "top-level building_surfaces must be an array.")
            building_surfaces = []
        building_compositions = data.get('building_compositions', [])
        if not isinstance(building_compositions, list):
            self.add_error(file_path, "top-level building_compositions must be an array.")
            building_compositions = []

        # 2. Check Optional Metadata Types
        metadata_checks = {
            'name': str,
            'description': str,
            'categories': list,
            'connections': dict,
            'mapwidth': (int, float), # Allow float for potential JSON/Godot parity issues
            'mapheight': (int, float),
            'weight': (int, float)
        }

        for field, expected_type in metadata_checks.items():
            if field in data:
                val = data[field]
                if not isinstance(str(val) if expected_type == str else val, expected_type):
                    self.add_error(file_path, f"Field '{field}' has incorrect type (expected {expected_type})")

        # 3. Enforce the fixed map dimensions used by the loader and editor.
        map_width = data.get('mapwidth', MAP_WIDTH)
        map_height = data.get('mapheight', MAP_HEIGHT)
        if map_width != MAP_WIDTH:
            self.add_error(
                file_path,
                f"Field 'mapwidth': expected {MAP_WIDTH}, actual {map_width}"
            )
        if map_height != MAP_HEIGHT:
            self.add_error(
                file_path,
                f"Field 'mapheight': expected {MAP_HEIGHT}, actual {map_height}"
            )

        # 4. Validate Areas
        area_ids: Set[str] = set()
        for idx, area in enumerate(areas):
            if not isinstance(area, dict):
                self.add_error(file_path, f"Area at index {idx} is not an object.")
                continue
            
            a_id = area.get('id')
            if not a_id:
                self.add_error(file_path, f"Area at index {idx} is missing 'id'.")
            elif a_id in area_ids:
                self.add_error(file_path, f"Duplicate area ID detected: '{a_id}'")
            else:
                area_ids.add(a_id)

            if 'entities' not in area:
                continue
            entities = area['entities']
            if not isinstance(entities, list):
                self.add_error(file_path, f"Area at index {idx} entities must be an array.")
                continue
            for entity_idx, entity in enumerate(entities):
                entity_context = f"Area at index {idx} entity at index {entity_idx}"
                if not isinstance(entity, dict):
                    self.add_error(file_path, f"{entity_context} is not an object.")
                    continue
                for field in ('id', 'type', 'count'):
                    if field not in entity:
                        self.add_error(file_path, f"{entity_context} is missing required field '{field}'.")
                entity_type = entity.get('type')
                if entity_type not in {'furniture', 'mob', 'mobgroup', 'itemgroup'}:
                    self.add_error(file_path, f"{entity_context} has unsupported entity type '{entity_type}'.")
                entity_id = entity.get('id')
                if not isinstance(entity_id, str) or not entity_id:
                    self.add_error(file_path, f"{entity_context} has invalid or missing ID.")
                count = entity.get('count')
                if (
                    isinstance(count, bool)
                    or not isinstance(count, (int, float))
                    or count <= 0
                ):
                    self.add_error(file_path, f"{entity_context} count must be a positive number.")

        room_ids: Set[str] = set()
        for idx, room in enumerate(rooms):
            if not isinstance(room, dict):
                self.add_error(file_path, f"Room at index {idx} is not an object.")
                continue
            unknown_fields = sorted(set(room) - {'id', 'kind', 'boundary_validation'})
            if unknown_fields:
                self.add_error(file_path, f"Room at index {idx} has unknown field '{unknown_fields[0]}'.")
            for field in ('id', 'kind'):
                if field not in room:
                    self.add_error(file_path, f"Room at index {idx} is missing required field '{field}'.")
            room_id = room.get('id')
            if not isinstance(room_id, str) or not room_id:
                self.add_error(file_path, f"Room at index {idx} has invalid or missing ID.")
            elif room_id in room_ids:
                self.add_error(file_path, f"Duplicate room ID detected: '{room_id}'")
            else:
                room_ids.add(room_id)
            kind = room.get('kind')
            if kind not in ROOM_KINDS:
                self.add_error(file_path, f"Room at index {idx} has unsupported room kind '{kind}'.")
            boundary_validation = room.get('boundary_validation')
            if boundary_validation is not None:
                if boundary_validation not in ROOM_BOUNDARY_VALIDATIONS:
                    self.add_error(file_path, f"Room at index {idx} has unsupported boundary validation '{boundary_validation}'.")
                elif kind != 'enclosed':
                    self.add_error(file_path, f"Room at index {idx} boundary validation is only supported for enclosed rooms.")

        validated_room_connections = []
        seen_connection_ids: Set[str] = set()
        for idx, connection in enumerate(room_connections):
            context = f"Room connection at index {idx}"
            if not isinstance(connection, dict):
                self.add_error(file_path, f"{context} is not an object.")
                continue
            unknown_fields = sorted(set(connection) - ROOM_CONNECTION_FIELDS)
            if unknown_fields:
                self.add_error(file_path, f"{context} has unknown field '{unknown_fields[0]}'.")
            for field in ROOM_CONNECTION_FIELDS:
                if field not in connection:
                    self.add_error(file_path, f"{context} is missing required field '{field}'.")
            connection_id = connection.get('id')
            if not isinstance(connection_id, str) or not connection_id:
                self.add_error(file_path, f"{context} has invalid or missing ID.")
            elif connection_id in seen_connection_ids:
                self.add_error(file_path, f"Duplicate room connection ID detected: '{connection_id}'")
            else:
                seen_connection_ids.add(connection_id)
            at = connection.get('at')
            if (
                not isinstance(at, list)
                or len(at) != 2
                or any(type(value) is not int for value in at)
                or not 0 <= at[0] < MAP_WIDTH
                or not 0 <= at[1] < MAP_HEIGHT
            ):
                self.add_error(file_path, f"{context} at must be a two-integer coordinate within map bounds.")
            z = connection.get('z')
            if type(z) is not int or not -10 <= z <= 10:
                self.add_error(file_path, f"{context} z must be an integer from -10 through 10.")
            endpoints = []
            endpoints_valid = True
            for field in ('from', 'to'):
                endpoint = connection.get(field)
                endpoint_context = f"{context} {field} endpoint"
                if not isinstance(endpoint, dict):
                    self.add_error(file_path, f"{endpoint_context} is not an object.")
                    endpoints_valid = False
                    continue
                kind = endpoint.get('kind')
                if kind not in ROOM_CONNECTION_ENDPOINT_KINDS:
                    self.add_error(file_path, f"{endpoint_context} has unsupported kind '{kind}'.")
                    endpoints_valid = False
                    continue
                expected_fields = {'kind', 'id'} if kind == 'room' else {'kind'}
                if set(endpoint) != expected_fields:
                    self.add_error(file_path, f"{endpoint_context} has invalid fields.")
                    endpoints_valid = False
                    continue
                if kind == 'room':
                    room_id = endpoint.get('id')
                    if not isinstance(room_id, str) or not room_id:
                        self.add_error(file_path, f"{endpoint_context} has invalid or missing room ID.")
                        endpoints_valid = False
                    elif room_id not in room_ids:
                        self.add_error(file_path, f"{endpoint_context} references non-existent room '{room_id}'.")
                        endpoints_valid = False
                endpoints.append(endpoint)
            if endpoints_valid and len(endpoints) == 2 and endpoints[0] == endpoints[1]:
                self.add_error(file_path, f"{context} must connect distinct endpoints.")
            if (
                isinstance(connection_id, str) and connection_id
                and isinstance(at, list) and len(at) == 2
                and all(type(value) is int for value in at)
                and 0 <= at[0] < MAP_WIDTH and 0 <= at[1] < MAP_HEIGHT
                and type(z) is int and -10 <= z <= 10
            ):
                validated_room_connections.append(connection)

        validated_room_boundaries = []
        seen_boundary_ids: Set[str] = set()
        for idx, boundary in enumerate(room_boundaries):
            context = f"Room boundary at index {idx}"
            if not isinstance(boundary, dict):
                self.add_error(file_path, f"{context} is not an object.")
                continue
            unknown_fields = sorted(set(boundary) - ROOM_BOUNDARY_FIELDS)
            if unknown_fields:
                self.add_error(file_path, f"{context} has unknown field '{unknown_fields[0]}'.")
            for field in ('id', 'room', 'at', 'z', 'element'):
                if field not in boundary:
                    self.add_error(file_path, f"{context} is missing required field '{field}'.")
            boundary_id = boundary.get('id')
            if not isinstance(boundary_id, str) or not boundary_id:
                self.add_error(file_path, f"{context} has invalid or missing ID.")
            elif boundary_id in seen_boundary_ids:
                self.add_error(file_path, f"Duplicate room boundary ID detected: '{boundary_id}'")
            else:
                seen_boundary_ids.add(boundary_id)
            room_id = boundary.get('room')
            if not isinstance(room_id, str) or not room_id:
                self.add_error(file_path, f"{context} has invalid or missing room ID.")
            elif room_id not in room_ids:
                self.add_error(file_path, f"{context} references non-existent room '{room_id}'.")
            at = boundary.get('at')
            valid_at = (
                isinstance(at, list)
                and len(at) == 2
                and all(type(value) is int for value in at)
                and 0 <= at[0] < MAP_WIDTH
                and 0 <= at[1] < MAP_HEIGHT
            )
            if not valid_at:
                self.add_error(file_path, f"{context} at must be a two-integer coordinate within map bounds.")
            z = boundary.get('z')
            valid_z = type(z) is int and -10 <= z <= 10
            if not valid_z:
                self.add_error(file_path, f"{context} z must be an integer from -10 through 10.")
            element = boundary.get('element')
            if element not in ROOM_BOUNDARY_ELEMENTS:
                self.add_error(file_path, f"{context} has unsupported element '{element}'.")
            side = boundary.get('side')
            if side is not None and side not in CARDINAL_SIDES:
                self.add_error(file_path, f"{context} side must be north, east, south, or west.")
            if (
                isinstance(boundary_id, str) and boundary_id
                and isinstance(room_id, str) and room_id in room_ids
                and valid_at and valid_z and element in ROOM_BOUNDARY_ELEMENTS
                and (side is None or side in CARDINAL_SIDES)
            ):
                validated_room_boundaries.append(boundary)

        # 5. Validate Levels (Tiles)
        if not isinstance(levels, list):
             self.add_error(file_path, "'levels' must be an array.")
        else:
            if len(levels) != LEVEL_COUNT:
                self.add_error(
                    file_path,
                    f"Level count: expected {LEVEL_COUNT}, actual {len(levels)}"
                )
            for level_idx, level in enumerate(levels):
                if not isinstance(level, list):
                    self.add_error(file_path, f"Level {level_idx} is not an array (list).")
                    continue
                
                # Check tile count if level is populated
                if len(level) > 0:
                    if len(level) != POPULATED_LEVEL_TILE_COUNT:
                        self.add_error(
                            file_path,
                            f"Level {level_idx} tile count: expected {POPULATED_LEVEL_TILE_COUNT}, actual {len(level)}"
                        )

                for tile_idx, tile in enumerate(level):
                    if not isinstance(tile, dict):
                        self.add_error(file_path, f"Level {level_idx}, Tile index {tile_idx} is not an object.")
                        continue
                    
                    # Check if the tile is empty (representing air/empty)
                    if not tile:
                        continue

                    # Tile ID Required
                    if 'id' not in tile:
                        self.add_error(file_path, f"Level {level_idx}, Tile index {tile_idx} missing required 'id'")
                        continue

                    if 'rooms' in tile:
                        room_memberships = tile['rooms']
                        if not isinstance(tile['id'], str) or not tile['id']:
                            self.add_error(
                                file_path,
                                f"Level {level_idx}, Tile index {tile_idx} room membership requires terrain."
                            )
                        elif not isinstance(room_memberships, list):
                            self.add_error(
                                file_path,
                                f"Level {level_idx}, Tile '{tile['id']}' rooms must be an array."
                            )
                        elif (
                            len(room_memberships) != 1
                            or not isinstance(room_memberships[0], str)
                            or not room_memberships[0]
                        ):
                            self.add_error(
                                file_path,
                                f"Level {level_idx}, Tile '{tile['id']}' rooms must contain exactly one room ID."
                            )
                        elif room_memberships[0] not in room_ids:
                            self.add_error(
                                file_path,
                                f"Level {level_idx}, Tile '{tile['id']}' references non-existent room '{room_memberships[0]}'"
                            )

                    if 'rotation' in tile:
                        rot = tile['rotation']
                        valid_rots = {0, 90, 180, 270}
                        try:
                            # Handle float equivalents like 90.0
                            float_rot = float(rot) % 360
                            if float_rot not in valid_rots:
                                self.add_error(file_path, f"Level {level_idx}, Tile ID '{tile['id']}' has invalid rotation: {rot}")
                        except (ValueError, TypeError):
                             self.add_error(file_path, f"Level {level_idx}, Tile ID '{tile['id']}' has non-numeric rotation: {rot}")

                    # Furniture is stored as a single feature embedded in a terrain tile.
                    if 'feature' in tile:
                        feature = tile['feature']
                        if not isinstance(feature, dict):
                            self.add_error(
                                file_path,
                                f"Level {level_idx}, Tile ID '{tile['id']}' feature is not an object."
                            )
                        elif feature.get('type') == 'furniture':
                            allowed_fields = {'type', 'id', 'rotation', 'itemgroups'}
                            unknown_fields = sorted(set(feature) - allowed_fields)
                            if unknown_fields:
                                self.add_error(
                                    file_path,
                                    f"Level {level_idx}, Tile ID '{tile['id']}' furniture feature has unknown field '{unknown_fields[0]}'"
                                )
                            furniture_id = feature.get('id')
                            if not isinstance(furniture_id, str) or not furniture_id:
                                self.add_error(
                                    file_path,
                                    f"Level {level_idx}, Tile ID '{tile['id']}' furniture feature has invalid or missing ID"
                                )
                            if 'rotation' in feature:
                                rotation = feature['rotation']
                                valid_feature_rotations = {0, 90, 180, 270}
                                try:
                                    float_rotation = float(rotation) % 360
                                    if float_rotation not in valid_feature_rotations:
                                        self.add_error(
                                            file_path,
                                            f"Level {level_idx}, Furniture ID '{furniture_id}' has invalid rotation: {rotation}"
                                        )
                                except (ValueError, TypeError):
                                    self.add_error(
                                        file_path,
                                        f"Level {level_idx}, Furniture ID '{furniture_id}' has non-numeric rotation: {rotation}"
                                    )
                            if 'itemgroups' in feature and not (
                                isinstance(feature['itemgroups'], list)
                                and all(isinstance(itemgroup, str) for itemgroup in feature['itemgroups'])
                            ):
                                self.add_error(
                                    file_path,
                                    f"Level {level_idx}, Furniture ID '{furniture_id}' itemgroups must be an array of strings"
                                )

                    # Area references use the editor/runtime contract: an array of
                    # {id, rotation?} dictionaries embedded in a terrain tile.
                    if 'areas' in tile:
                        area_references = tile['areas']
                        if not isinstance(area_references, list):
                            self.add_error(
                                file_path,
                                f"Level {level_idx}, Tile '{tile['id']}' areas must be an array."
                            )
                            continue
                        for area_ref in area_references:
                            if not isinstance(area_ref, dict):
                                self.add_error(file_path, f"Level {level_idx}, Tile '{tile['id']}' has malformed area reference.")
                                continue
                            
                            ref_id = area_ref.get('id')
                            if not isinstance(ref_id, str) or not ref_id:
                                self.add_error(file_path, f"Level {level_idx}, Tile '{tile['id']}' references an area without an ID.")
                            elif ref_id not in area_ids:
                                self.add_error(file_path, f"Level {level_idx}, Tile '{tile['id']}' references non-existent area '{ref_id}'")
                            if 'rotation' in area_ref:
                                rotation = area_ref['rotation']
                                valid_area_rotations = {0, 90, 180, 270}
                                try:
                                    float_rotation = float(rotation) % 360
                                    if float_rotation not in valid_area_rotations:
                                        self.add_error(
                                            file_path,
                                            f"Level {level_idx}, Tile '{tile['id']}' has invalid area rotation: {rotation}"
                                        )
                                except (ValueError, TypeError):
                                    self.add_error(
                                        file_path,
                                        f"Level {level_idx}, Tile '{tile['id']}' has non-numeric area rotation: {rotation}"
                                    )

        door_furniture_ids = self._door_furniture_ids() if (validated_room_connections or validated_room_boundaries) else set()
        seen_door_targets: Set[tuple] = set()
        for connection in validated_room_connections:
            x, y = connection['at']
            z = connection['z']
            target = (z, x, y)
            if target in seen_door_targets:
                self.add_error(file_path, f"Room connection '{connection['id']}' duplicates door target at z {z} [{x}, {y}].")
                continue
            seen_door_targets.add(target)
            level_index = z + 10
            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
            tile = level[y * MAP_WIDTH + x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
            feature = tile.get('feature') if isinstance(tile, dict) else None
            if (
                not isinstance(tile, dict)
                or not isinstance(tile.get('id'), str)
                or not tile['id']
                or not isinstance(feature, dict)
                or feature.get('type') != 'furniture'
                or feature.get('id') not in door_furniture_ids
            ):
                self.add_error(file_path, f"Room connection '{connection['id']}' must reference door-capable furniture at z {z} [{x}, {y}].")

        wall_tile_ids = self._wall_tile_ids() if validated_room_boundaries else set()
        seen_boundary_targets: Set[tuple] = set()
        for boundary in validated_room_boundaries:
            room_id = boundary['room']
            x, y = boundary['at']
            z = boundary['z']
            target = (room_id, z, x, y)
            if target in seen_boundary_targets:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' duplicates boundary target for room '{room_id}' at z {z} [{x}, {y}].")
                continue
            seen_boundary_targets.add(target)
            level_index = z + 10
            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
            tile = level[y * MAP_WIDTH + x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
            if not isinstance(tile, dict) or not isinstance(tile.get('id'), str) or not tile['id']:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' requires existing terrain at z {z} [{x}, {y}].")
                continue
            if boundary['element'] == 'wall_tile':
                if tile['id'] not in wall_tile_ids:
                    self.add_error(file_path, f"Room boundary '{boundary['id']}' must reference a Wall-category tile at z {z} [{x}, {y}].")
                    continue
                adjacent_to_room = False
                for delta_x, delta_y in ((0, -1), (1, 0), (0, 1), (-1, 0)):
                    neighbor_x = x + delta_x
                    neighbor_y = y + delta_y
                    if not 0 <= neighbor_x < MAP_WIDTH or not 0 <= neighbor_y < MAP_HEIGHT:
                        continue
                    neighbor = level[neighbor_y * MAP_WIDTH + neighbor_x]
                    if isinstance(neighbor, dict) and neighbor.get('rooms') == [room_id]:
                        adjacent_to_room = True
                        break
                if not adjacent_to_room:
                    self.add_error(file_path, f"Room boundary '{boundary['id']}' wall tile must be cardinally adjacent to room '{room_id}'.")
                continue
            feature = tile.get('feature')
            if (
                not isinstance(feature, dict)
                or feature.get('type') != 'furniture'
                or feature.get('id') not in door_furniture_ids
            ):
                self.add_error(file_path, f"Room boundary '{boundary['id']}' must reference door-capable furniture at z {z} [{x}, {y}].")
                continue
            matches_connection = any(
                connection['at'] == [x, y]
                and connection['z'] == z
                and any(
                    endpoint.get('kind') == 'room' and endpoint.get('id') == room_id
                    for endpoint in (connection['from'], connection['to'])
                )
                for connection in validated_room_connections
            )
            if not matches_connection:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' must match a room connection for room '{room_id}'.")

        complete_room_ids = {
            room['id']
            for room in rooms
            if isinstance(room, dict)
            and room.get('kind') == 'enclosed'
            and room.get('boundary_validation') == 'complete'
            and isinstance(room.get('id'), str)
        }
        declared_edges: Dict[tuple, Set[tuple]] = {}
        for boundary in validated_room_boundaries:
            room_id = boundary['room']
            if room_id not in complete_room_ids:
                continue
            boundary_id = boundary['id']
            side = boundary.get('side')
            if side not in CARDINAL_SIDES:
                self.add_error(file_path, f"Room boundary '{boundary_id}' side is required for complete boundary validation.")
                continue
            x, y = boundary['at']
            z = boundary['z']
            level_index = z + 10
            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
            if not isinstance(level, list) or len(level) != POPULATED_LEVEL_TILE_COUNT:
                continue
            if boundary['element'] == 'wall_tile':
                delta_x, delta_y = CARDINAL_SIDES[side]
                room_x, room_y = x + delta_x, y + delta_y
                if not 0 <= room_x < MAP_WIDTH or not 0 <= room_y < MAP_HEIGHT:
                    self.add_error(file_path, f"Room boundary '{boundary_id}' side does not point to room '{room_id}'.")
                    continue
                room_tile = level[room_y * MAP_WIDTH + room_x]
                if not isinstance(room_tile, dict) or room_tile.get('rooms') != [room_id]:
                    self.add_error(file_path, f"Room boundary '{boundary_id}' side does not point to room '{room_id}'.")
                    continue
                edge = (room_x, room_y, OPPOSITE_SIDES[side])
            else:
                room_tile = level[y * MAP_WIDTH + x]
                if not isinstance(room_tile, dict) or room_tile.get('rooms') != [room_id]:
                    self.add_error(file_path, f"Room boundary '{boundary_id}' side does not start on room '{room_id}'.")
                    continue
                edge = (x, y, side)
            key = (room_id, z)
            edges = declared_edges.setdefault(key, set())
            if edge in edges:
                self.add_error(file_path, f"Room boundary '{boundary_id}' duplicates directed boundary edge for room '{room_id}'.")
            edges.add(edge)

        for room_id in complete_room_ids:
            for level_index, level in enumerate(levels if isinstance(levels, list) else []):
                if not isinstance(level, list) or len(level) != POPULATED_LEVEL_TILE_COUNT:
                    continue
                required_edges: Set[tuple] = set()
                for y in range(MAP_HEIGHT):
                    for x in range(MAP_WIDTH):
                        tile = level[y * MAP_WIDTH + x]
                        if not isinstance(tile, dict) or tile.get('rooms') != [room_id]:
                            continue
                        for side, (delta_x, delta_y) in CARDINAL_SIDES.items():
                            neighbor_x, neighbor_y = x + delta_x, y + delta_y
                            if not 0 <= neighbor_x < MAP_WIDTH or not 0 <= neighbor_y < MAP_HEIGHT:
                                required_edges.add((x, y, side))
                                continue
                            neighbor = level[neighbor_y * MAP_WIDTH + neighbor_x]
                            if not isinstance(neighbor, dict) or neighbor.get('rooms') != [room_id]:
                                required_edges.add((x, y, side))
                z = level_index - 10
                declared = declared_edges.get((room_id, z), set())
                missing = required_edges - declared
                extra = declared - required_edges
                if missing:
                    x, y, side = sorted(missing)[0]
                    self.add_error(file_path, f"Complete room '{room_id}' is missing boundary evidence for {side} edge at z {z} [{x}, {y}].")
                if extra:
                    x, y, side = sorted(extra)[0]
                    self.add_error(file_path, f"Complete room '{room_id}' declares non-exposed {side} boundary edge at z {z} [{x}, {y}].")

        validated_buildings = []
        seen_building_ids: Set[str] = set()
        for idx, building in enumerate(buildings):
            context = f"Building at index {idx}"
            if not isinstance(building, dict):
                self.add_error(file_path, f"{context} is not an object.")
                continue
            unknown_fields = sorted(set(building) - BUILDING_FIELDS)
            if unknown_fields:
                self.add_error(file_path, f"{context} has unknown field '{unknown_fields[0]}'.")
            for field in BUILDING_REQUIRED_FIELDS:
                if field not in building:
                    self.add_error(file_path, f"{context} is missing required field '{field}'.")
            building_id = building.get('id')
            if not isinstance(building_id, str) or not building_id:
                self.add_error(file_path, f"{context} has invalid or missing ID.")
            elif building_id in seen_building_ids:
                self.add_error(file_path, f"Duplicate building ID detected: '{building_id}'")
            else:
                seen_building_ids.add(building_id)
            building_rooms = building.get('rooms')
            rooms_valid = isinstance(building_rooms, list) and bool(building_rooms)
            if not rooms_valid:
                self.add_error(file_path, f"{context} rooms must name at least one room.")
                building_rooms = []
            elif len(building_rooms) != len(set(building_rooms)):
                self.add_error(file_path, f"{context} rooms must not duplicate room IDs.")
            for room_id in building_rooms:
                if not isinstance(room_id, str) or room_id not in room_ids:
                    self.add_error(file_path, f"{context} references non-existent room '{room_id}'.")
                    rooms_valid = False
            footprint = building.get('footprint')
            footprint_valid = isinstance(footprint, dict) and set(footprint) == BUILDING_FOOTPRINT_FIELDS
            if not footprint_valid:
                self.add_error(file_path, f"{context} footprint must define x, y, width, and height.")
                footprint = {}
            x, y, width, height = (footprint.get(field) for field in ('x', 'y', 'width', 'height'))
            if (
                not all(type(value) is int for value in (x, y, width, height))
                or width is None or height is None or width <= 0 or height <= 0
            ):
                self.add_error(file_path, f"{context} footprint must use positive integer width and height.")
                footprint_valid = False
            elif x < 0 or y < 0 or x + width > MAP_WIDTH or y + height > MAP_HEIGHT:
                self.add_error(file_path, f"{context} footprint must fit within map bounds.")
                footprint_valid = False
            z = building.get('z')
            z_valid = type(z) is int and -10 <= z <= 10
            if not z_valid:
                self.add_error(file_path, f"{context} z must be an integer from -10 through 10.")
            access_validation = building.get('access_validation')
            if access_validation is not None and access_validation not in BUILDING_ACCESS_VALIDATIONS:
                self.add_error(file_path, f"{context} access_validation has unsupported validation '{access_validation}'.")
            interior_rooms = building.get('interior_rooms')
            if interior_rooms is not None:
                if not isinstance(interior_rooms, list) or not interior_rooms:
                    self.add_error(file_path, f"{context} interior_rooms must name at least one room.")
                else:
                    if len(interior_rooms) != len(set(interior_rooms)):
                        self.add_error(file_path, f"{context} interior_rooms must not duplicate room IDs.")
                    for room_id in interior_rooms:
                        if not isinstance(room_id, str) or room_id not in room_ids:
                            self.add_error(file_path, f"{context} interior_rooms references unknown room '{room_id}'.")
                        elif not isinstance(building_rooms, list) or room_id not in building_rooms:
                            self.add_error(file_path, f"{context} interior_rooms room '{room_id}' is not owned by the building.")
            open_space_rooms = building.get('open_space_rooms')
            if open_space_rooms is not None:
                if not isinstance(open_space_rooms, list) or not open_space_rooms:
                    self.add_error(file_path, f"{context} open_space_rooms must name at least one room.")
                else:
                    if all(isinstance(room_id, str) for room_id in open_space_rooms) and len(open_space_rooms) != len(set(open_space_rooms)):
                        self.add_error(file_path, f"{context} open_space_rooms must not duplicate room IDs.")
                    for room_id in open_space_rooms:
                        if not isinstance(room_id, str) or room_id not in room_ids:
                            self.add_error(file_path, f"{context} open_space_rooms references unknown room '{room_id}'.")
                        elif not isinstance(building_rooms, list) or room_id not in building_rooms:
                            self.add_error(file_path, f"{context} open_space_rooms room '{room_id}' is not owned by the building.")
                    if (
                        isinstance(interior_rooms, list)
                        and all(isinstance(room_id, str) for room_id in open_space_rooms)
                        and all(isinstance(room_id, str) for room_id in interior_rooms)
                        and set(open_space_rooms) & set(interior_rooms)
                    ):
                        self.add_error(file_path, f"{context} open_space_rooms must not overlap interior_rooms.")
            room_partition_validation = building.get('room_partition_validation')
            if (
                room_partition_validation is not None
                and room_partition_validation not in BUILDING_ROOM_PARTITION_VALIDATIONS
            ):
                self.add_error(file_path, f"{context} room_partition_validation has unsupported validation '{room_partition_validation}'.")
            overhead_validation = building.get('overhead_validation')
            if overhead_validation is not None and overhead_validation not in BUILDING_OVERHEAD_VALIDATIONS:
                self.add_error(file_path, f"{context} overhead_validation has unsupported validation '{overhead_validation}'.")
            if (
                isinstance(building_id, str) and building_id
                and rooms_valid and footprint_valid and z_valid
            ):
                validated_buildings.append(building)

        room_definitions = {
            room['id']: room for room in rooms
            if isinstance(room, dict) and isinstance(room.get('id'), str)
        }
        for index, building in enumerate(validated_buildings):
            context = f"Building at index {index}"
            footprint = building['footprint']
            z = building['z']
            for other in validated_buildings[:index]:
                if other['z'] != z:
                    continue
                left, right = footprint, other['footprint']
                overlaps = not (
                    left['x'] + left['width'] <= right['x']
                    or right['x'] + right['width'] <= left['x']
                    or left['y'] + left['height'] <= right['y']
                    or right['y'] + right['height'] <= left['y']
                )
                if overlaps:
                    self.add_error(file_path, f"{context} overlaps building '{other['id']}' at z {z}.")
            if not any(
                room_definitions[room_id].get('kind') == 'enclosed'
                and room_definitions[room_id].get('boundary_validation') == 'complete'
                for room_id in building['rooms']
            ):
                self.add_error(file_path, f"{context} requires an enclosed room with boundary_validation 'complete'.")
            for room_id in building['rooms']:
                memberships = []
                for level_index, level in enumerate(levels if isinstance(levels, list) else []):
                    if not isinstance(level, list) or len(level) != POPULATED_LEVEL_TILE_COUNT:
                        continue
                    for tile_index, tile in enumerate(level):
                        if isinstance(tile, dict) and tile.get('rooms') == [room_id]:
                            memberships.append((level_index - 10, tile_index % MAP_WIDTH, tile_index // MAP_WIDTH))
                if not memberships:
                    self.add_error(file_path, f"{context} room '{room_id}' has no membership at z {z}.")
                    continue
                for membership_z, x, y in memberships:
                    if membership_z != z:
                        self.add_error(file_path, f"{context} room '{room_id}' has membership outside building z {z}.")
                    elif not (footprint['x'] <= x < footprint['x'] + footprint['width'] and footprint['y'] <= y < footprint['y'] + footprint['height']):
                        self.add_error(file_path, f"{context} room '{room_id}' membership at [{x}, {y}] is outside building footprint.")
                for boundary in validated_room_boundaries:
                    if boundary['room'] == room_id and boundary['z'] == z:
                        x, y = boundary['at']
                        if not (footprint['x'] <= x < footprint['x'] + footprint['width'] and footprint['y'] <= y < footprint['y'] + footprint['height']):
                            self.add_error(file_path, f"{context} room boundary '{boundary['id']}' is outside building footprint.")
                for connection in validated_room_connections:
                    names_room = any(endpoint.get('kind') == 'room' and endpoint.get('id') == room_id for endpoint in (connection['from'], connection['to']))
                    if connection['z'] == z and names_room:
                        x, y = connection['at']
                        if not (footprint['x'] <= x < footprint['x'] + footprint['width'] and footprint['y'] <= y < footprint['y'] + footprint['height']):
                            self.add_error(file_path, f"{context} room connection '{connection['id']}' is outside building footprint.")
            if building.get('interior_rooms') is not None and isinstance(building.get('interior_rooms'), list):
                for room_id in building['interior_rooms']:
                    room_definition = room_definitions.get(room_id)
                    if (
                        isinstance(room_definition, dict)
                        and (room_definition.get('kind') != 'enclosed' or room_definition.get('boundary_validation') != 'complete')
                    ):
                        self.add_error(file_path, f"{context} interior room '{room_id}' must be enclosed with boundary_validation 'complete'.")
            if building.get('open_space_rooms') is not None and isinstance(building.get('open_space_rooms'), list):
                for room_id in building['open_space_rooms']:
                    room_definition = room_definitions.get(room_id)
                    if isinstance(room_definition, dict) and room_definition.get('kind') not in {'covered_open', 'ruin'}:
                        self.add_error(file_path, f"{context} open-space room '{room_id}' must be covered_open or ruin.")
            if building.get('room_partition_validation') == 'complete':
                interior = building.get('interior_rooms', [])
                open_space = building.get('open_space_rooms', [])
                if isinstance(interior, list) and isinstance(open_space, list):
                    classified_rooms = set(interior) | set(open_space)
                    for room_id in building['rooms']:
                        if room_id not in classified_rooms:
                            self.add_error(file_path, f"{context} room '{room_id}' is not classified as interior or open space.")
            if building.get('access_validation') == 'complete':
                owned_rooms = set(building['rooms'])
                room_graph = {room_id: set() for room_id in owned_rooms}
                exterior_rooms: Set[str] = set()
                for connection in validated_room_connections:
                    if connection['z'] != z:
                        continue
                    endpoints = (connection['from'], connection['to'])
                    room_endpoints = [endpoint['id'] for endpoint in endpoints if endpoint.get('kind') == 'room']
                    if any(endpoint.get('kind') == 'exterior' for endpoint in endpoints):
                        exterior_rooms.update(room_id for room_id in room_endpoints if room_id in owned_rooms)
                    elif len(room_endpoints) == 2 and all(room_id in owned_rooms for room_id in room_endpoints):
                        left, right = room_endpoints
                        room_graph[left].add(right)
                        room_graph[right].add(left)
                reachable_rooms = set(exterior_rooms)
                frontier = list(exterior_rooms)
                while frontier:
                    room_id = frontier.pop()
                    for connected_room in room_graph[room_id]:
                        if connected_room not in reachable_rooms:
                            reachable_rooms.add(connected_room)
                            frontier.append(connected_room)
                for room_id in building['rooms']:
                    if room_id not in reachable_rooms:
                        self.add_error(file_path, f"{context} room '{room_id}' has no route to exterior through owned room_connections.")

        building_by_id = {building['id']: building for building in validated_buildings}
        seen_surface_ids: Set[str] = set()
        seen_surface_kinds: Set[tuple] = set()
        for idx, surface in enumerate(building_surfaces):
            context = f"Building surface at index {idx}"
            if not isinstance(surface, dict):
                self.add_error(file_path, f"{context} is not an object.")
                continue
            unknown_fields = sorted(set(surface) - BUILDING_SURFACE_FIELDS)
            if unknown_fields:
                self.add_error(file_path, f"{context} has unknown field '{unknown_fields[0]}'.")
            for field in BUILDING_SURFACE_FIELDS:
                if field not in surface:
                    self.add_error(file_path, f"{context} is missing required field '{field}'.")
            surface_id = surface.get('id')
            if not isinstance(surface_id, str) or not surface_id:
                self.add_error(file_path, f"{context} has invalid or missing ID.")
            elif surface_id in seen_surface_ids:
                self.add_error(file_path, f"Duplicate building surface ID detected: '{surface_id}'")
            else:
                seen_surface_ids.add(surface_id)
            building_id = surface.get('building')
            building = building_by_id.get(building_id) if isinstance(building_id, str) else None
            if building is None:
                self.add_error(file_path, f"{context} references non-existent building '{building_id}'.")
            kind = surface.get('kind')
            if kind not in BUILDING_SURFACE_KINDS:
                self.add_error(file_path, f"{context} has unsupported kind '{kind}'.")
            elif building is not None:
                surface_key = (building_id, kind)
                if surface_key in seen_surface_kinds:
                    self.add_error(file_path, f"{context} duplicates {kind} surface for building '{building_id}'.")
                seen_surface_kinds.add(surface_key)
            z = surface.get('z')
            if type(z) is not int or not -10 <= z <= 10:
                self.add_error(file_path, f"{context} z must be an integer from -10 through 10.")
            elif building is not None and z != building['z'] + 1:
                self.add_error(file_path, f"{context} z must be immediately above building '{building_id}' at z {building['z'] + 1}.")

        surface_kinds_by_building: Dict[str, Set[str]] = {}
        for surface in building_surfaces:
            if not isinstance(surface, dict):
                continue
            building_id = surface.get('building')
            kind = surface.get('kind')
            if isinstance(building_id, str) and building_id in building_by_id and kind in BUILDING_SURFACE_KINDS:
                surface_kinds_by_building.setdefault(building_id, set()).add(kind)
        for index, building in enumerate(validated_buildings):
            if building.get('overhead_validation') != 'complete':
                continue
            surface_kinds = surface_kinds_by_building.get(building['id'], set())
            for kind in ('roof', 'ceiling'):
                if kind not in surface_kinds:
                    self.add_error(file_path, f"Building at index {index} requires {kind} surface at z {building['z'] + 1}.")
        seen_composition_ids: Set[str] = set()
        seen_composition_buildings: Set[str] = set()
        for idx, composition in enumerate(building_compositions):
            context = f"Building composition at index {idx}"
            if not isinstance(composition, dict):
                self.add_error(file_path, f"{context} is not an object.")
                continue
            unknown_fields = sorted(set(composition) - BUILDING_COMPOSITION_FIELDS)
            if unknown_fields:
                self.add_error(file_path, f"{context} has unknown field '{unknown_fields[0]}'.")
            for field in BUILDING_COMPOSITION_FIELDS:
                if field not in composition:
                    self.add_error(file_path, f"{context} is missing required field '{field}'.")
            composition_id = composition.get('id')
            if not isinstance(composition_id, str) or not composition_id:
                self.add_error(file_path, f"{context} has invalid or missing ID.")
            elif composition_id in seen_composition_ids:
                self.add_error(file_path, f"Duplicate building composition ID detected: '{composition_id}'")
            else:
                seen_composition_ids.add(composition_id)
            building_id = composition.get('building')
            if not isinstance(building_id, str) or building_id not in building_by_id:
                self.add_error(file_path, f"{context} references non-existent building '{building_id}'.")
            elif building_id in seen_composition_buildings:
                self.add_error(file_path, f"{context} duplicates composition for building '{building_id}'.")
            else:
                seen_composition_buildings.add(building_id)
            required_surfaces = composition.get('required_surfaces')
            if not isinstance(required_surfaces, list) or not required_surfaces:
                self.add_error(file_path, f"{context} must require at least one surface kind.")
                continue
            unsupported_kinds = [kind for kind in required_surfaces if kind not in BUILDING_SURFACE_KINDS]
            if unsupported_kinds:
                self.add_error(file_path, f"{context} has unsupported surface kind '{unsupported_kinds[0]}'.")
            if len(required_surfaces) != len(set(required_surfaces)):
                self.add_error(file_path, f"{context} must not duplicate surface kinds.")
            if isinstance(building_id, str) and building_id in building_by_id:
                surface_kinds = surface_kinds_by_building.get(building_id, set())
                for kind in required_surfaces:
                    if kind in BUILDING_SURFACE_KINDS and kind not in surface_kinds:
                        self.add_error(file_path, f"{context} requires {kind} surface for building '{building_id}'.")

    def run(self, path: str):
        if os.path.isdir(path):
            for root, _, files in os.walk(path):
                for file in files:
                    if file.endswith('.json'):
                        full_path = os.path.abspath(os.path.join(root, file))
                        self.validate_map(full_path)
        else:
            self.validate_map(os.path.abspath(path))

        print("\n--- Map Validation Summary ---")
        print(f"Files processed: {self.files_processed}")
        
        if self.errors:
            print(f"\n❌ Found {len(self.errors)} error(s):")
            for err in self.errors:
                print(err)
            return 1
        
        if self.warnings:
            print(f"\n⚠️ Found {len(self.warnings)} warning(s):")
            for warn in self.warnings:
                print(warn)
        else:
            print("\n✅ No errors found.")

        if not self.errors:
            return 0
        return 1

def main():
    parser = argparse.ArgumentParser(description="Dimensionfall Map Validator")
    parser.add_argument("path", help="Path to a .json map file or a directory containing maps")
    args = parser.parse_args()

    validator = MapValidator()
    exit_code = validator.run(args.path)
    sys.exit(exit_code)

if __name__ == "__main__":
    main()
