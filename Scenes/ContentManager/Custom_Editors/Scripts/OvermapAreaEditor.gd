extends Control

# This scene is intended to be used inside the content editor
# It is supposed to edit exactly one DOvermapArea
# It expects to save the data to a JSON file
# Example overmaparea data:
# {
#     "id": "city_00",  // id for the overmap area
#     "name": "Example City",  // Name for the overmap area
#     "description": "A densely populated urban area surrounded by suburban regions and open fields.",  // Description of the overmap area
#     "min_width": 5,  // Minimum width of the overmap area
#     "min_height": 5,  // Minimum height of the overmap area
#     "max_width": 15,  // Maximum width of the overmap area
#     "max_height": 15,  // Maximum height of the overmap area
#     "regions": {
#       "urban": {
#         "spawn_probability": {
#           "range": {
#             "start_range": 0,  // Will start spawning at 0% distance from the center
#             "end_range": 30     // Will stop spawning at 30% distance from the center
#           }
#         },
#         "maps": [
#           {
#             "id": "house_01",
#             "weight": 10  // Higher weight means this map has a higher chance to spawn in this region
#           },
#           {
#             "id": "shop_01",
#             "weight": 5
#           },
#           {
#             "id": "park_01",
#             "weight": 2
#           }
#         ]
#       },
#       "suburban": {
#         "spawn_probability": {
#           "range": {
#             "start_range": 20,  // Will start spawning at 20% distance from the center
#             "end_range": 80     // Will stop spawning at 80% distance from the center
#           }
#         },
#         "maps": [
#           {
#             "id": "house_02",
#             "weight": 8
#           },
#           {
#             "id": "garden_01",
#             "weight": 4
#           },
#           {
#             "id": "school_01",
#             "weight": 3
#           }
#         ]
#       },
#       "field": {
#         "spawn_probability": {
#           "range": {
#             "start_range": 70,  // Will start spawning at 70% distance from the center
#             "end_range": 100     // Will stop spawning at 100% distance from the center
#           }
#         },
#         "maps": [
#           {
#             "id": "field_01",
#             "weight": 12
#           },
#           {
#             "id": "barn_01",
#             "weight": 6
#           },
#           {
#             "id": "tree_01",
#             "weight": 8
#           }
#         ]
#       }
#     }
# }


@export var IDTextLabel: Label = null # Displays the ID
@export var NameTextEdit: TextEdit = null # Allows editing of the name of this area
@export var DescriptionTextEdit: TextEdit = null # Describes this area
@export var min_width_spin_box: SpinBox = null # The minimum width of the area in tiles
@export var min_height_spin_box: SpinBox = null # The minimum height of the area in tiles
@export var max_width_spin_box: SpinBox = null # The maximum width of the area in tiles
@export var max_height_spin_box: SpinBox = null # The maximum height of the area in tiles
@export var region_name_text_edit: TextEdit = null # Allows the user to enter a new region name
@export var region_v_box_container: VBoxContainer = null # Contains region editing controls
@export var overmap_area_region_editor: PackedScene = null


# This signal will be emitted when the user presses the save button
# This signal should alert Gamedata that the overmaparea data array should be saved to disk
signal data_changed()

var olddata: DOvermaparea # Remember what the value of the data was before editing

# The data that represents this overmaparea
# The data is selected from the Gamedata.overmapareas
# based on the ID that the user has selected in the content editor
var dovermaparea: DOvermaparea = null:
	set(value):
		dovermaparea = value
		load_overmaparea_data()
		olddata = DOvermaparea.new(dovermaparea.get_data().duplicate(true))


# This function updates the form based on the DOvermaparea that has been loaded
func load_overmaparea_data() -> void:
	if IDTextLabel != null:
		IDTextLabel.text = str(dovermaparea.id)
	if NameTextEdit != null:
		NameTextEdit.text = dovermaparea.name
	if DescriptionTextEdit != null:
		DescriptionTextEdit.text = dovermaparea.description

	# Update the minimum and maximum width and height spin boxes
	if min_width_spin_box != null:
		min_width_spin_box.value = dovermaparea.min_width
	if min_height_spin_box != null:
		min_height_spin_box.value = dovermaparea.min_height
	if max_width_spin_box != null:
		max_width_spin_box.value = dovermaparea.max_width
	if max_height_spin_box != null:
		max_height_spin_box.value = dovermaparea.max_height

	# Load region data into the region_v_box_container
	if dovermaparea.regions:
		for region_key in dovermaparea.regions.keys():
			var region_instance: DOvermaparea.Region = dovermaparea.regions[region_key]  # Expecting Region instance

			# Instantiate the region editor and set its data
			var region_editor = overmap_area_region_editor.instantiate()
			region_v_box_container.add_child(region_editor)

			# Set the region name and values for the region editor
			region_editor.set_region_name(region_key)
			region_editor.set_values(region_instance.get_data())  # Using get_data() to get the region's dictionary representation


# The editor is closed, destroy the instance
# TODO: Check for unsaved changes
func _on_close_button_button_up() -> void:
	queue_free()

# This function takes all data from the form elements and stores them in the DOvermaparea instance
# Since dovermaparea is a reference to an item in Gamedata.overmapareas
# the central array for overmaparea data is updated with the changes as well
# The function will signal to Gamedata that the data has changed and needs to be saved
func _on_save_button_button_up() -> void:
	# Update the name and description fields
	dovermaparea.name = NameTextEdit.text
	dovermaparea.description = DescriptionTextEdit.text

	# Update the minimum and maximum width and height fields from the spin boxes
	if min_width_spin_box != null:
		dovermaparea.min_width = int(min_width_spin_box.value)
	if min_height_spin_box != null:
		dovermaparea.min_height = int(min_height_spin_box.value)
	if max_width_spin_box != null:
		dovermaparea.max_width = int(max_width_spin_box.value)
	if max_height_spin_box != null:
		dovermaparea.max_height = int(max_height_spin_box.value)

	# Construct the regions object from the UI data
	var regions_data: Dictionary = {}
	for region_editor in region_v_box_container.get_children():
		var region_key = region_editor.get_region_name()
		var region_values = region_editor.get_values()

		# Create a new Region instance using the extracted data
		var new_region = DOvermaparea.Region.new()
		new_region.spawn_probability = region_values.get("spawn_probability", {})
		new_region.maps = region_values.get("maps", [])
		regions_data[region_key] = new_region  # Store the Region instance instead of a dictionary

	# Update the regions property in the DOvermaparea instance with Region instances
	dovermaparea.regions = regions_data

	# Save the updated data to disk and emit the data_changed signal
	dovermaparea.save_to_disk()
	data_changed.emit()

	# Store the current data as the old data for future comparisons
	olddata = DOvermaparea.new(dovermaparea.get_data().duplicate(true))