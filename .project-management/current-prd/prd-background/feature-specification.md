This is a recurring error from the `godot --headless --import` import command:
```
root@46cd07386be9:/workspace/CataX# godot --headless --import > /tmp/godot_impor
t.log && tail -n 20 /tmp/godot_import.log
ERROR: Unable to open file: res://.godot/imported/pointer3.png-daf3916ed3afea06b
8c4267b5a72e06f.ctex.
   at: _load_data (scene/resources/compressed_texture.cpp:41)
ERROR: Failed loading resource: res://.godot/imported/pointer3.png-daf3916ed3afe
a06b8c4267b5a72e06f.ctex. Make sure resources have been imported by opening the
project in the editor at least once.
   at: _load (core/io/resource_loader.cpp:343)
ERROR: Failed loading resource: res://Textures/pointer3.png. Make sure resources
 have been imported by opening the project in the editor at least once.
   at: _load (core/io/resource_loader.cpp:343)
```

This feature will tackle the following objectives:
1. Identify what pointer3.png is
2. identify what the role of pointer3.png is in the Dimensionfall game
3. Find out what files are referencinv the pointer3.png file
4. Analize what the errors mean and what the impact is for the Dimensionfall game
5. Come up with mitigating actions so that the errors no longer show up when using the import command.
