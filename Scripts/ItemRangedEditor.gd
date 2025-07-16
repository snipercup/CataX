extends Control

# This scene is intended to be used inside the item editor
# It is supposed to edit exactly one ranged weapon

# Ranged form elements
@export var UsedAmmoTextEdit: TextEdit = null
@export var MagazinesEditable_Item_List: Control = null  # Drag-and-drop magazine list widget
@export var RangeNumberBox: SpinBox = null
@export var SpreadNumberBox: SpinBox = null
@export var SwayNumberBox: SpinBox = null
@export var RecoilNumberBox: SpinBox = null
@export var UsedSkillTextEdit: HBoxContainer = null
@export var skill_xp_spin_box: SpinBox = null
@export var ReloadSpeedNumberBox: SpinBox = null
@export var FiringSpeedNumberBox: SpinBox = null
@export var accuracy_stat_text_edit: HBoxContainer = null

var ditem: DItem = null:
	set(value):
		if not value:
			return
		ditem = value
		load_properties()


func _ready():
		set_drop_functions()




# Returns the properties of the ranged tab in the item editor
func save_properties() -> void:
	var selected_magazines: Array = MagazinesEditable_Item_List.get_items()
	
	ditem.ranged.used_ammo = UsedAmmoTextEdit.text
	ditem.ranged.used_magazine = ",".join(selected_magazines)  # Join the selected magazines by commas
	ditem.ranged.firing_range = int(RangeNumberBox.value)
	ditem.ranged.spread = int(SpreadNumberBox.value)
	ditem.ranged.sway = int(SwayNumberBox.value)
	ditem.ranged.recoil = int(RecoilNumberBox.value)
	ditem.ranged.reload_speed = ReloadSpeedNumberBox.value
	ditem.ranged.firing_speed = FiringSpeedNumberBox.value
	ditem.ranged.accuracy_stat = accuracy_stat_text_edit.get_text()
	
	# Only include used_skill if UsedSkillTextEdit has a value
	if UsedSkillTextEdit.get_text() != "":
		ditem.ranged.used_skill = {
			"skill_id": UsedSkillTextEdit.get_text(),
			"xp": skill_xp_spin_box.value
		}
	else:
		ditem.ranged.used_skill.clear()


func load_properties() -> void:
	if not ditem.ranged:
		print_debug("ditem.ranged is null, skipping property loading.")
		return
	if ditem.ranged.used_ammo != "":
		UsedAmmoTextEdit.text = ditem.ranged.used_ammo
		if ditem.ranged.used_magazine != "":
				var used_magazines = ditem.ranged.used_magazine.split(",")
				MagazinesEditable_Item_List.set_items(used_magazines)
		else:
				MagazinesEditable_Item_List.clear_list()
	RangeNumberBox.value = ditem.ranged.firing_range
	SpreadNumberBox.value = ditem.ranged.spread
	SwayNumberBox.value = ditem.ranged.sway
	RecoilNumberBox.value = ditem.ranged.recoil
	ReloadSpeedNumberBox.value = ditem.ranged.reload_speed
	FiringSpeedNumberBox.value = ditem.ranged.firing_speed
	accuracy_stat_text_edit.set_text(ditem.ranged.accuracy_stat)
	
	if ditem.ranged.used_skill.has("skill_id"):
		UsedSkillTextEdit.set_text(ditem.ranged.used_skill["skill_id"])
	if ditem.ranged.used_skill.has("xp"):
		skill_xp_spin_box.value = ditem.ranged.used_skill["xp"]


# Called when the user has successfully dropped data onto the skillTextEdit
# We have to check the dropped_data for the id property
func skill_drop(dropped_data: Dictionary, texteditcontrol: HBoxContainer) -> void:
	# dropped_data is a Dictionary that includes an 'id'
	if dropped_data and "id" in dropped_data:
		var skill_id = dropped_data["id"]
		if not Gamedata.mods.by_id(dropped_data["mod_id"]).skills.has_id(skill_id):
			print_debug("No item data found for ID: " + skill_id)
			return
		texteditcontrol.set_text(skill_id)
	else:
		print_debug("Dropped data does not contain an 'id' key.")


func can_skill_drop(dropped_data: Dictionary):
	# Check if the data dictionary has the 'id' property
	if not dropped_data or not dropped_data.has("id"):
		return false
	
	# Fetch skill data by ID from the Gamedata to ensure it exists and is valid
	if not Gamedata.mods.by_id(dropped_data["mod_id"]).skills.has_id(dropped_data["id"]):
		return false

	# If all checks pass, return true
	return true

func stat_drop(dropped_data: Dictionary, texteditcontrol: HBoxContainer) -> void:
	if dropped_data and dropped_data.has("id"):
		var stat_id = dropped_data["id"]
		if not Gamedata.mods.by_id(dropped_data["mod_id"]).stats.has_id(stat_id):
			print_debug("No stat data found for ID: " + stat_id)
			return
		texteditcontrol.set_text(stat_id)
	else:
		print_debug("Dropped data does not contain an 'id' key.")

func can_stat_drop(dropped_data: Dictionary):
	if not dropped_data or not dropped_data.has("id"):
		return false
	return Gamedata.mods.by_id(dropped_data["mod_id"]).stats.has_id(dropped_data["id"])


# Set the drop functions on the required skill and skill progression controls
# This enables them to receive drop data
func set_drop_functions():
	UsedSkillTextEdit.drop_function = skill_drop.bind(UsedSkillTextEdit)
	UsedSkillTextEdit.can_drop_function = can_skill_drop
	accuracy_stat_text_edit.drop_function = stat_drop.bind(accuracy_stat_text_edit)
	accuracy_stat_text_edit.can_drop_function = can_stat_drop
