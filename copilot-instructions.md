# Copilot Instructions (Init)

This repository is a Godot project focused on a medieval plague-themed game. The project is structured for Godot 4 (with Terrain3D and addon-based tooling) and includes a demo scene used for testing gameplay systems.

## Key Paths
- **Project root:** `project.godot`
- **Demo scene:** `demo/Demo.tscn` (main testbed)
- **Player logic:** `Scripts/player.gd`
- **Existing enemy movement:** `demo/src/Enemy.gd` + `demo/components/Enemy.tscn`
- **Terrain / navigation:** `demo/src/RuntimeNavigationBaker.gd` and addon `addons/terrain_3d`

## Primary Goals (Typical Requests)
1. Add gameplay systems (AI, combat, health, enemies, etc.)
2. Implement in-scene logic for demo/test scenes (e.g., spawn bandit enemy and validate behavior)
3. Keep changes minimal and focused in relevant folders (`demo/src`, `demo/components`, `Scripts`)

## Preferred Behavior for Copilot
- Always check for existing patterns or scripts before creating new ones.
- Use existing `demo/src/Enemy.gd` as the basis for new enemy AI types.
- When adding new scripts or scenes, place them alongside related demo content (e.g., `demo/src/` and `demo/components/`).
- Keep runtime dependencies simple: avoid adding new third-party addons unless explicitly requested.

## Useful Notes
- The project uses Godot 4 conventions (e.g., `CharacterBody3D`, `NavigationAgent3D`, `Terrain3D`).
- This repo includes addons like `terrain_3d` and `proton_scatter`; avoid modifying them unless required.
- For gameplay code, prefer `.gd` scripts in `demo/src/` rather than global singleton scripts unless asked.

---

This file is intended to help the assistant understand the project structure and goals immediately when asked for changes.