import json
import os
import sys
import argparse
from typing import List, Dict, Any, Set, Tuple

MAP_WIDTH = 32
MAP_HEIGHT = 32
LEVEL_COUNT = 21
POPULATED_LEVEL_TILE_COUNT = MAP_WIDTH * MAP_HEIGHT
CONNECTION_DIRECTIONS = {'north', 'east', 'south', 'west'}
CONNECTION_TYPES = {'ground', 'road'}
ROAD_ENDPOINT_FIELDS = {'id', 'direction', 'at', 'z'}
ROAD_PATH_FIELDS = {'id', 'from', 'to', 'waypoints'}
ROAD_PATH_OPTIONAL_FIELDS = {'tile'}
ROOM_KINDS = {'enclosed', 'covered_open', 'ruin'}
ROOM_BOUNDARY_VALIDATIONS = {'complete'}
ROOM_BOUNDARY_GENERATIONS = {'walls'}
CARDINAL_SIDES = {
    'north': (0, -1),
    'east': (1, 0),
    'south': (0, 1),
    'west': (-1, 0),
}
OPPOSITE_SIDES = {'north': 'south', 'east': 'west', 'south': 'north', 'west': 'east'}
ROOM_CONNECTION_FIELDS = {'id', 'at', 'target_at', 'z', 'from', 'to', 'entrance'}
ROOM_CONNECTION_ENTRANCE_FIELDS = {'exterior_at', 'facing'}
ROOM_CONNECTION_ENDPOINT_KINDS = {'room', 'exterior'}
ROOM_BOUNDARY_FIELDS = {'id', 'room', 'at', 'target_at', 'room_at', 'z', 'element', 'side'}


def _physical_at(record):
    return record.get('target_at', record['at'])


def _room_at(record):
    return record.get('room_at', record['at'])


def _generated_room_connection_opening(connection, room_id):
    at = tuple(connection['at'])
    target_at = tuple(connection.get('target_at', connection['at']))
    if connection['from'] == {'kind': 'room', 'id': room_id}:
        return at, target_at, target_at
    if connection['to'] == {'kind': 'room', 'id': room_id}:
        return target_at, at, target_at
    return None
ROOM_BOUNDARY_ELEMENTS = {'wall_tile', 'door_furniture'}
BUILDING_FIELDS = {'id', 'rooms', 'footprint', 'z', 'building_levels', 'staircases', 'access_validation', 'interior_rooms', 'open_space_rooms', 'room_partition_validation', 'overhead_validation', 'exterior_context', 'exterior_access_context', 'entrance', 'entrances', 'entrance_validation', 'furniture_anchors', 'building_geometry', 'reachability_validation'}
BUILDING_REQUIRED_FIELDS = {'id', 'rooms', 'footprint', 'z'}
BUILDING_LEVEL_FIELDS = {'z', 'rooms', 'furniture_anchors'}
BUILDING_STAIRCASE_FIELDS = {'id', 'lower_at', 'upper_at', 'rotation', 'upper_rotation', 'landing_at', 'upper_clearance_at'}
BUILDING_EXTERIOR_CONTEXT_FIELDS = {'at', 'z'}
BUILDING_EXTERIOR_ACCESS_CONTEXT_FIELDS = {'connection'}
BUILDING_ENTRANCE_FIELDS = {'connection', 'facing'}
BUILDING_ENTRANCES_ENTRY_FIELDS = {'id', 'connection', 'facing'}
BUILDING_ENTRANCE_FACINGS = {'north', 'east', 'south', 'west'}
BUILDING_FURNITURE_ANCHOR_FIELDS = {'id', 'at', 'z', 'kind'}
BUILDING_ENTRANCE_VALIDATIONS = {'complete'}
BUILDING_ACCESS_VALIDATIONS = {'complete'}
BUILDING_REACHABILITY_FIELDS = {'required_entrances', 'required_furniture_anchors', 'required_building_levels'}
BUILDING_ROOM_PARTITION_VALIDATIONS = {'complete'}
BUILDING_OVERHEAD_VALIDATIONS = {'complete'}
BUILDING_FOOTPRINT_FIELDS = {'x', 'y', 'width', 'height'}
BUILDING_SURFACE_FIELDS = {'id', 'building', 'kind', 'z'}
BUILDING_SURFACE_KINDS = {'roof', 'ceiling', 'floor'}
BUILDING_COMPOSITION_FIELDS = {'id', 'building', 'required_surfaces'}
BUILDING_SUPPORT_FIELDS = {'id', 'building', 'at', 'from_z', 'to_z', 'kind'}
BUILDING_SUPPORT_KINDS = {'column', 'wall'}

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

    def _slope_tile_ids(self):
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
                and entry.get('shape') == 'slope'
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
        building_supports = data.get('building_supports', [])
        if not isinstance(building_supports, list):
            self.add_error(file_path, "top-level building_supports must be an array.")
            building_supports = []

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

        # 2b. Validate connections content
        connections = data.get('connections')
        if isinstance(connections, dict):
            for direction, value in connections.items():
                if direction not in CONNECTION_DIRECTIONS:
                    self.add_error(file_path, f"connections has unknown direction '{direction}'.")
                if not isinstance(value, str) or value not in CONNECTION_TYPES:
                    self.add_error(file_path, f"connections.{direction} has unsupported type '{value}'.")

        # 2c. Validate road_endpoints
        road_endpoints = data.get('road_endpoints', [])
        if not isinstance(road_endpoints, list):
            self.add_error(file_path, "top-level road_endpoints must be an array.")
            road_endpoints = []
        road_paths = data.get('road_paths', [])
        if not isinstance(road_paths, list):
            self.add_error(file_path, "top-level road_paths must be an array.")
            road_paths = []
        if isinstance(road_endpoints, list):
            seen_endpoint_ids: Set[str] = set()
            for idx, endpoint in enumerate(road_endpoints):
                if not isinstance(endpoint, dict):
                    self.add_error(file_path, f"road_endpoints[{idx}] is not an object.")
                    continue
                context = f"road_endpoints[{idx}]"
                unknown_fields = set(endpoint) - ROAD_ENDPOINT_FIELDS
                if unknown_fields:
                    self.add_error(file_path, f"{context} has unknown field '{sorted(unknown_fields)[0]}'.")
                if set(endpoint) != ROAD_ENDPOINT_FIELDS:
                    self.add_error(file_path, f"{context} must define id, direction, at, and z.")
                    continue
                endpoint_id = endpoint.get('id')
                if not isinstance(endpoint_id, str) or not endpoint_id:
                    self.add_error(file_path, f"{context} id must be a non-empty string.")
                elif endpoint_id in seen_endpoint_ids:
                    self.add_error(file_path, f"{context} duplicates road endpoint ID '{endpoint_id}'.")
                else:
                    seen_endpoint_ids.add(endpoint_id)
                direction = endpoint.get('direction')
                if direction not in CONNECTION_DIRECTIONS:
                    self.add_error(file_path, f"{context} direction must be north, east, south, or west.")
                elif isinstance(connections, dict) and connections.get(direction) != 'road':
                    self.add_error(file_path, f"{context} direction '{direction}' requires connections.{direction} to be 'road'.")
                at = endpoint.get('at')
                if isinstance(at, list) and len(at) == 2 and all(type(v) is int for v in at):
                    ep_x, ep_y = at
                    if not 0 <= ep_x < MAP_WIDTH or not 0 <= ep_y < MAP_HEIGHT:
                        self.add_error(file_path, f"{context} at must be within map bounds.")
                    elif direction in CONNECTION_DIRECTIONS:
                        edge_checks = {
                            'north': ep_y == 0,
                            'south': ep_y == MAP_HEIGHT - 1,
                            'west': ep_x == 0,
                            'east': ep_x == MAP_WIDTH - 1,
                        }
                        if not edge_checks[direction]:
                            self.add_error(file_path, f"{context} at must be on the {direction} edge of the map.")
                        elif endpoint.get('z') == 0:
                            level_index = 10
                            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
                            tile = level[ep_y * MAP_WIDTH + ep_x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
                            if not isinstance(tile, dict) or not isinstance(tile.get('id'), str) or not tile.get('id'):
                                self.add_error(file_path, f"{context} must reference existing terrain at [{ep_x}, {ep_y}] on z 0.")
                else:
                    self.add_error(file_path, f"{context} at must be a two-integer coordinate within map bounds.")
                z = endpoint.get('z')
                if z is not None and (type(z) is not int or z != 0):
                    self.add_error(file_path, f"{context} z must be 0.")

            endpoint_by_id = {endpoint.get('id'): endpoint for endpoint in road_endpoints if isinstance(endpoint, dict) and isinstance(endpoint.get('id'), str)}
            seen_path_ids: Set[str] = set()
            for idx, path in enumerate(road_paths):
                context = f"road_paths[{idx}]"
                if not isinstance(path, dict) or not ROAD_PATH_FIELDS.issubset(path) or set(path) - ROAD_PATH_FIELDS - ROAD_PATH_OPTIONAL_FIELDS:
                    self.add_error(file_path, f"{context} must define id, from, to, and waypoints, with optional tile.")
                    continue
                path_id = path.get('id')
                if not isinstance(path_id, str) or not path_id:
                    self.add_error(file_path, f"{context} id must be a non-empty string.")
                elif path_id in seen_path_ids:
                    self.add_error(file_path, f"{context} duplicates road path ID '{path_id}'.")
                seen_path_ids.add(path_id)
                from_id, to_id = path.get('from'), path.get('to')
                if from_id not in endpoint_by_id or to_id not in endpoint_by_id:
                    self.add_error(file_path, f"{context} must reference existing road endpoint IDs.")
                if from_id == to_id:
                    self.add_error(file_path, f"{context} from and to must reference different endpoints.")
                waypoints = path.get('waypoints')
                if not isinstance(waypoints, list):
                    self.add_error(file_path, f"{context} waypoints must be an array.")
                    continue
                endpoints = [endpoint_by_id[from_id]['at']] if from_id in endpoint_by_id else []
                points = endpoints + waypoints + ([endpoint_by_id[to_id]['at']] if to_id in endpoint_by_id else [])
                for point_index, point in enumerate(points):
                    if not isinstance(point, list) or len(point) != 2 or not all(type(value) is int for value in point) or not 0 <= point[0] < MAP_WIDTH or not 0 <= point[1] < MAP_HEIGHT:
                        self.add_error(file_path, f"{context} point {point_index} must be a map-bounded two-integer coordinate.")
                    elif point_index and points[point_index][0] != points[point_index - 1][0] and points[point_index][1] != points[point_index - 1][1]:
                        self.add_error(file_path, f"{context} points must form cardinally aligned segments.")
                if 'tile' in path:
                    tile = path['tile']
                    if not isinstance(tile, dict) or set(tile) - {'id', 'rotation'} or not isinstance(tile.get('id'), str) or not tile.get('id'):
                        self.add_error(file_path, f"{context}.tile must be a non-empty tile object.")

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
            unknown_fields = sorted(set(room) - {'id', 'kind', 'boundary_validation', 'boundary_generation'})
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
            boundary_generation = room.get('boundary_generation')
            if boundary_generation is not None:
                if boundary_generation not in ROOM_BOUNDARY_GENERATIONS:
                    self.add_error(file_path, f"Room at index {idx} has unsupported boundary generation '{boundary_generation}'.")
                elif kind != 'enclosed' or boundary_validation != 'complete':
                    self.add_error(file_path, f"Room at index {idx} boundary generation requires an enclosed room with complete boundary validation.")

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
            for field in ('id', 'at', 'z', 'from', 'to'):
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
            target_at = connection.get('target_at')
            if target_at is not None and (
                not isinstance(target_at, list)
                or len(target_at) != 2
                or any(type(value) is not int for value in target_at)
                or not 0 <= target_at[0] < MAP_WIDTH
                or not 0 <= target_at[1] < MAP_HEIGHT
            ):
                self.add_error(file_path, f"{context} target_at must be a two-integer coordinate within map bounds.")
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
            entrance = connection.get('entrance')
            entrance_valid = True
            if entrance is not None:
                if not isinstance(entrance, dict):
                    self.add_error(file_path, f"{context} entrance must be an object.")
                    entrance_valid = False
                else:
                    unknown_entrance_fields = sorted(set(entrance) - ROOM_CONNECTION_ENTRANCE_FIELDS)
                    if unknown_entrance_fields:
                        self.add_error(file_path, f"{context} entrance has unknown field '{unknown_entrance_fields[0]}'.")
                        entrance_valid = False
                    if set(entrance) != ROOM_CONNECTION_ENTRANCE_FIELDS:
                        self.add_error(file_path, f"{context} entrance must define exterior_at and facing.")
                        entrance_valid = False
                    exterior_at = entrance.get('exterior_at')
                    if (
                        not isinstance(exterior_at, list)
                        or len(exterior_at) != 2
                        or any(type(value) is not int for value in exterior_at)
                        or not 0 <= exterior_at[0] < MAP_WIDTH
                        or not 0 <= exterior_at[1] < MAP_HEIGHT
                    ):
                        self.add_error(file_path, f"{context} entrance.exterior_at must be a two-integer coordinate within map bounds.")
                        entrance_valid = False
                    facing = entrance.get('facing')
                    if not isinstance(facing, str) or facing not in CARDINAL_SIDES:
                        self.add_error(file_path, f"{context} entrance.facing must be one of north, east, south, or west.")
                        entrance_valid = False
                    if not any(isinstance(endpoint, dict) and endpoint.get('kind') == 'exterior' for endpoint in endpoints):
                        self.add_error(file_path, f"{context} entrance metadata requires a room-to-exterior connection.")
                        entrance_valid = False
            else:
                entrance_valid = True
            if (
                isinstance(connection_id, str) and connection_id
                and isinstance(at, list) and len(at) == 2
                and all(type(value) is int for value in at)
                and 0 <= at[0] < MAP_WIDTH and 0 <= at[1] < MAP_HEIGHT
                and type(z) is int and -10 <= z <= 10
                and entrance_valid
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
            for coordinate_field in ('target_at', 'room_at'):
                coordinate = boundary.get(coordinate_field)
                if coordinate is not None and (
                    not isinstance(coordinate, list)
                    or len(coordinate) != 2
                    or any(type(value) is not int for value in coordinate)
                    or not 0 <= coordinate[0] < MAP_WIDTH
                    or not 0 <= coordinate[1] < MAP_HEIGHT
                ):
                    self.add_error(file_path, f"{context} {coordinate_field} must be a two-integer coordinate within map bounds.")
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
            x, y = _physical_at(connection)
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
            x, y = _physical_at(boundary)
            room_x, room_y = _room_at(boundary)
            z = boundary['z']
            target = (room_id, z, x, y)
            if target in seen_boundary_targets:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' duplicates boundary target for room '{room_id}' at z {z} [{x}, {y}].")
                continue
            seen_boundary_targets.add(target)
            level_index = z + 11 if boundary['element'] == 'wall_tile' else z + 10
            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
            if boundary['element'] == 'wall_tile' and (not level or level[y * MAP_WIDTH + x].get('id') not in wall_tile_ids):
                level = levels[z + 10] if isinstance(levels, list) and z + 10 < len(levels) else []
            tile = level[y * MAP_WIDTH + x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
            if not isinstance(tile, dict) or not isinstance(tile.get('id'), str) or not tile['id']:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' requires existing terrain at z {z + 1 if boundary['element'] == 'wall_tile' else z} [{x}, {y}].")
                continue
            room_level = level
            if boundary['element'] == 'wall_tile':
                room_level_index = z + 10
                room_level = levels[room_level_index] if isinstance(levels, list) and 0 <= room_level_index < len(levels) else []
                if tile['id'] not in wall_tile_ids:
                    self.add_error(file_path, f"Room boundary '{boundary['id']}' must reference a Wall-category tile at z {z} [{x}, {y}].")
                    continue
                if 'room_at' in boundary:
                    room_tile = room_level[room_y * MAP_WIDTH + room_x]
                    adjacent_to_room = isinstance(room_tile, dict) and room_tile.get('rooms') == [room_id]
                else:
                    adjacent_to_room = False
                    for delta_x, delta_y in ((0, -1), (1, 0), (0, 1), (-1, 0)):
                        neighbor_x = x + delta_x
                        neighbor_y = y + delta_y
                        if not 0 <= neighbor_x < MAP_WIDTH or not 0 <= neighbor_y < MAP_HEIGHT:
                            continue
                        neighbor = room_level[neighbor_y * MAP_WIDTH + neighbor_x]
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
                connection['at'] == [room_x, room_y]
                and ('target_at' not in connection or connection['target_at'] == [x, y])
                and connection['z'] == z
                and any(
                    endpoint.get('kind') == 'room' and endpoint.get('id') == room_id
                    for endpoint in (connection['from'], connection['to'])
                )
                for connection in validated_room_connections
            )
            if not matches_connection:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' must match a room connection for room '{room_id}'.")

        automatic_room_ids = {
            room['id']
            for room in rooms
            if isinstance(room, dict)
            and room.get('kind') == 'enclosed'
            and room.get('boundary_validation') == 'complete'
            and room.get('boundary_generation') == 'walls'
            and isinstance(room.get('id'), str)
        }
        for boundary in validated_room_boundaries:
            if boundary['room'] in automatic_room_ids:
                self.add_error(file_path, f"Room boundary '{boundary['id']}' must not target room '{boundary['room']}' with boundary_generation 'walls'.")

        for room_id in automatic_room_ids:
            owner = next(
                (
                    building for building in buildings
                    if isinstance(building, dict)
                    and room_id in building.get('rooms', [])
                    and isinstance(building.get('building_geometry'), dict)
                    and isinstance(building['building_geometry'].get('wall_tile'), dict)
                    and isinstance(building['building_geometry']['wall_tile'].get('id'), str)
                ),
                None,
            )
            if owner is None:
                self.add_error(file_path, f"Generated boundary room '{room_id}' requires an owning building with building_geometry.wall_tile.")
                continue
            wall_id = owner['building_geometry']['wall_tile']['id']
            for level_index, level in enumerate(levels if isinstance(levels, list) else []):
                if not isinstance(level, list) or len(level) != POPULATED_LEVEL_TILE_COUNT:
                    continue
                z = level_index - 10
                room_cells = {
                    (x, y)
                    for y in range(MAP_HEIGHT)
                    for x in range(MAP_WIDTH)
                    if isinstance(level[y * MAP_WIDTH + x], dict)
                    and level[y * MAP_WIDTH + x].get('rooms') == [room_id]
                }
                if not room_cells:
                    continue
                perimeter = {
                    (neighbor_x, neighbor_y)
                    for x, y in room_cells
                    for delta_x in (-1, 0, 1)
                    for delta_y in (-1, 0, 1)
                    if (delta_x or delta_y)
                    and 0 <= (neighbor_x := x + delta_x) < MAP_WIDTH
                    and 0 <= (neighbor_y := y + delta_y) < MAP_HEIGHT
                    and (neighbor_x, neighbor_y) not in room_cells
                }
                openings = set()
                for connection in validated_room_connections:
                    if connection['z'] != z:
                        continue
                    opening = _generated_room_connection_opening(connection, room_id)
                    if opening is None:
                        continue
                    room_at, opening_at, door_at = opening
                    if room_at not in room_cells or abs(room_at[0] - opening_at[0]) + abs(room_at[1] - opening_at[1]) != 1 or opening_at not in perimeter:
                        self.add_error(file_path, f"Room connection '{connection['id']}' must cross a cardinal perimeter edge of generated room '{room_id}' at z {z}.")
                        continue
                    openings.add(opening_at)
                wall_level_index = z + 11
                wall_level = levels[wall_level_index] if 0 <= wall_level_index < len(levels) else []
                for x, y in perimeter - openings:
                    tile = wall_level[y * MAP_WIDTH + x] if isinstance(wall_level, list) and len(wall_level) == POPULATED_LEVEL_TILE_COUNT else {}
                    has_wall = isinstance(tile, dict) and tile.get('id') == wall_id
                    if not has_wall:
                        neighbor_room_id = level[y * MAP_WIDTH + x].get('rooms', [None])[0]
                        if neighbor_room_id in automatic_room_ids and room_id > neighbor_room_id:
                            for delta_x, delta_y in CARDINAL_SIDES.values():
                                room_x, room_y = x + delta_x, y + delta_y
                                if not 0 <= room_x < MAP_WIDTH or not 0 <= room_y < MAP_HEIGHT:
                                    continue
                                room_tile = level[room_y * MAP_WIDTH + room_x]
                                if isinstance(room_tile, dict) and room_tile.get('rooms') == [room_id]:
                                    canonical_tile = wall_level[room_y * MAP_WIDTH + room_x] if isinstance(wall_level, list) and len(wall_level) == POPULATED_LEVEL_TILE_COUNT else {}
                                    has_wall = isinstance(canonical_tile, dict) and canonical_tile.get('id') == wall_id
                                    break
                    if not has_wall:
                        self.add_error(file_path, f"Generated boundary room '{room_id}' is missing wall '{wall_id}' at z {z + 1} [{x}, {y}].")

        complete_room_ids = {
            room['id']
            for room in rooms
            if isinstance(room, dict)
            and room.get('kind') == 'enclosed'
            and room.get('boundary_validation') == 'complete'
            and room.get('boundary_generation') != 'walls'
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
            x, y = _physical_at(boundary)
            room_x, room_y = _room_at(boundary)
            z = boundary['z']
            level_index = z + 10
            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
            if not isinstance(level, list) or len(level) != POPULATED_LEVEL_TILE_COUNT:
                continue
            if boundary['element'] == 'wall_tile':
                room_level_index = z + 10
                room_level = levels[room_level_index] if isinstance(levels, list) and room_level_index < len(levels) else []
                level = room_level
                if 'room_at' not in boundary:
                    delta_x, delta_y = CARDINAL_SIDES[side]
                    room_x, room_y = x + delta_x, y + delta_y
                if not 0 <= room_x < MAP_WIDTH or not 0 <= room_y < MAP_HEIGHT:
                    self.add_error(file_path, f"Room boundary '{boundary_id}' side does not point to room '{room_id}'.")
                    continue
                room_level_index = z + 10
                room_level = levels[room_level_index] if isinstance(levels, list) and 0 <= room_level_index < len(levels) else []
                room_tile = room_level[room_y * MAP_WIDTH + room_x] if room_level else {}
                if not isinstance(room_tile, dict) or room_tile.get('rooms') != [room_id]:
                    self.add_error(file_path, f"Room boundary '{boundary_id}' side does not point to room '{room_id}'.")
                    continue
                edge = (room_x, room_y, OPPOSITE_SIDES[side])
            else:
                room_tile = room_level[room_y * MAP_WIDTH + room_x] if room_level else {}
                if not isinstance(room_tile, dict) or room_tile.get('rooms') != [room_id]:
                    self.add_error(file_path, f"Room boundary '{boundary_id}' side does not start on room '{room_id}'.")
                    continue
                edge = (room_x, room_y, side)
            boundary_level_z = z
            key = (room_id, boundary_level_z)
            edges = declared_edges.setdefault(key, set())
            if edge in edges and 'target_at' not in boundary:
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
            if 'building_geometry' in building:
                geometry = building['building_geometry']
                if not isinstance(geometry, dict) or set(geometry) not in ({'floor_tile', 'wall_tile', 'support_tile'}, {'floor_tile', 'wall_tile', 'support_tile', 'roof_tile'}):
                    self.add_error(file_path, f"{context} building_geometry must define floor_tile, wall_tile, support_tile, and optional roof_tile.")
                else:
                    for geometry_key, tile in geometry.items():
                        if not isinstance(tile, dict) or not isinstance(tile.get('id'), str) or not tile.get('id'):
                            self.add_error(file_path, f"{context} building_geometry.{geometry_key} must contain a non-empty tile id.")
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
            building_levels = building.get('building_levels')
            if building_levels is not None:
                if not isinstance(building_levels, list) or not building_levels:
                    self.add_error(file_path, f"{context} building_levels must be a non-empty array.")
                else:
                    previous_z = None
                    for level_index, level_definition in enumerate(building_levels):
                        level_context = f"{context} building_levels[{level_index}]"
                        if not isinstance(level_definition, dict) or not set(level_definition) <= BUILDING_LEVEL_FIELDS or 'z' not in level_definition or type(level_definition.get('z')) is not int:
                            self.add_error(file_path, f"{level_context} must define integer z and may only contain rooms and furniture_anchors.")
                            continue
                        level_rooms = level_definition.get('rooms')
                        if level_rooms is not None:
                            if not isinstance(level_rooms, list):
                                self.add_error(file_path, f"{level_context} rooms must be an array.")
                            else:
                                if len(level_rooms) != len(set(level_rooms)):
                                    self.add_error(file_path, f"{level_context} rooms must not duplicate room IDs.")
                                for room_id in level_rooms:
                                    if not isinstance(room_id, str) or room_id not in building_rooms:
                                        self.add_error(file_path, f"{level_context} rooms references room not owned by the building '{room_id}'.")
                        level_anchor_ids = level_definition.get('furniture_anchors')
                        if level_anchor_ids is not None:
                            if not isinstance(level_anchor_ids, list):
                                self.add_error(file_path, f"{level_context} furniture_anchors must be an array.")
                            elif len(level_anchor_ids) != len(set(level_anchor_ids)):
                                self.add_error(file_path, f"{level_context} furniture_anchors must not duplicate anchor IDs.")
                        level_z = level_definition['z']
                        if not 0 <= level_z <= 10:
                            self.add_error(file_path, f"{level_context} z must be an integer from 0 through 10.")
                        elif level_z % 2 != 0:
                            self.add_error(file_path, f"{level_context} z must be even; odd levels are intentional open gaps.")
                        if previous_z is not None and level_z <= previous_z:
                            self.add_error(file_path, f"{level_context} z must be strictly greater than the previous building level.")
                        previous_z = level_z
                    if isinstance(building_levels[0], dict) and building_levels[0].get('z') != 0:
                        self.add_error(file_path, f"{context} building_levels must start with ground floor z 0.")
                    if isinstance(building_levels, list) and building_levels:
                        level_room_lists = [level_definition.get('rooms') for level_definition in building_levels if isinstance(level_definition, dict) and 'rooms' in level_definition]
                        if level_room_lists:
                            assigned_rooms = [room_id for rooms_at_level in level_room_lists for room_id in (rooms_at_level or [])]
                            if set(assigned_rooms) != set(building_rooms) or len(assigned_rooms) != len(set(assigned_rooms)):
                                self.add_error(file_path, f"{context} building_levels rooms must assign every building room exactly once.")
                        level_anchor_lists = [level_definition.get('furniture_anchors') for level_definition in building_levels if isinstance(level_definition, dict) and 'furniture_anchors' in level_definition]
                        if level_anchor_lists:
                            assigned_anchors = [anchor_id for anchors_at_level in level_anchor_lists for anchor_id in (anchors_at_level or [])]
                            root_anchor_ids = {anchor.get('id') for anchor in building.get('furniture_anchors', []) if isinstance(anchor, dict)}
                            if set(assigned_anchors) != root_anchor_ids or len(assigned_anchors) != len(set(assigned_anchors)):
                                self.add_error(file_path, f"{context} building_levels furniture_anchors must assign every building anchor exactly once.")
                if z_valid and z != 0:
                    self.add_error(file_path, f"{context} z must be 0 when building_levels is declared.")
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
            exterior_context = building.get('exterior_context')
            if exterior_context is not None:
                if not isinstance(exterior_context, dict) or set(exterior_context) != BUILDING_EXTERIOR_CONTEXT_FIELDS:
                    self.add_error(file_path, f"{context} exterior_context must define at and z.")
                else:
                    at = exterior_context.get('at')
                    context_z = exterior_context.get('z')
                    if (
                        not isinstance(at, list)
                        or len(at) != 2
                        or any(type(value) is not int for value in at)
                        or not 0 <= at[0] < MAP_WIDTH
                        or not 0 <= at[1] < MAP_HEIGHT
                    ):
                        self.add_error(file_path, f"{context} exterior_context at must be a two-integer coordinate within map bounds.")
                    if type(context_z) is not int or context_z != z:
                        self.add_error(file_path, f"{context} exterior_context z must use building z {z}.")
            exterior_access_context = building.get('exterior_access_context')
            if exterior_access_context is not None:
                if (
                    not isinstance(exterior_access_context, dict)
                    or set(exterior_access_context) != BUILDING_EXTERIOR_ACCESS_CONTEXT_FIELDS
                    or not isinstance(exterior_access_context.get('connection'), str)
                    or not exterior_access_context['connection']
                ):
                    self.add_error(file_path, f"{context} exterior_access_context must define connection.")
                if exterior_context is None:
                    self.add_error(file_path, f"{context} exterior_access_context requires exterior_context.")
            entrance = building.get('entrance')
            entrances = building.get('entrances')
            if entrance is not None and entrances is not None:
                self.add_error(file_path, f"{context} entrance and entrances are mutually exclusive.")
            if entrance is not None:
                if (
                    not isinstance(entrance, dict)
                    or set(entrance) != BUILDING_ENTRANCE_FIELDS
                    or not isinstance(entrance.get('connection'), str)
                    or not entrance.get('connection')
                    or not isinstance(entrance.get('facing'), str)
                ):
                    self.add_error(file_path, f"{context} entrance must define connection and facing.")
                elif entrance['facing'] not in BUILDING_ENTRANCE_FACINGS:
                    self.add_error(file_path, f"{context} entrance.facing must be one of north, east, south, or west.")
                if exterior_context is None:
                    self.add_error(file_path, f"{context} entrance requires exterior_context.")
                if (
                    exterior_access_context is not None
                    and isinstance(exterior_access_context, dict)
                    and isinstance(entrance, dict)
                    and entrance.get('connection') != exterior_access_context.get('connection')
                ):
                    self.add_error(file_path, f"{context} entrance.connection must match exterior_access_context.connection.")
            if entrances is not None:
                if not isinstance(entrances, list) or not entrances:
                    self.add_error(file_path, f"{context} entrances must be a non-empty array.")
                else:
                    seen_entrance_ids: Set[str] = set()
                    seen_entrance_connections: Set[str] = set()
                    for ent_index, entrance_entry in enumerate(entrances):
                        ent_context = f"{context} entrances[{ent_index}]"
                        if (
                            not isinstance(entrance_entry, dict)
                            or set(entrance_entry) != BUILDING_ENTRANCES_ENTRY_FIELDS
                            or not isinstance(entrance_entry.get('id'), str)
                            or not entrance_entry.get('id')
                            or not isinstance(entrance_entry.get('connection'), str)
                            or not entrance_entry.get('connection')
                            or not isinstance(entrance_entry.get('facing'), str)
                        ):
                            self.add_error(file_path, f"{ent_context} must define id, connection, and facing.")
                        else:
                            if entrance_entry['facing'] not in BUILDING_ENTRANCE_FACINGS:
                                self.add_error(file_path, f"{ent_context} facing must be one of north, east, south, or west.")
                            if entrance_entry['id'] in seen_entrance_ids:
                                self.add_error(file_path, f"{ent_context} duplicates entrance id '{entrance_entry['id']}'.")
                            seen_entrance_ids.add(entrance_entry['id'])
                            if entrance_entry['connection'] in seen_entrance_connections:
                                self.add_error(file_path, f"{ent_context} duplicates connection '{entrance_entry['connection']}'.")
                            seen_entrance_connections.add(entrance_entry['connection'])
                    if exterior_context is None:
                        self.add_error(file_path, f"{context} entrances requires exterior_context.")
                    if (
                        exterior_access_context is not None
                        and isinstance(exterior_access_context, dict)
                        and isinstance(exterior_access_context.get('connection'), str)
                        and exterior_access_context.get('connection') not in seen_entrance_connections
                    ):
                        self.add_error(file_path, f"{context} exterior_access_context.connection must match one of the entrances connections.")
            access_validation = building.get('access_validation')
            staircases = building.get('staircases')
            if staircases is not None:
                if not isinstance(staircases, list) or not staircases:
                    self.add_error(file_path, f"{context} staircases must be a non-empty array.")
                else:
                    seen_staircase_ids: Set[str] = set()
                    for staircase_index, staircase in enumerate(staircases):
                        staircase_context = f"{context} staircases[{staircase_index}]"
                        if not isinstance(staircase, dict) or not {'id', 'lower_at', 'upper_at', 'rotation'} <= set(staircase) or not set(staircase) <= BUILDING_STAIRCASE_FIELDS:
                            self.add_error(file_path, f"{staircase_context} must define id, lower_at, upper_at, and rotation.")
                            continue
                        staircase_id = staircase.get('id')
                        if not isinstance(staircase_id, str) or not staircase_id:
                            self.add_error(file_path, f"{staircase_context} id must be a non-empty string.")
                        elif staircase_id in seen_staircase_ids:
                            self.add_error(file_path, f"{staircase_context} duplicates staircase ID '{staircase_id}'.")
                        seen_staircase_ids.add(staircase_id)
                        for coordinate_name in ('lower_at', 'upper_at'):
                            coordinate = staircase.get(coordinate_name)
                            if not isinstance(coordinate, list) or len(coordinate) != 2 or not all(type(value) is int for value in coordinate):
                                self.add_error(file_path, f"{staircase_context} {coordinate_name} must be a two-integer coordinate.")
                        rotation = staircase.get('rotation')
                        if type(rotation) is not int or rotation not in {0, 90, 180, 270}:
                            self.add_error(file_path, f"{staircase_context} rotation must be 0, 90, 180, or 270.")
                        upper_rotation = staircase.get('upper_rotation', rotation)
                        if type(upper_rotation) is not int or upper_rotation not in {0, 90, 180, 270}:
                            self.add_error(file_path, f"{staircase_context} upper_rotation must be 0, 90, 180, or 270.")
                        for coordinate_name in ('landing_at', 'upper_clearance_at'):
                            coordinate = staircase.get(coordinate_name)
                            if coordinate is not None and (
                                not isinstance(coordinate, list)
                                or len(coordinate) != 2
                                or not all(type(value) is int for value in coordinate)
                            ):
                                self.add_error(file_path, f"{staircase_context} {coordinate_name} must be a two-integer coordinate.")
                    declared_level_zs = {level_definition.get('z') for level_definition in building_levels if isinstance(level_definition, dict)} if isinstance(building_levels, list) else set()
                    if not {0, 2} <= declared_level_zs:
                        self.add_error(file_path, f"{context} staircases require declared building levels z 0 and z 2.")
                if building_levels is None:
                    self.add_error(file_path, f"{context} staircases require building_levels.")
            if access_validation is not None and access_validation not in BUILDING_ACCESS_VALIDATIONS:
                self.add_error(file_path, f"{context} access_validation has unsupported validation '{access_validation}'.")
            entrance_validation = building.get('entrance_validation')
            if entrance_validation is not None:
                if entrance_validation not in BUILDING_ENTRANCE_VALIDATIONS:
                    self.add_error(file_path, f"{context} entrance_validation has unsupported validation '{entrance_validation}'.")
                if entrance is None and entrances is None:
                    self.add_error(file_path, f"{context} entrance_validation requires entrance or entrances.")
            reachability_validation = building.get('reachability_validation')
            if reachability_validation is not None:
                rv_context = f"{context} reachability_validation"
                if not isinstance(reachability_validation, dict):
                    self.add_error(file_path, f"{rv_context} must be an object.")
                else:
                    unknown_rv_fields = sorted(set(reachability_validation) - BUILDING_REACHABILITY_FIELDS)
                    for unknown_field in unknown_rv_fields:
                        self.add_error(file_path, f"unknown {rv_context} field '{unknown_field}'.")
                    if not reachability_validation:
                        self.add_error(file_path, f"{rv_context} must define at least one requirement.")
                    declared_entrance_ids = {
                        entry.get('id') for entry in (building.get('entrances') or [])
                        if isinstance(entry, dict) and isinstance(entry.get('id'), str)
                    }
                    declared_anchor_ids = {
                        anchor.get('id') for anchor in (building.get('furniture_anchors') or [])
                        if isinstance(anchor, dict) and isinstance(anchor.get('id'), str)
                    }
                    declared_level_zs = {
                        level_definition.get('z') for level_definition in (building.get('building_levels') or [])
                        if isinstance(level_definition, dict)
                    } or {building.get('z')}
                    for requirement_name in ('required_entrances', 'required_furniture_anchors', 'required_building_levels'):
                        if requirement_name not in reachability_validation:
                            continue
                        requirement = reachability_validation[requirement_name]
                        if not isinstance(requirement, list) or not requirement:
                            self.add_error(file_path, f"{rv_context} {requirement_name} must be a non-empty array.")
                            continue
                        if len(requirement) != len(set(requirement)):
                            self.add_error(file_path, f"{rv_context} {requirement_name} must not duplicate entries.")
                        if requirement_name == 'required_building_levels':
                            if any(type(value) is not int for value in requirement):
                                self.add_error(file_path, f"{rv_context} {requirement_name} must contain integers.")
                                continue
                            for level_z in requirement:
                                if level_z not in declared_level_zs:
                                    self.add_error(file_path, f"{rv_context} required_building_levels references undeclared building level z {level_z}.")
                        else:
                            if any(not isinstance(value, str) or not value.strip() for value in requirement):
                                self.add_error(file_path, f"{rv_context} {requirement_name} must contain non-empty strings.")
                                continue
                            if requirement_name == 'required_entrances':
                                for entrance_id in requirement:
                                    if entrance_id not in declared_entrance_ids:
                                        self.add_error(file_path, f"{rv_context} required_entrances references unknown entrance '{entrance_id}'.")
                            else:
                                for anchor_id in requirement:
                                    if anchor_id not in declared_anchor_ids:
                                        self.add_error(file_path, f"{rv_context} required_furniture_anchors references unknown furniture anchor '{anchor_id}'.")
            furniture_anchors = building.get('furniture_anchors')
            if furniture_anchors is not None:
                if not isinstance(furniture_anchors, list) or not furniture_anchors:
                    self.add_error(file_path, f"{context} furniture_anchors must be a non-empty array.")
                else:
                    seen_anchor_ids: Set[str] = set()
                    for anchor_index, anchor in enumerate(furniture_anchors):
                        anchor_context = f"{context} furniture_anchors[{anchor_index}]"
                        if (
                            not isinstance(anchor, dict)
                            or set(anchor) != BUILDING_FURNITURE_ANCHOR_FIELDS
                            or not isinstance(anchor.get('id'), str)
                            or not anchor.get('id')
                            or not isinstance(anchor.get('kind'), str)
                            or not anchor.get('kind')
                        ):
                            self.add_error(file_path, f"{anchor_context} must define id, at, z, and kind.")
                        else:
                            if anchor['id'] in seen_anchor_ids:
                                self.add_error(file_path, f"{anchor_context} duplicates anchor id '{anchor['id']}'.")
                            seen_anchor_ids.add(anchor['id'])
                        if isinstance(anchor, dict):
                            anchor_at = anchor.get('at')
                            if (
                                not isinstance(anchor_at, list)
                                or len(anchor_at) != 2
                                or not all(type(value) is int for value in anchor_at)
                                or not 0 <= anchor_at[0] < MAP_WIDTH
                                or not 0 <= anchor_at[1] < MAP_HEIGHT
                            ):
                                self.add_error(file_path, f"{anchor_context} at must be a two-integer coordinate within map bounds.")
                            anchor_z = anchor.get('z')
                            if anchor_z is not None and (type(anchor_z) is not int or not -10 <= anchor_z <= 10):
                                self.add_error(file_path, f"{anchor_context} z must be an integer from -10 through 10.")
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
                owned_room_levels = [
                    level_definition['z']
                    for level_definition in building.get('building_levels', [])
                    if room_id in level_definition.get('rooms', [])
                ] if building.get('building_levels') else [z]
                memberships = []
                for level_index, level in enumerate(levels if isinstance(levels, list) else []):
                    if not isinstance(level, list) or len(level) != POPULATED_LEVEL_TILE_COUNT:
                        continue
                    for tile_index, tile in enumerate(level):
                        if isinstance(tile, dict) and tile.get('rooms') == [room_id]:
                            memberships.append((level_index - 10, tile_index % MAP_WIDTH, tile_index // MAP_WIDTH))
                if z in owned_room_levels and not memberships:
                    self.add_error(file_path, f"{context} room '{room_id}' has no membership at z {z}.")
                    continue
                for membership_z, x, y in memberships:
                    if membership_z not in owned_room_levels:
                        if building.get('building_levels'):
                            self.add_error(file_path, f"{context} room '{room_id}' has membership at undeclared building level z {membership_z}.")
                        else:
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
            if building.get('exterior_access_context') is not None and isinstance(building.get('exterior_access_context'), dict):
                connection_id = building['exterior_access_context'].get('connection')
                matching_connections = [
                    connection for connection in validated_room_connections
                    if connection.get('id') == connection_id
                ]
                if not matching_connections:
                    self.add_error(file_path, f"{context} exterior_access_context references unknown room connection '{connection_id}'.")
                else:
                    connection = matching_connections[0]
                    endpoints = (connection['from'], connection['to'])
                    named_rooms = [endpoint['id'] for endpoint in endpoints if endpoint.get('kind') == 'room']
                    if (
                        connection['z'] != z
                        or not any(endpoint.get('kind') == 'exterior' for endpoint in endpoints)
                        or len(named_rooms) != 1
                        or named_rooms[0] not in building['rooms']
                    ):
                        self.add_error(file_path, f"{context} exterior_access_context must reference a room-to-exterior connection owned by the building.")
            if building.get('entrance') is not None and isinstance(building.get('entrance'), dict):
                entrance = building['entrance']
                connection_id = entrance.get('connection')
                matching_connections = [
                    connection for connection in validated_room_connections
                    if connection.get('id') == connection_id
                ]
                if not matching_connections:
                    self.add_error(file_path, f"{context} entrance references unknown room connection '{connection_id}'.")
                else:
                    connection = matching_connections[0]
                    endpoints = (connection['from'], connection['to'])
                    named_rooms = [endpoint['id'] for endpoint in endpoints if endpoint.get('kind') == 'room']
                    if (
                        connection['z'] != z
                        or not any(endpoint.get('kind') == 'exterior' for endpoint in endpoints)
                        or len(named_rooms) != 1
                        or named_rooms[0] not in building['rooms']
                    ):
                        self.add_error(file_path, f"{context} entrance must reference a room-to-exterior connection owned by the building.")
                facing = entrance.get('facing')
                exterior_context = building.get('exterior_context')
                if (
                    facing in CARDINAL_SIDES
                    and isinstance(exterior_context, dict)
                    and isinstance(exterior_context.get('at'), list)
                    and len(exterior_context['at']) == 2
                    and all(type(value) is int for value in exterior_context['at'])
                ):
                    context_x, context_y = exterior_context['at']
                    delta_x, delta_y = CARDINAL_SIDES[facing]
                    facing_x = context_x + delta_x
                    facing_y = context_y + delta_y
                    if not (
                        footprint['x'] <= facing_x < footprint['x'] + footprint['width']
                        and footprint['y'] <= facing_y < footprint['y'] + footprint['height']
                    ):
                        self.add_error(file_path, f"{context} entrance.facing '{facing}' does not point from exterior_context toward the building footprint.")
            if building.get('entrances') is not None and isinstance(building.get('entrances'), list):
                entrances = building['entrances']
                primary_connection = None
                exterior_access_context = building.get('exterior_access_context')
                if isinstance(exterior_access_context, dict) and isinstance(exterior_access_context.get('connection'), str):
                    primary_connection = exterior_access_context.get('connection')
                for ent_index, entrance_entry in enumerate(entrances):
                    if not isinstance(entrance_entry, dict):
                        continue
                    ent_context = f"{context} entrances[{ent_index}]"
                    connection_id = entrance_entry.get('connection')
                    matching_connections = [
                        connection for connection in validated_room_connections
                        if connection.get('id') == connection_id
                    ]
                    if not matching_connections:
                        self.add_error(file_path, f"{ent_context} references unknown room connection '{connection_id}'.")
                    else:
                        connection = matching_connections[0]
                        endpoints = (connection['from'], connection['to'])
                        named_rooms = [endpoint['id'] for endpoint in endpoints if endpoint.get('kind') == 'room']
                        if (
                            connection['z'] != z
                            or not any(endpoint.get('kind') == 'exterior' for endpoint in endpoints)
                            or len(named_rooms) != 1
                            or named_rooms[0] not in building['rooms']
                        ):
                            self.add_error(file_path, f"{ent_context} must reference a room-to-exterior connection owned by the building.")
                    facing = entrance_entry.get('facing')
                    exterior_context = building.get('exterior_context')
                    is_primary = (
                        primary_connection is not None and connection_id == primary_connection
                    ) or (primary_connection is None and ent_index == 0)
                    if (
                        is_primary
                        and facing in CARDINAL_SIDES
                        and isinstance(exterior_context, dict)
                        and isinstance(exterior_context.get('at'), list)
                        and len(exterior_context['at']) == 2
                        and all(type(value) is int for value in exterior_context['at'])
                    ):
                        context_x, context_y = exterior_context['at']
                        delta_x, delta_y = CARDINAL_SIDES[facing]
                        facing_x = context_x + delta_x
                        facing_y = context_y + delta_y
                        if not (
                            footprint['x'] <= facing_x < footprint['x'] + footprint['width']
                            and footprint['y'] <= facing_y < footprint['y'] + footprint['height']
                        ):
                            self.add_error(file_path, f"{ent_context} facing '{facing}' does not point from exterior_context toward the building footprint.")
            if building.get('entrance_validation') == 'complete':
                entrance = building.get('entrance')
                entrances_list = building.get('entrances')
                if isinstance(entrance, dict):
                    entries = [{'connection': entrance.get('connection'), 'facing': entrance.get('facing')}]
                elif isinstance(entrances_list, list):
                    entries = entrances_list
                else:
                    entries = []
                primary_connection = None
                exterior_access_context = building.get('exterior_access_context')
                if isinstance(exterior_access_context, dict) and isinstance(exterior_access_context.get('connection'), str):
                    primary_connection = exterior_access_context.get('connection')
                for ent_index, entry in enumerate(entries):
                    if not isinstance(entry, dict):
                        continue
                    entrance_facing = entry.get('facing')
                    entrance_connection_id = entry.get('connection')
                    matching_entrance_connections = [
                        conn for conn in validated_room_connections
                        if conn.get('id') == entrance_connection_id
                    ]
                    if not matching_entrance_connections:
                        continue
                    entrance_connection = matching_entrance_connections[0]
                    door_x, door_y = entrance_connection['at']
                    door_boundary = None
                    for boundary in validated_room_boundaries:
                        if (
                            boundary['at'] == [door_x, door_y]
                            and boundary['z'] == z
                            and boundary['element'] == 'door_furniture'
                            and boundary['room'] in building['rooms']
                        ):
                            door_boundary = boundary
                            break
                    if door_boundary is None:
                        self.add_error(file_path, f"{context} entrance_validation requires a door_furniture boundary at the entrance connection.")
                    else:
                        if door_boundary.get('side') is None:
                            self.add_error(file_path, f"{context} entrance_validation requires a side on the door_furniture boundary.")
                        elif entrance_facing in OPPOSITE_SIDES and door_boundary['side'] != OPPOSITE_SIDES[entrance_facing]:
                            self.add_error(file_path, f"{context} entrance_validation door side '{door_boundary['side']}' must face '{OPPOSITE_SIDES[entrance_facing]}'.")
                    is_primary = (
                        primary_connection is not None and entrance_connection_id == primary_connection
                    ) or (primary_connection is None and ent_index == 0)
                    if is_primary:
                        ext_ctx = building.get('exterior_context')
                        if (
                            isinstance(ext_ctx, dict)
                            and isinstance(ext_ctx.get('at'), list)
                            and len(ext_ctx['at']) == 2
                            and all(type(value) is int for value in ext_ctx['at'])
                        ):
                            ctx_x, ctx_y = ext_ctx['at']
                            if entrance_facing in ('east', 'west'):
                                if not (footprint['y'] <= ctx_y < footprint['y'] + footprint['height']
                                        and footprint['y'] <= door_y < footprint['y'] + footprint['height']):
                                    self.add_error(file_path, f"{context} entrance_validation requires exterior_context and entrance door aligned within the footprint height.")
                            elif entrance_facing in ('north', 'south'):
                                if not (footprint['x'] <= ctx_x < footprint['x'] + footprint['width']
                                        and footprint['x'] <= door_x < footprint['x'] + footprint['width']):
                                    self.add_error(file_path, f"{context} entrance_validation requires exterior_context and entrance door aligned within the footprint width.")
            if building.get('furniture_anchors') is not None and isinstance(building.get('furniture_anchors'), list):
                for anchor_index, anchor in enumerate(building['furniture_anchors']):
                    if not isinstance(anchor, dict):
                        continue
                    anchor_context = f"{context} furniture_anchors[{anchor_index}]"
                    anchor_at = anchor.get('at')
                    anchor_z = anchor.get('z')
                    if isinstance(anchor_at, list) and len(anchor_at) == 2 and all(type(value) is int for value in anchor_at):
                        anchor_x, anchor_y = anchor_at
                        if not (footprint['x'] <= anchor_x < footprint['x'] + footprint['width']
                                and footprint['y'] <= anchor_y < footprint['y'] + footprint['height']):
                            self.add_error(file_path, f"{anchor_context} at [{anchor_x}, {anchor_y}] is outside building footprint.")
                    if building.get('building_levels') is not None:
                        declared_level_zs = {level_definition['z'] for level_definition in building['building_levels']}
                        if isinstance(anchor_z, int) and anchor_z not in declared_level_zs:
                            self.add_error(file_path, f"{anchor_context} z must name a declared building level.")
                    elif isinstance(anchor_z, int) and anchor_z != z:
                        self.add_error(file_path, f"{anchor_context} z must use building z {z}.")
                    if isinstance(anchor_z, int) and (anchor_z in ({level_definition['z'] for level_definition in building.get('building_levels', [])} if building.get('building_levels') else {z})):
                        if isinstance(anchor_at, list) and len(anchor_at) == 2 and all(type(value) is int for value in anchor_at):
                            anchor_x, anchor_y = anchor_at
                            level_index = anchor_z + 10
                            level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
                            tile = level[anchor_y * MAP_WIDTH + anchor_x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
                            feature = tile.get('feature') if isinstance(tile, dict) else None
                            if (
                                not isinstance(feature, dict)
                                or feature.get('type') != 'furniture'
                                or not isinstance(feature.get('id'), str)
                                or not feature.get('id')
                            ):
                                self.add_error(file_path, f"{anchor_context} must reference furniture at [{anchor_at[0]}, {anchor_at[1]}] on z {z}.")
            if building.get('staircases') is not None and isinstance(building.get('staircases'), list):
                declared_level_zs = {level_definition.get('z') for level_definition in building.get('building_levels', []) if isinstance(level_definition, dict)}
                slope_tile_ids = self._slope_tile_ids()
                for staircase_index, staircase in enumerate(building['staircases']):
                    if not isinstance(staircase, dict):
                        continue
                    staircase_context = f"{context} staircases[{staircase_index}]"
                    lower_at = staircase.get('lower_at')
                    upper_at = staircase.get('upper_at')
                    if not isinstance(lower_at, list) or not isinstance(upper_at, list) or len(lower_at) != 2 or len(upper_at) != 2 or not all(type(value) is int for value in lower_at + upper_at):
                        continue
                    lower_x, lower_y = lower_at
                    upper_x, upper_y = upper_at
                    landing_at = staircase.get('landing_at')
                    upper_clearance_at = staircase.get('upper_clearance_at')
                    if not (footprint['x'] <= lower_x < footprint['x'] + footprint['width'] and footprint['y'] <= lower_y < footprint['y'] + footprint['height'] and footprint['x'] <= upper_x < footprint['x'] + footprint['width'] and footprint['y'] <= upper_y < footprint['y'] + footprint['height']):
                        self.add_error(file_path, f"{staircase_context} slope coordinates must be inside building footprint.")
                    if (lower_x, lower_y) == (upper_x, upper_y):
                        self.add_error(file_path, f"{staircase_context} lower_at and upper_at must not stack at the same coordinates.")
                    lower_rotation = staircase.get('rotation')
                    upper_rotation = staircase.get('upper_rotation', lower_rotation)
                    if landing_at is None:
                        if abs(lower_x - upper_x) + abs(lower_y - upper_y) != 1:
                            self.add_error(file_path, f"{staircase_context} lower_at and upper_at must be cardinally adjacent.")
                    else:
                        if not isinstance(landing_at, list) or len(landing_at) != 2 or not all(type(value) is int for value in landing_at):
                            continue
                        landing_x, landing_y = landing_at
                        if not (footprint['x'] <= landing_x < footprint['x'] + footprint['width'] and footprint['y'] <= landing_y < footprint['y'] + footprint['height']):
                            self.add_error(file_path, f"{staircase_context} landing_at must be inside building footprint.")
                        if abs(lower_x - landing_x) + abs(lower_y - landing_y) != 1:
                            self.add_error(file_path, f"{staircase_context} landing_at must be cardinally adjacent to lower_at.")
                        if abs(upper_x - landing_x) + abs(upper_y - landing_y) != 1:
                            self.add_error(file_path, f"{staircase_context} landing_at must be cardinally adjacent to upper_at.")
                    if upper_clearance_at is not None and isinstance(upper_clearance_at, list) and len(upper_clearance_at) == 2 and all(type(value) is int for value in upper_clearance_at):
                        clearance_x, clearance_y = upper_clearance_at
                        if not (footprint['x'] <= clearance_x < footprint['x'] + footprint['width'] and footprint['y'] <= clearance_y < footprint['y'] + footprint['height']):
                            self.add_error(file_path, f"{staircase_context} upper_clearance_at must be inside building footprint.")
                        else:
                            clearance_level = levels[12] if isinstance(levels, list) and len(levels) > 12 else []
                            clearance_tile = clearance_level[clearance_y * MAP_WIDTH + clearance_x] if isinstance(clearance_level, list) and len(clearance_level) == POPULATED_LEVEL_TILE_COUNT else {}
                            if clearance_tile != {}:
                                self.add_error(file_path, f"{staircase_context} upper_clearance_at must be empty on z 2.")
                    if not {0, 2}.issubset(declared_level_zs):
                        continue
                    for slope_z, coordinate, slope_rotation in ((1, lower_at, lower_rotation), (2, upper_at, upper_rotation)):
                        slope_x, slope_y = coordinate
                        level_index = slope_z + 10
                        level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
                        tile = level[slope_y * MAP_WIDTH + slope_x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
                        if not isinstance(tile, dict) or tile.get('id') not in slope_tile_ids or tile.get('rotation', 0) != slope_rotation:
                            self.add_error(file_path, f"{staircase_context} requires a slope tile with rotation {slope_rotation} at [{slope_x}, {slope_y}] on z {slope_z}.")
                    if landing_at is not None and isinstance(landing_at, list) and len(landing_at) == 2 and all(type(value) is int for value in landing_at):
                        landing_x, landing_y = landing_at
                        level_index = 1 + 10
                        level = levels[level_index] if isinstance(levels, list) and level_index < len(levels) else []
                        tile = level[landing_y * MAP_WIDTH + landing_x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
                        if not isinstance(tile, dict) or not tile.get('id') or tile.get('id') in slope_tile_ids:
                            self.add_error(file_path, f"{staircase_context} requires a flat landing block at [{landing_x}, {landing_y}] on z 1.")
            if building.get('exterior_context') is not None and isinstance(building.get('exterior_context'), dict):
                exterior_context = building['exterior_context']
                at = exterior_context.get('at')
                if isinstance(at, list) and len(at) == 2 and all(type(value) is int for value in at):
                    context_x, context_y = at
                    if footprint['x'] <= context_x < footprint['x'] + footprint['width'] and footprint['y'] <= context_y < footprint['y'] + footprint['height']:
                        self.add_error(file_path, f"{context} exterior_context must be outside the building footprint.")
                    adjacent = any(
                        footprint['x'] <= context_x + dx < footprint['x'] + footprint['width']
                        and footprint['y'] <= context_y + dy < footprint['y'] + footprint['height']
                        for dx, dy in CARDINAL_SIDES.values()
                    )
                    if not adjacent:
                        self.add_error(file_path, f"{context} exterior_context must be cardinally adjacent to the building footprint.")
                    level_index = z + 10
                    level = levels[level_index] if isinstance(levels, list) and 0 <= level_index < len(levels) else []
                    terrain = level[context_y * MAP_WIDTH + context_x] if isinstance(level, list) and len(level) == POPULATED_LEVEL_TILE_COUNT else {}
                    if not isinstance(terrain, dict) or not isinstance(terrain.get('id'), str) or not terrain.get('id'):
                        self.add_error(file_path, f"{context} exterior_context must reference existing terrain.")
                    elif terrain.get('rooms'):
                        self.add_error(file_path, f"{context} exterior_context must not reference a room membership.")
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
            if building.get('reachability_validation') is not None:
                reachability = building['reachability_validation']
                level_of_room = {room_id: z for room_id in building['rooms']}
                for level_definition in building.get('building_levels') or []:
                    if not isinstance(level_definition, dict):
                        continue
                    for room_id in level_definition.get('rooms') or []:
                        level_of_room[room_id] = level_definition['z']
                room_nodes = {(room_id, level_of_room[room_id]) for room_id in building['rooms']}
                room_graph = {node: set() for node in room_nodes}
                seed_nodes: Set[Tuple[str, int]] = set()
                required_entrance_ids = reachability.get('required_entrances')
                entrance_records = building.get('entrances') or []
                if required_entrance_ids is not None:
                    entrance_records = [entry for entry in entrance_records if entry.get('id') in set(required_entrance_ids)]
                for entrance_entry in entrance_records:
                    connection = next(
                        (conn for conn in validated_room_connections if conn.get('id') == entrance_entry.get('connection')),
                        None,
                    )
                    if connection is None:
                        continue
                    named_rooms = [endpoint['id'] for endpoint in (connection['from'], connection['to']) if endpoint.get('kind') == 'room']
                    for room_id in named_rooms:
                        if room_id in level_of_room and connection['z'] == level_of_room[room_id]:
                            seed_nodes.add((room_id, level_of_room[room_id]))
                for connection in validated_room_connections:
                    endpoints = (connection['from'], connection['to'])
                    room_endpoints = [endpoint['id'] for endpoint in endpoints if endpoint.get('kind') == 'room']
                    if any(endpoint.get('kind') == 'exterior' for endpoint in endpoints):
                        if required_entrance_ids is None:
                            for room_id in room_endpoints:
                                if room_id in level_of_room and connection['z'] == level_of_room[room_id]:
                                    seed_nodes.add((room_id, level_of_room[room_id]))
                    elif len(room_endpoints) == 2 and all(room_id in level_of_room for room_id in room_endpoints):
                        left_level = level_of_room[room_endpoints[0]]
                        right_level = level_of_room[room_endpoints[1]]
                        if left_level == right_level and connection['z'] == left_level:
                            left_node = (room_endpoints[0], left_level)
                            right_node = (room_endpoints[1], right_level)
                            room_graph[left_node].add(right_node)
                            room_graph[right_node].add(left_node)
                for staircase in building.get('staircases') or []:
                    lower_at = staircase.get('lower_at')
                    upper_at = staircase.get('upper_at')
                    lower_tile = (
                        levels[10][lower_at[1] * MAP_WIDTH + lower_at[0]]
                        if isinstance(lower_at, list) and len(lower_at) == 2 and len(levels) > 10 and len(levels[10]) == POPULATED_LEVEL_TILE_COUNT
                        else {}
                    )
                    upper_tile = (
                        levels[12][upper_at[1] * MAP_WIDTH + upper_at[0]]
                        if isinstance(upper_at, list) and len(upper_at) == 2 and len(levels) > 12 and len(levels[12]) == POPULATED_LEVEL_TILE_COUNT
                        else {}
                    )
                    lower_room_ids = lower_tile.get('rooms', []) if isinstance(lower_tile, dict) else []
                    upper_room_ids = upper_tile.get('rooms', []) if isinstance(upper_tile, dict) else []
                    lower_node = next(
                        ((room_id, 0) for room_id in lower_room_ids if (room_id, 0) in room_nodes),
                        None,
                    )
                    upper_node = next(
                        ((room_id, 2) for room_id in upper_room_ids if (room_id, 2) in room_nodes),
                        None,
                    )
                    if lower_node is None:
                        lower_node = next((node for node in sorted(room_nodes) if node[1] == 0), None)
                    if upper_node is None:
                        upper_node = next((node for node in sorted(room_nodes) if node[1] == 2), None)
                    if lower_node is not None and upper_node is not None:
                        room_graph[lower_node].add(upper_node)
                        room_graph[upper_node].add(lower_node)
                reachable_nodes = set(seed_nodes)
                frontier = list(seed_nodes)
                while frontier:
                    node = frontier.pop()
                    for connected_node in room_graph[node]:
                        if connected_node not in reachable_nodes:
                            reachable_nodes.add(connected_node)
                            frontier.append(connected_node)
                reachable_levels = {node[1] for node in reachable_nodes}
                if 'required_entrances' in reachability:
                    for entrance_entry in entrance_records:
                        connection = next(
                            (conn for conn in validated_room_connections if conn.get('id') == entrance_entry.get('connection')),
                            None,
                        )
                        if connection is None:
                            continue
                        named_rooms = [endpoint['id'] for endpoint in (connection['from'], connection['to']) if endpoint.get('kind') == 'room']
                        if not any((room_id, level_of_room.get(room_id)) in reachable_nodes for room_id in named_rooms):
                            self.add_error(file_path, f"{context} reachability_validation entrance '{entrance_entry.get('id')}' is not reachable.")
                if 'required_furniture_anchors' in reachability:
                    anchor_level = {
                        anchor.get('id'): anchor.get('z') for anchor in (building.get('furniture_anchors') or [])
                        if isinstance(anchor, dict)
                    }
                    for anchor_id in reachability['required_furniture_anchors']:
                        if not any(node[1] == anchor_level.get(anchor_id) for node in reachable_nodes):
                            self.add_error(file_path, f"{context} reachability_validation furniture anchor '{anchor_id}' is not reachable from the required entrances.")
                if 'required_building_levels' in reachability:
                    for level_z in reachability['required_building_levels']:
                        if level_z not in reachable_levels:
                            self.add_error(file_path, f"{context} reachability_validation building level z {level_z} is not reachable from the required entrances.")

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
            z = surface.get('z')
            if type(z) is not int or not -10 <= z <= 10:
                self.add_error(file_path, f"{context} z must be an integer from -10 through 10.")
            elif building is not None:
                building_levels = building.get('building_levels')
                if building_levels is not None:
                    declared_zs = [level_definition.get('z') for level_definition in building_levels if isinstance(level_definition, dict)]
                    if z not in declared_zs:
                        self.add_error(file_path, f"{context} z must name a declared building level for building '{building_id}'.")
                    if kind == 'roof' and z != max(declared_zs):
                        self.add_error(file_path, f"{context} roof must be at highest declared building level z {max(declared_zs)}.")
                    if kind == 'ceiling' and z == building['z']:
                        self.add_error(file_path, f"{context} ceiling cannot be declared at ground level z {z}.")
                    surface_key = (building_id, kind, z)
                    if surface_key in seen_surface_kinds:
                        self.add_error(file_path, f"{context} duplicates {kind} surface at z {z} for building '{building_id}'.")
                    seen_surface_kinds.add(surface_key)
                else:
                    if kind == 'floor':
                        self.add_error(file_path, f"{context} kind 'floor' requires multi-level building_levels.")
                    if z != building['z'] + 1:
                        self.add_error(file_path, f"{context} z must be immediately above building '{building_id}' at z {building['z'] + 1}.")
                    surface_key = (building_id, kind)
                    if surface_key in seen_surface_kinds:
                        self.add_error(file_path, f"{context} duplicates {kind} surface for building '{building_id}'.")
                    seen_surface_kinds.add(surface_key)

        seen_support_ids: Set[str] = set()
        for idx, support in enumerate(building_supports):
            context = f"Building support at index {idx}"
            if not isinstance(support, dict) or set(support) != BUILDING_SUPPORT_FIELDS:
                self.add_error(file_path, f"{context} must define id, building, at, from_z, to_z, and kind.")
                continue
            support_id = support.get('id')
            if not isinstance(support_id, str) or not support_id:
                self.add_error(file_path, f"{context} has invalid or missing ID.")
            elif support_id in seen_support_ids:
                self.add_error(file_path, f"Duplicate building support ID detected: '{support_id}'")
            seen_support_ids.add(support_id)
            building = building_by_id.get(support.get('building'))
            if building is None:
                self.add_error(file_path, f"{context} references non-existent building '{support.get('building')}'.")
                continue
            at = support.get('at')
            footprint = building['footprint']
            if not isinstance(at, list) or len(at) != 2 or not all(type(value) is int for value in at) or not (footprint['x'] <= at[0] < footprint['x'] + footprint['width'] and footprint['y'] <= at[1] < footprint['y'] + footprint['height']):
                self.add_error(file_path, f"{context} at must be inside building footprint.")
            declared_zs = {level.get('z') for level in building.get('building_levels', []) if isinstance(level, dict)}
            if type(support.get('from_z')) is not int or type(support.get('to_z')) is not int or support.get('from_z') not in declared_zs or support.get('to_z') not in declared_zs or support.get('from_z') >= support.get('to_z'):
                self.add_error(file_path, f"{context} from_z and to_z must be ascending declared building levels.")
            if support.get('kind') not in BUILDING_SUPPORT_KINDS:
                self.add_error(file_path, f"{context} has unsupported kind '{support.get('kind')}'.")

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
            required_kinds = ('roof', 'ceiling')
            for kind in required_kinds:
                if kind not in surface_kinds:
                    self.add_error(file_path, f"Building at index {index} requires {kind} surface for its declared levels.")
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
