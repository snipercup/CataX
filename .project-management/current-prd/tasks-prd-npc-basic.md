## Pre-Feature Development Project Tree
```bash
./
./Assets
./Defaults
./Documentation
./Images
./Media
./Mods
./Mods/Backrooms
./Mods/Core
./Mods/Dimensionfall
./Mods/Test
./Scenes
./Scripts
./Scripts/Components
./Scripts/Gamedata
./Scripts/Helper
./Scripts/Mob
./Scripts/Runtimedata
./Shaders
./Sounds
./Tests
./Tests/Unit
./Textures
```

## Relevant Files
- Reference existing scripts and mod directories for NPC integration
### Proposed New Files
- `Scripts/Gamedata/DNpc.gd` - Data class representing a single NPC
- `Scripts/Gamedata/DNpcs.gd` - Handles loading NPC JSON files for a mod
- `Scripts/Runtimedata/RNpc.gd` - Runtime representation of an NPC
- `Scripts/Runtimedata/RNpcs.gd` - Container for runtime NPC instances
- `Mods/Dimensionfall/Npcs/hank.json` - Example NPC definition for Hank
- `Mods/Dimensionfall/Npcs/hank.png` - Placeholder sprite referenced by Hank
- `Tests/Unit/test_npc_loading.gd` - Unit test verifying Hank loads correctly
### Existing Files Modified
- `Scripts/Gamedata/DMod.gd` - Add NPC support to mod content types
- `Scripts/runtimedata.gd` - Include NPCs when reconstructing runtime data

### Notes
- JSON schema mirrors mob data style but limited to: id, name, description, sprite, health
- New folders under each mod should follow `Mods/<ModName>/Npcs/`

## Tasks
- [ ] **1.0** Define the NPC JSON schema and establish the `/Mods/<ModName>/Npcs/` directory structure. *(Ref: `.project-management/current-prd/prd-npc-basic.md`)*
  - [ ] **1.1** Create `Npcs` folder for each mod, starting with `Mods/Dimensionfall/Npcs/`
  - [ ] **1.2** Document JSON fields (`id`, `name`, `description`, `sprite`, `health`) within the PRD notes or code comments
  - [ ] **1.3** Prepare placeholder sprite location for NPCs
- [ ] **2.0** Implement `Dnpc` and `Rnpc` classes for parsing and representing NPC data.
  - [ ] **2.1** Create `Scripts/Gamedata/DNpc.gd` defining NPC properties and `get_data()`
  - [ ] **2.2** Create `Scripts/Gamedata/DNpcs.gd` to load all NPC JSON files from a mod directory
  - [ ] **2.3** Create `Scripts/Runtimedata/RNpc.gd` mirroring runtime NPC properties
  - [ ] **2.4** Create `Scripts/Runtimedata/RNpcs.gd` to instantiate runtime NPCs from `DNpcs`
- [ ] **3.0** Update the mod loading system so `Gamedata` and `Runtimedata` load NPC JSON files on startup.
  - [ ] **3.1** Add `NPCS` enum entry and `npcs` variable in `Scripts/Gamedata/DMod.gd`
  - [ ] **3.2** Instantiate `DNpcs` in `DMod._init()` and include it in `content_instances`
  - [ ] **3.3** Extend `Scripts/runtimedata.gd` to construct `RNpcs` and map it in `gamedata_map`
- [ ] **4.0** Add an example NPC called **Hank** in `Mods/Dimensionfall/Npcs/`.
  - [ ] **4.1** Copy or create a sprite `hank.png` under the new folder
  - [ ] **4.2** Write `hank.json` containing Hank's id, name, description, sprite reference, health 100
- [ ] **5.0** Create a unit test ensuring Hank’s data loads correctly via the new classes.
  - [ ] **5.1** Build `Tests/Unit/test_npc_loading.gd` using `Runtimedata.reconstruct` with Dimensionfall
  - [ ] **5.2** Assert the NPC exists in `Gamedata` and properties match expectations
  - [ ] **5.3** Reset runtime data after the test
*End of document*
