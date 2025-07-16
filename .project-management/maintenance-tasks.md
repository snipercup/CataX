## Rule: Generating a Maintenance Task list

### Goal  
To guide an AI assistant in creating a detailed, step-by-step task list in Markdown format based on the findings after analyzing the existing codebase. The task list should guide a developer through implementation.


---
### Refactoring & Code Quality Improvement Goals

- **Refactor for Readability & Maintainability**:  
  Identify functions or modules (excluding the addons/ folder) that could benefit from refactoring and simplifying complex code. Find opportunities to improve readability, maintainability, or reduce code duplication.

- **Error Handling Review**:  
  Review error handling patterns across the codebase and propose improvements to make error messages clearer, logging more consistent, or edge cases better covered.

- **Bug & Logic Error Identification**:  
  Analyze the codebase (excluding addons/) for bugs, logic errors, or overlooked edge cases, and create detailed tasks to fix them.

- **Decouple Tightly Coupled Scripts & Scenes**:  
  Identify tightly coupled scripts and scenes and propose strategies to decouple them using best practices such as signals, event buses, or service locators.

- **Content & Data Structure Review**:  
  Review mod definitions (items, mobs, tiles, furniture) and data structures in `/mods` for consistency, completeness, and usability improvements.

- **Test Coverage & QA Enhancement**:  
  Examine test coverage and propose test cases for weak or untested systems, including mod validation. Use GUT (Godot Unit Test).

- **Performance Optimization**:  
  Identify performance-critical paths (rendering, AI, loops) and propose tasks to improve framerate or resource usage.

- **UI/UX Improvement Proposals**:  
  Suggest improvements to the game’s UI layout, editor usability, and control responsiveness based on current implementations.

- **Gameplay Balance Assessment**:  
  Evaluate balance of mechanics such as progression, loot, and combat, and suggest improvements or rebalancing tasks.

- **Dead Code & Folder Structure Cleanup**:  
  Detect unused signals, variables, files, and poorly organized folders, and find opportunities to clean or reorganize them.

- **Modding Tools & Editor Enhancements**:  
  Review the content editor and modding systems, proposing quality-of-life improvements, validations, or features.

- **Procedural Generation Improvements**:  
  Evaluate procedural systems and suggest ways to increase variety, coherence, or modularity.

- **AI Behavior Improvements**:  
  Review AI behaviors and identify ways to improve logic, pathfinding, or adaptability.

- **Lore & Design Implementation Review**:  
  Cross-check current implementation against design docs and lore, and suggest content additions or fixes.

- **Typo & Comment Discrepancy Detection**:  
  Propose fixes for typos in variable names, labels, comments, or documentation entries. Identify missing or unclear documentation in code and project files, and propose consistent naming conventions.

---

### Maintenance Task Guidelines

- The primary focus is to clean up and refactor existing code without introducing new functionality.
- Ensure that tasks are actionable, with clear steps and validation.
- Validate fixes through testing, manual checks, or automated procedures.
- Focus on improving code structure, clarity, and reliability.


---

### Process for Generating Maintenance Tasks  

1. **Pick a goal**  
   - Pick one of the 'Refactoring & Code Quality Improvement Goals' so we limit the scope of maintenance.

2. **Analyze the codebase**  
   - The AI scans the codebase to identify scripts, scenes, or folders that require maintenance based on the selected refactoring or quality improvement goal.

3. **Phase 1: Generate Parent Tasks**  
   - Based on the codebase analysis, create the file and generate the main, high-level tasks required to implement the feature. Use your judgment on how many high-level tasks to use. It's likely to be about 5. 
   - Present these tasks to the user in the specified format (without sub-tasks yet).  
   - Inform the user: "I have generated the high-level tasks based on the analysis. Ready to generate the sub-tasks? Respond with 'Go' to proceed."

4. **Wait for Confirmation**  
   - Pause and wait for the user to respond with "Go."

5. **Phase 2: Generate Sub-Tasks**  
   - Once the user confirms, break down each parent task into smaller, actionable sub-tasks necessary to complete the parent task. Ensure sub-tasks logically follow from the parent task and cover the implementation details implied by the maintenance goal.

6. **Identify Relevant Files**  
   - Based on the tasks and maintenance goal, identify potential files that will need to be created, modified or removed. List these under the Relevant Files section, including corresponding test files if applicable.

7. **Generate Final Output**  
   - Combine the parent tasks, sub-tasks, relevant files, and notes into the final Markdown structure.

8. **Save Task List**  
   - Save the generated document to `/project-management/current-prd/tasks-[prd-file-name].md`, where `[prd-file-name]` is based on the current goals of the maintenance tasks.

---

## Output  
**Format:** Markdown (`.md`)  
**Location:** `.project-management/current-prd/`  
**Filename:** `tasks-[prd-file-name].md` (e.g., tasks-prd-code-refactor.md)

# Output Format
The generated task list must follow this structure:

```
## Selected maintenance goal
- Specify the selected maintenance goal so we know if the tasks align with this goal

## Pre-Feature Development Project Tree  
- Use command line tools to get current project tree view, omitting any directory that starts with `.` or verbose nested directories like `addons`, etc...

## Relevant Files  
- Reference *existing* project files here  

### Proposed New Files  
- `path/to/potential/file1.gd` - Brief description of why this file is relevant (e.g., Contains the main component for this feature).  
- `/Tests/Unit/test_file1.gd` - Unit tests for `file1.gd`.  
- `path/to/another/file.gd` - Brief description (e.g., signal broker involvement).  
- `/Tests/Unit/test_file.gd` - Unit tests for `another/file.gd`.  

### Existing Files Modified  
- `scripts/utils/helpers.gd` - Brief description (e.g., Refactor the damage calculation functions).  
- `/Tests/Unit/test_helpers.gd` - Unit tests for `helpers.gd`. 

### Files To Remove  
- `path/to/file_to_remove.gd` - Brief description (e.g., File was no longer in use).  

### Notes  
- Unit tests should typically be placed in `/Tests/Unit/`.

## Tasks

- [ ] 1.0 Parent Task Title
  - [ ] 1.1 [Sub-task description 1.1]
  - [ ] 1.2 [Sub-task description 1.2]
- [ ] 2.0 Parent Task Title
  - [ ] 2.1 [Sub-task description 2.1]
- [ ] 3.0 Parent Task Title (may not require sub-tasks if purely structural or configuration)

```

*End of document*
