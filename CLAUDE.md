# General
- **NEVER use Bash to read, search, or edit files. Use dedicated tools instead:** `find`/`ls` → Glob, `grep`/`rg` → Grep, `cat`/`head`/`tail` → Read, `sed`/`awk` → Edit, `echo >`/heredoc → Write. These handle Windows paths natively. Bash is still needed for file management (`cp`, `mv`, `rm`, `mkdir`).
- Take advantage of static typing and compiler features as much as possible.
- Do NOT add defensive null and valid checks unless the variable is used in a way that requires it.
- Do not add comments, but don't delete existing comments.
- Be short and concise in your language.
- Only expand and explain things if asked.
- Avoid the word "Data". Use more descriptive terminology.
- Shorten summaries to just the most important code bits.
- when you are uncertain, clearly explain things you're not sure of. Double check your knowledge by accessing documentation or doing a web search.
- Do not invent abbreviations or acronyms for user facing text. Reuse terminology already established in the codebase and presented to the player. Optimize for understandability over brevity.

# Godot
## Overall guidance
- ALWAYS use two spaces for indentation, never tabs
- Add static types to GDScript variables, declarations, return values, etc. Greatly prefer using := to give a variable a type, except in situations where we need to be more generic, or must explicitly assign a type.
- Do not ever delete the .godot folder unless I explicitly ask.
- Avoid hardcoding magic numbers and values, and expose them as human editable in the editor.
- Avoid hardcoding UIs in code, preferring to create nodes for them in the .tscn.
- Don't add empty whitespace spacer elements, preferring to use idiomatic and clean UI architecture practices in godot. take full advantage of the features of godot UI - all the layout properties, the theme, visibility, etc.
* When possible use data assets and resources that are hooked up through .tscn references, so it's human editable and inspectable.
* Prioritize allowing the game developer to easily iterate and control numbers and content by being data driven
- Prefer using `unique_name_in_owner = true` to access nodes through %Name in gdscript
- AVOID using `add_node` MCP tool. Instead, write/edit .tscn files directly.
- ALWAYS use `update_project_uids` after renaming or moving assets to fix UID references.
- Prefer `@export var` over `const` for tunable values. Use `@export_group()` to organize related exports.
- Use components and other elements in `_common/`.
- Use methods from `_common/utils.gd` (autoload `Utils`).

## Fonts
- **Hard minimum: 20px. Nothing below 20.**
- Typographic hierarchy: headings/titles 28+, subheadings/section headers/names 24, body/description/caption/all other text 20.
- For programmatically created labels, set `.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` to handle overflow via word wrapping instead of shrinking text.
- Avoid adding colors unnecessarily to UI elements and text. Especially avoid super basic and overly loud colors like pure red or pure green.

## Input Actions
- WASD is mapped to `camera_left`, `camera_right`, `camera_up`, `camera_down` (NOT `ui_left/right/up/down`)
- Use `camera_*` actions for player movement


## Documentation
- **Docs & API reference:** `C:\Users\hello\godot\godot-docs-html-master`
- **Demo projects:** `C:\Users\hello\godot\godot-demo-projects-master`
- Strongly prefer searching the docs and using idiomatic and well-supported ways of performing tasks.
- When solving a problem, first check the documentation to see what solutions already exist.
- Do things in a godot-esque manner.
- When working on Godot tasks, search this directory for relevant examples before implementing
- Use Grep/Glob to find usage patterns, node examples, and best practices

### UX for new players
- Show descriptions when items are selected, not just names
- Provide contextual prompts telling the player what to do next
- Highlight valid placement locations when placing items
- Show why placement is invalid when hovering invalid cells
- Add hover tooltips explaining what things are and their current state

### Checklist for file moves in Godot:

1. Move files to new location
2. Update ext_resource path= in .tscn files
3. Update preload("res://...") in .gd files
4. Update [autoload] paths in project.godot
5. Check for load() calls with hardcoded paths

### Git worktrees for isolated work

When creating a worktree, copy .godot/ so headless Godot can validate scripts:
```bash
git worktree add ../sketches-<name> <branch-name> -b <branch-name>
cp -r .godot ../sketches-<name>/
```

After adding the worktree, run `/add-dir ../sketches-<name>/` to allow edits without repeated permission prompts.

## Testing with gdUnit4
- **When to write tests:** Write tests for logic-heavy code (state machines, calculations, game rules, utilities). Skip tests for UI-only or scene-setup code.
- **Test location:** Place tests in `<sketch>/tests/` folder (e.g., `jan_28_2026-psychebuilder-ai/tests/test_game_state.gd`). gdUnit4 looks for folders named `tests/` by project setting.
- **Run tests for a sketch:**
  ```bash
  C:/Users/hello/godot/godot.exe --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -rc 1 --add res://<sketch>/tests
  ```
- **Run all tests:**
  ```bash
  C:/Users/hello/godot/godot.exe --headless -s addons/gdUnit4/bin/GdUnitCmdTool.gd --ignoreHeadlessMode -rc 1 --add res://
  ```
- **Exit codes:** 0 = all pass, non-zero = failures
- **After implementing features:** Write tests, run them, fix failures before committing
- **Test file template:**
  ```gdscript
  extends GdUnitTestSuite

  func test_example() -> void:
    assert_int(2 + 2).is_equal(4)
    assert_str("hello").contains("ell")
    assert_bool(true).is_true()
  ```

### How to get audio assets
Option 1 - Use rfxgen to generate short sfx audio assets. It's located in _tools\rfxgen_v5.0_win_x64\rfxgen.exe. Use this for short sfx that provide clear feedback for the player.
Option 2 - use the cc0-music skill to download background music.
Option 3 - use audiocraft-cli skill to generate looping background music.