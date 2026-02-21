---
name: migrate-godot-project
description: Migrate an external Godot project into this sketches repo as a nested folder. Handles file copying, res:// path rewriting, UID management, class_name collision avoidance, input action remapping, project.godot merging, and verification. Usage - /migrate-godot-project <source_path>
user_invocable: true
---

# Migrate External Godot Project into Sketches

Migrate a standalone Godot project into this sketches repo (`c:\Users\hello\godot\sketches`) as a self-contained subfolder.

The user provides the source project path as an argument. If no argument is given, ask for it.

## Phase 1: Explore Source Project

1. Read source `project.godot` for: autoloads, global groups, input actions, rendering settings, enabled plugins, main scene
2. List all `.gd`, `.tscn`, `.tres`, `.uid` files (exclude `addons/`, `.godot/`)
3. Grep `.gd` files for `class_name` declarations
4. Grep `.gd` files for `preload()` and `load()` with hardcoded `res://` paths
5. Grep `.tscn` files for `ext_resource` lines to identify all referenced assets
6. Determine which assets in `assets/` (or similar) are actually referenced by scenes vs unused bloat
7. Identify editor-only addons (EditorPlugin) vs runtime addons

## Phase 2: Check for Conflicts with Sketches

1. Grep sketches `.gd` files for matching `class_name` declarations to detect collisions
2. Check sketches `project.godot` for conflicting global groups, autoloads, or input actions
3. Check if the source project uses `ui_left/right/up/down` (needs remapping to `camera_left/right/up/down`)

## Phase 3: Ask User Decisions

Present findings and ask about:
- **Assets**: Copy only referenced assets, or everything?
- **Class names**: If generic names found (e.g., `Player`, `Card`, `Game`), propose a prefix to avoid future collisions
- **Addons**: Skip editor-only addons? Include runtime addons?
- **Any other conflicts** found in Phase 2

## Phase 4: Copy Files

Target folder: `sketches/<source-folder-name>/`

### Copy (into target folder):
- All `.gd` files and their `.gd.uid` sidecar files
- All `.tscn` files (preserving subfolder structure)
- All `.tres` resource files
- Referenced asset folders only (or all, per user choice)
- Other non-Godot files the game needs (e.g., `.json` data files)

### Skip:
- `project.godot` (settings merge into sketches project.godot)
- `.godot/` folder (editor cache, will regenerate)
- `*.import` files (Godot regenerates these on import)
- `addons/` (unless runtime-required)

### Method:
Use PowerShell via a temp `.ps1` script to handle Windows paths reliably:
```powershell
$src = 'C:\path\to\source'
$dst = 'C:\Users\hello\godot\sketches\<folder-name>'
New-Item -ItemType Directory -Force -Path $dst | Out-Null
Copy-Item "$src\*.gd" $dst -Force
# ... etc
```
Delete the temp script after use.

After copying, delete any `.import` files that came along:
```powershell
Get-ChildItem -Recurse $dst -Filter '*.import' | Remove-Item -Force
```

## Phase 5: Rewrite res:// Paths

All `path="res://X"` in `.tscn` files must become `path="res://<folder-name>/X"`.

Use sed on all `.tscn` files in the target folder (and subfolders):
```bash
sed -i 's|path="res://|path="res://<folder-name>/|g' "$file"
```

Do the same for any `preload("res://...")` or `load("res://...")` in `.gd` files.

## Phase 6: Fix UIDs

### Script/scene UIDs (.gd.uid files):
These were copied alongside their scripts. The UIDs remain valid since they're globally unique random values.

### Texture/asset UIDs:
Texture files get new UIDs when reimported into the sketches project. The old UIDs in `.tscn` `ext_resource` lines become stale. **Strip stale texture UIDs** from `.tscn` files:

For each `ext_resource` line referencing a texture/image (type="Texture2D", type="FontFile", etc.), remove the `uid="uid://..."` portion so Godot falls back to the text `path=`. Example:
```
# Before
[ext_resource type="Texture2D" uid="uid://stale123" path="res://..." id="1"]
# After
[ext_resource type="Texture2D" path="res://..." id="1"]
```

Do NOT strip UIDs from Script or PackedScene ext_resources -- those UIDs are valid because we copied the .uid sidecar files.

## Phase 7: Remap Input Actions

If the source uses `ui_left/right/up/down`, change to `camera_left/right/up/down` in all `.gd` files. The sketches project maps WASD and arrow keys to `camera_*` actions.

## Phase 8: Rename class_names (if collisions or generic)

For each `class_name` that collides or is too generic, rename with a prefix:
1. Update `class_name X` declaration in the `.gd` file
2. Update `extends X` in all `.gd` files that inherit
3. Update all type references: `: X`, `as X`, `is X`, `X.static_method`
4. Be careful with string literals -- don't rename inside `"quotes"`
5. Verify with grep that no old references remain

## Phase 9: Merge project.godot Settings

Add to sketches `project.godot`:
- **Global groups**: Convert to scene only groups
- **Autoloads**: Only if the game needs runtime autoloads (not editor plugins), prefer converting them to global static singletons.

Do NOT change:
- Display/rendering settings (project-wide, affects all sketches)
- Editor plugin list
- Input actions (already standardized)

If the source has project-wide rendering settings (e.g., nearest-neighbor filtering), apply them per-scene on the root node instead.

## Phase 10: Rebuild Caches

Run headless import to rebuild script class cache and UID cache:
```bash
C:/Users/hello/godot/godot.exe --headless --import --path "c:/Users/hello/godot/sketches" --quit
```

Expect errors about terrain_3d and debug_draw_3d DLLs -- these are from other sketches and are harmless.

## Phase 11: Verify

1. Run the migrated scene:
   ```
   mcp godot run_project with scene: <folder-name>/main_scene.tscn
   ```
2. Check debug output for errors (warnings about unused params or integer division are fine)
3. Take a screenshot to confirm visuals load correctly
4. Stop the project

## Phase 12: Report

Summarize what was done:
- Files copied (count of scripts, scenes, assets)
- Paths updated
- Class renames applied
- project.godot changes
- Any remaining warnings and whether they matter