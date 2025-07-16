## Selected maintenance goal
- **Refactor for Readability & Maintainability**

## Pre-Feature Development Project Tree
```
$(tree -L 1 -I '.git|addons|.*')
```

## Relevant Files

### Proposed New Files
- `Scripts/Helper/logger.gd` – Centralized logging utility for consistent debug output.
- `Tests/Unit/test_logger.gd` – Unit tests for `logger.gd`.

### Existing Files Modified
- `Scripts/BuildManager.gd` – Refactor construction logic, add enums, and use logger.
- `LevelGenerator.gd` – Simplify chunk queue management.
- `Scripts/Helper/json_helper.gd` – Extract common file operations and add error handling.
- `Scripts/general.gd` – Document functions and clean action timer logic.
- `/Tests/Unit/*` – Add or adjust tests for refactored functions.

### Files To Remove
- *(none)*

### Notes
- Unit tests should be placed under `/Tests/Unit/`.

## Tasks
- [ ] **1.0 Introduce centralized logging utility**
  - [ ] 1.1 Create `Scripts/Helper/logger.gd` with typed log level enum and functions `debug`, `info`, `warn`, `error`.
  - [ ] 1.2 Add Godot documentation comments to describe usage and parameters.
  - [ ] 1.3 Implement `/Tests/Unit/test_logger.gd` verifying log functions return expected strings or behavior.
- [ ] **2.0 Refactor `BuildManager.gd` for clarity**
  - [ ] 2.1 Define enum for construction types to replace string literals.
  - [ ] 2.2 Replace `print_debug` calls with `Helper.logger.debug`.
  - [ ] 2.3 Break up long functions (`handle_block_construction`, etc.) into smaller helpers where appropriate.
  - [ ] 2.4 Add unit tests covering `calculate_local_position` and new helpers.
- [ ] **3.0 Simplify `LevelGenerator.gd` queue management**
  - [ ] 3.1 Extract queue update logic into dedicated methods with documentation.
  - [ ] 3.2 Use typed arrays for `load_queue` and `unload_queue`.
  - [ ] 3.3 Add unit tests ensuring queue deduplication and proper chunk loading order.
- [ ] **4.0 Improve `json_helper.gd` file handling**
  - [ ] 4.1 Add utility methods for file open/close with error handling.
  - [ ] 4.2 Update existing JSON functions to use these utilities.
  - [ ] 4.3 Ensure functions return informative errors and write tests for failure cases.
- [ ] **5.0 Document and clean up `general.gd`**
  - [ ] 5.1 Add comments describing the action timer workflow.
  - [ ] 5.2 Simplify or remove redundant `is_action_in_progress` checks.
  - [ ] 5.3 Add unit test for `string_to_vector2` edge cases.
