# Commando Assassin — AI Coordination

> Source of truth for agent ownership, dependency contracts, integration, and planned work.
> Repository: https://github.com/gauravprajapat-23/commando-assesian
> Integration branch: `dev` | Release branch: `main` (do not merge to main)

## Game vision

Godot 4 third-person tactical action-adventure. A commando travels to distinct islands, infiltrates hostile bases, completes varied missions, and extracts. Build a **small but complete vertical slice first**: Island 01, landing → infiltration → outpost objective → extraction, then expand to additional islands, mission types, stealth, weapons and Android controls.

## Branches and owners

| Agent | Branch | GitHub issue | Exclusive files | First delivery |
|---|---|---|---|---|
| Island World | `dev/world` | [WORLD-001 #1](https://github.com/gauravprajapat-23/commando-assesian/issues/1) | `scenes/world/**`, `scripts/world/**`, `assets/world/**`, `tests/world/**` | Island 01, markers, collision |
| Player & Combat | `dev/player-combat` | [PLAYER-001 #2](https://github.com/gauravprajapat-23/commando-assesian/issues/2) | `scenes/player/**`, `scripts/player/**`, `assets/player/**`, `tests/player/**` | Third-person movement, shooting |
| Enemies & AI | `dev/enemy-ai` | [AI-001 #3](https://github.com/gauravprajapat-23/commando-assesian/issues/3) | `scenes/enemies/**`, `scripts/enemies/**`, `assets/enemies/**`, `tests/enemies/**` | Guard patrol, detection, combat |
| Missions & UI | `dev/missions-ui` | [MISSION-001 #4](https://github.com/gauravprajapat-23/commando-assesian/issues/4) | `scenes/missions/**`, `scripts/missions/**`, `scenes/ui/**`, `scripts/ui/**`, `tests/missions/**`, `tests/ui/**` | Mission state machine and HUD |
| Master Integrator | `dev` | integration follow-up | `scenes/main.tscn`, `scripts/core/main.gd`, `project.godot`, `docs/AI_COORDINATION.md` | Wire verified PRs, smoke test, update issues |

All workers start from `dev` and create **pull requests with base `dev`**. Do not merge or push changes to `main`. Do not modify any shared/integration-only files or another agent's paths. On a contract change, comment on the owning Issue before editing.

## Cross-worker interfaces (v1)

- World scene: `res://scenes/world/island_01.tscn`, root `Node3D`; named `PlayerSpawn`, `EnemySpawns`, `ObjectivePoint`, `ExtractionPoint` markers.
- Player scene: `res://scenes/player/commando.tscn`, root `CharacterBody3D`; `take_damage(amount: float)`; `get_team() -> String` (`player`); signals `health_changed(current: float, maximum: float)`, `ammo_changed(current: int, reserve: int)`, `died`.
- Guard scene: `res://scenes/enemies/guard.tscn`, root `CharacterBody3D`; `take_damage(amount: float)`; `get_team() -> String` (`enemy`); signals `alerted(target: Node3D)`, `died`. Avoid hardcoded global main-scene lookups.
- Mission controller: `res://scripts/missions/mission_controller.gd`; states `NOT_STARTED`, `INFILTRATE`, `OBJECTIVE_COMPLETE`, `EXTRACTED`, `FAILED`; `mission_state_changed` signal; methods `start_mission()`, `complete_objective()`, `extract()`, `fail_mission()`.
- UI consumes state via signals/injected nodes. Inputs must be abstractable for later touch controls.
- Keep geometry/assets original or appropriately licensed. Prefer Godot built-ins, simple meshes, and GL Compatibility renderer for early Android viability.

## Milestone 1 — Island 01 vertical slice

1. Parallel workers implement Issues #1–#4 in exclusive directories.
2. Each worker runs Godot 4 headless parse/import and focused regression tests and reports exact commands/output. **Do not claim tests passed if they were not executed.**
3. Each worker opens a PR to `dev`, including tests, changed files and integration notes. No worker merges.
4. Master verifies files, branch target, checks and contracts; requests changes where needed.
5. Master merges verified PRs into `dev` **one at a time**, rechecking each against updated `dev`; integrates only through shared files.
6. Master runs integrated playability test: spawn player → traverse island → encounter guard → complete outpost objective → extraction; update Issues and this MD with verified state.
7. No release merge to `main` without explicit user request.

### Dependency rules

- WORLD-001, PLAYER-001 and AI-001 can implement in parallel.
- MISSION-001 state machine / UI can implement in parallel, but its integration is blocked until WORLD-001 and PLAYER-001 contracts land.
- World navigation and enemy AI integration must be tested together after both merge.
- Do not edit `main.gd` from worker chats to “quick-fix” an integration failure.

## Next milestone backlog (unassigned)

- INTEGRATION-001: Island 01 complete playable loop with Godot acceptance.
- WORLD-002: Island 02 biome and travel/map selection.
- GAME-002: Mission variations (rescue, sabotage, intel, extraction).
- PLAYER-002: Weapons, stealth and equipment.
- AI-002: Alerted squads and improved navigation/cover.
- UI-002: Android touch controls, safe-area adaptation and performance checks.
- SAVE-001: Mission progress, unlocks, and checkpoint saving.

## Operating instructions for ChatGPT Manager

At each cycle: read this MD and active GitHub Issues/PRs; schedule only dependency-ready tasks; send one scoped assignment per worker chat; capture test/PR evidence; review diffs; merge approved PRs into `dev` only; update issue status and coordination file; choose next unfinished tasks. A worker's natural-language completion report alone is not verification. Stop on conflicts or uncertain execution rather than guessing.

## Current status (2026-11-19)

- Godot project bootstrap created on `dev`.
- Initial worker issues #1–#4 created; implementation not started.
- No PR merged; no Godot test run claimed.
