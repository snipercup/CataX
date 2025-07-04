class_name CraftingRecipesManagerTest
extends GutTest

var player: Node
var original_has_sufficient_item_amount

func before_all():
	var custom_mods: Array[DMod] = [Gamedata.mods.by_id('Core'), Gamedata.mods.by_id('Test')]
	Runtimedata.reconstruct(custom_mods)
	await get_tree().process_frame

func before_each():
	player = Node.new()
	player.skills = {}
	player.stats = {}
	player.get_stat = func(stat_id: String) -> int:
		return player.stats.get(stat_id, 0)
	player.add_to_group('Players')
	add_child(player)

func after_each():
	if player:
		player.queue_free()
	player = null
	if original_has_sufficient_item_amount != null:
		ItemManager.has_sufficient_item_amount = original_has_sufficient_item_amount

func after_all():
	Runtimedata.reset()

func test_has_required_skill_sufficient_level():
	player.skills = {'carpentry': {'level': 3}}
	var recipe := RItem.CraftRecipe.new({'skill_requirement': {'id': 'carpentry', 'level': 2}})
	assert_true(CraftingRecipesManager.has_required_skill(recipe), 'Player should meet skill requirement')

func test_has_required_skill_insufficient_level():
	player.skills = {'carpentry': {'level': 1}}
	var recipe := RItem.CraftRecipe.new({'skill_requirement': {'id': 'carpentry', 'level': 2}})
	assert_false(CraftingRecipesManager.has_required_skill(recipe), 'Player should not meet skill requirement')

func test_can_craft_recipe_missing_items():
	player.skills = {'carpentry': {'level': 5}}
	var recipe := RItem.CraftRecipe.new({
		'skill_requirement': {'id': 'carpentry', 'level': 2},
		'required_resources': [{'id': 'wood', 'amount': 2}]
	})
	original_has_sufficient_item_amount = ItemManager.has_sufficient_item_amount
	ItemManager.has_sufficient_item_amount = func(_id: String, _amount: int) -> bool:
		return false
	assert_false(CraftingRecipesManager.can_craft_recipe(recipe), 'Crafting should fail when items are missing')
