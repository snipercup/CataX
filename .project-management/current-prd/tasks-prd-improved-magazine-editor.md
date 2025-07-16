## Pre-Feature Development Project Tree
```
.
├── Assets
├── Defaults
├── Documentation
├── Images
├── Mods
├── Scenes
├── Scripts
├── Tests
```

## Relevant Files
### Proposed New Files
- `/Tests/Unit/test_item_ranged_editor.gd` - Unit tests for drag-and-drop magazine workflow.
### Existing Files Modified
- `Scenes/ContentManager/Custom_Editors/ItemEditor/ItemRangedEditor.tscn` - Replace magazine UI with drag-and-drop widget.
- `Scripts/ItemRangedEditor.gd` - Handles drop validation and serialization.
- `Scenes/ContentManager/Custom_Widgets/Editable_Item_List.tscn` - Reused drag-and-drop widget.
- `Scenes/ContentManager/Custom_Widgets/DropEntityTextEdit.tscn` - Reference for validation logic.
- `/Tests/Unit/test_drop_entity_text_edit.gd` - Example of drop behavior tests.

### Notes
- Mirror the itemgroup editor layout for consistency.
- Field should be collapsible if space is limited.

## Tasks
- [ ] 1.0 Replace magazine selection UI in `ItemRangedEditor.tscn` with `Editable_Item_List` to allow drag-and-drop magazines.
  - [ ] 1.1 Locate current magazine list node and remove it.
  - [ ] 1.2 Instance `Editable_Item_List` and position it in the editor UI.
  - [ ] 1.3 Expose the new widget as a script variable for later access.
- [ ] 2.0 Implement drop validation in `ItemRangedEditor.gd` to only accept items of type `magazine` using logic from `Editable_Item_List`.
  - [ ] 2.1 Connect the drop signal from the `Editable_Item_List` widget.
  - [ ] 2.2 Verify the dropped item type using `DropEntityTextEdit` logic.
  - [ ] 2.3 Display feedback when an invalid item is dropped.
- [ ] 3.0 Update save and load methods in `ItemRangedEditor.gd` to handle magazine ID list stored as comma-separated string.
  - [ ] 3.1 Serialize the selected magazine IDs into a comma-separated string.
  - [ ] 3.2 Parse the stored string on load and populate the widget list.
  - [ ] 3.3 Maintain compatibility with existing saved items.
- [ ] 4.0 Create unit tests verifying magazine drag/drop acceptance and serialization.
  - [ ] 4.1 Write tests rejecting non-magazine items using the new editor.
  - [ ] 4.2 Write tests for saving and loading magazines as a string.
  - [ ] 4.3 Test removing magazines from the list updates the stored data.
*End of document*
