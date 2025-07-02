extends GutTest

const LevelGenerator = preload("res://LevelGenerator.gd")

class StubChunk:
	extends Node3D
	enum LoadStates { NEITHER, LOADING, UNLOADING }
	var load_state: LoadStates = LoadStates.NEITHER
	var mypos: Vector3

	func unload_chunk():
	    load_state = LoadStates.UNLOADING
	    queue_free()

var generator: LevelGenerator

func before_each():
	generator = LevelGenerator.new()
	add_child(generator)
	generator.level_width = 32
	generator.level_height = 32

func after_each():
	if generator:
	    generator.queue_free()

func test_handle_chunk_unload_uses_loop():
	var count = 25
	for i in range(count):
	    var chunk = StubChunk.new()
	    chunk.mypos = Vector3(i * generator.level_width, 0, 0)
	    generator.loaded_chunks[Vector2(i, 0)] = chunk
	    add_child(chunk)
	    chunk.add_to_group("chunks")

	var done := false
	generator.all_chunks_unloaded.connect(func(): done = true)
	await generator.handle_chunk_unload()
	assert_true(done, "all_chunks_unloaded should emit")
	assert_eq(generator.loaded_chunks.size(), 0, "Loaded chunks should be empty")
