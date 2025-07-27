extends GutTest


func test_pick_compatible_candidate_returns_null_on_empty():
	var gen = OvermapAreaGenerator.new()
	var result = gen._pick_compatible_candidate(null, "north", Vector2.ZERO, [])
	assert_eq(result, null)
