# Commando Assassin — AI Coordination

> Source of truth for agent ownership, dependency contracts, integration, and planned work.
> Repository: https://github.com/gauravprajapat-23/commando-assesian
> Integration branch: `dev` | Release branch: `main` (do not merge to main)

## Game vision

Godot 4 third-person tactical action-adventure. A commando travels to distinct islands, infiltrates hostile bases, completes varied missions, and extracts. Build a **small but complete vertical slice first**: Island 01, landing → infiltration → outpost objective → extraction, then expand to additional islands, mission types, stealth, weapons and Android controls.

## Branches and owners

| Agent | Branch | GitHub issue | Exclusive files | First delivery |
|---|---|---|---|---|
| Island World | `world` | [WORLD-001 #1](https://github.com/gauravprajapat-23/commando-assesian/issues/1) | `scenes/world/**`, `scripts/world/**`, `assets/world/**`, `tests/world/**` | Island 01, markers, collision |
| Player & Combat | `player-combat` | [PLAYER-001 #2](https://github.com/gauravprajapat-23/commando-assesian/issues/2) | `scenes/player/**`, `scripts/player/**`, `assets/player/**`, `tests/player/**` | Third-person movement, shooting |
| Enemies & AI | `enemy-ai` | [AI-001 #3](https://github.com/gauravprajapat-23/commando-assesian/issues/3) | `scenes/enemies/**`, `scripts/enemies/**`, `assets/enemies/**`, `tests/enemies/**` | Guard patrol, detection, combat |
| Missions & UI | `missions-ui` | [MISSION-001 #4](https://github.com/gauravprajapat-23/commando-assesian/issues/4) | `scenes/missions/**`, `scripts/missions/**`, `scenes/ui/**`, `scripts/ui/**`, `tests/missions/**`, `tests/ui/**` | Mission state machine and HUD |
| Master Integrator | `dev` | integration follow-up | `scenes/main.tscn`, `scripts/core/main.gd`, `project.godot`, `docs/AI_COORDINATION.md` | Wire verified PRs, smoke test, update issues |

Worker branch names are top-level because Git cannot have both a `dev` ref and refs under `dev/`. All workers start from `dev` and create **pull requests with base `dev`**. Do not merge or push changes to `main`. Do not modify any shared/integration-only files or another agent's paths. On a contract change, comment on the owning Issue before editing.

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

## Current status (2026-11-19) — Cycle 01 dispatched

- Master inspected Issues #1–#4, `dev`, four worker branches and pull-request inventory.
- Issues #1–#4 assigned to dedicated worker chats; each issue records branch, exclusive paths, expected tests, PR target `dev`, and explicit no-merge restrictions.
- At audit, all four worker branches were 1 commit behind `dev`, 0 commits ahead, with no unique changes. Manager will fast-forward them to this coordination commit before development.
- No worker implementation PRs existed at dispatch. No code tests have been executed or claimed by Master.
- Master reserved `scenes/main.tscn`, `scripts/core/main.gd`, `project.godot` and this coordination file for integration only.
- Status: `ASSIGNED / AWAITING WORKER IMPLEMENTATION`. Island 01 integrated acceptance remains `NOT RUN`; no merges approved.

### Cycle 01 dispatch and gates

| Issue | Branch | Status | Integration gate |
|---|---|---|---|
| #1 WORLD-001 | `world` | Assigned, awaiting PR | Scene root/marker contract, collision, Godot parse + world test evidence |
| #2 PLAYER-001 | `player-combat` | Assigned, awaiting PR | Controller API/signals, shooting and damage tests, Godot parse evidence |
| #3 AI-001 | `enemy-ai` | Assigned, awaiting PR | Patrol/LOS/death tests, dependency-free target lookup, Godot parse evidence |
| #4 MISSION-001 | `missions-ui` | Assigned, awaiting PR | Valid/invalid state transitions, HUD signals, Godot parse evidence; final wiring waits for #1 and #2 |

**Master review rule:** For every incoming PR inspect base=`dev`, head branch, exact changed file list, ownership boundaries, commit diff, review threads, checks and raw test evidence. Block incomplete or conflicting PRs. Verify cross-worker interface compatibility. Only after verification merge one PR at a time to `dev`, and re-evaluate the remaining PRs against the new `dev`. Never auto-merge to `main`.

**Master integration backlog:** Wire Island 01 world, player, guard spawning, mission controller and HUD using only master-owned files. Execute actual Godot 4 integrated play loop: beach spawn → traverse → guard encounter → objective → extraction; test failure/invalid extraction too. Update issues and coordination only after execution evidence.

**Proposed Cycle 02 (not yet dispatched):** Island 01 stability and integration regressions first; then WORLD-002, PLAYER-002, AI-002, UI-002, SAVE-001 as dependencies permit.

## Cycle 01 verification — 2026-11-20

All four worker PRs target `dev` and all 17 changed files are within their owner’s paths. The four PRs were drafts with no recorded reviews, inline review threads or combined commit statuses at verification. The current cycle had no new worker-chat dispatch.

| Workstream | PR and verified head | Execution result | Next gate |
|---|---|---|---|
| `world` | #5 (`8ac5936`) | World contract passed (exit 0, 39 solid colliders). | Review the island visually and verify traversal from beach to outpost and extraction with the player. Provide a navigation region if navigation mode is enabled. |
| `player-combat` | #6 (`6bd1fc9`) | Player focused test passed (exit 0). | At integration set the weapon ray mask to include guard layer 2 and geometry layer 1. Bind HUD signals before the player emits its initial values. |
| `enemy-ai` | #7 (`c020df6`) | Guard suite failed to parse (exit 1) at line 94: array `deaths` compared to an integer. After a local correction, the suite reached line 60 and rejected the untyped patrol array. | Fix both test issues in the enemy-owned test and rerun. Test target injection and patrol routes on the island. Keep direct steering until a navigation region is available. |
| `missions-ui` | #8 (`2e4d1bd`) | Mission controller and HUD focused tests passed (both exit 0). | Wait for world and player integration. Bind injected state, map objective and extraction markers to progression, and route player death to mission failure. |

Godot 4.6.3 headless. Original `dev` main scene fails to load because its three child nodes omit `parent="."`. A local correction loaded the bootstrap cleanly in all four snapshots.

Re-run the focused suites against the latest candidate commits before merging. Once the bootstrap PR is approved and merged to `dev`, review and merge eligible worker PRs one at a time, rechecking each against the updated base. Hold guard AI for a passing rerun and wire missions only after the world and player contracts land. Guard navigation and player/guard collision masks need an integrated check. Run the beach-to-extraction playthrough and the player-death and premature-extraction cases before closing acceptance.

## Cycle 01 post-bootstrap verification — 2026-11-20

PR #9 merged into `dev` at `ebdbcfe9cc7649b45c3b134d88cefd79358c8182` after a clean Godot 4.6.3 headless import and startup at the approved head. All four worker snapshots also imported and started cleanly with the merged bootstrap.

| PR | Verified worker head | Status and next action |
|---|---|---|
| #5 | `8ac5936` | World contract passed (exit 0, 39 solid colliders). Ready for maintainer review. Verify visible landmarks and player traversal in the integrated Island 01 playthrough (#10). |
| #6 | `6bd1fc9` | Player controller and combat suite passed (exit 0). Ready for maintainer review. Master will include world layer 1 and guard layer 2 in the player's hitscan mask and verify actual guard hits in #10. |
| #7 | `c020df6` | Published head remains blocked. In `tests/enemies/guard_ai_test.gd`, compare `deaths[0]` to `1` (line 94), and assign an explicitly typed `Array[NodePath]` to `guard.patrol_points` (line 60). The original suite exits 1. Applying both fixes in a local diagnostic copy passed all 13 assertions, exit 0. Commit these corrections on `enemy-ai` and rerun the original focused script at the new PR head before requesting approval. |
| #8 | `2e4d1bd` | Mission and HUD suites both passed (exit 0 each). Ready for maintainer review. Merge after world and player land. Bind HUD signals before player initialization and route objective, extraction, and death in #10. |

All worker PRs remain drafts with no recorded approval. Merge approved worker PRs one at a time into `dev` and recheck the updated base after each merge. Merge the world and player contracts before the mission PR. Verify and approve the guard fixes separately.

[INTEGRATION-001 #10](https://github.com/gauravprajapat-23/commando-assesian/issues/10) tracks Master-owned wiring and acceptance. The full playthrough, early extraction, player death, guard interaction, and HUD checks remain pending.

## Cycle 01 integration — 2026-11-20

- PR #5 merged into `dev` at `cbce65e181894586c85b2b655bdc1aadf2907d5e`. WORLD-001 passed with 39 colliders and the expected spawn/mission markers. Draft #11 exercised beach-to-outpost traversal and return in the combined candidate. Rendered landmark review remains in #10.
- PR #6 merged into `dev` at `a7eac1aa9f5ff1c2dc67a2aa4559aaca8683613f`. PLAYER-001 passed after #5 landed. Draft #11 includes both world and actor layers in hitscan and verifies actual guard hits plus ammo and health HUD updates.
- PR #7 ready for independent approval at `a2dade3afc4d172238881ea5104ba61f5a45ea76`. The test now checks `deaths[0]` and assigns a typed `Array[NodePath]`. Godot 4.6.3 clean import and all 13 guard assertions passed at the committed head against the post-#8 candidate. #11 depends on #7 landing in `dev`.
- PR #8 merged into `dev` at `94de496416ac61543094d9fa7dec6fdd4290a4fb` after world and player landed and all four cumulative suites passed. Draft #11 verifies initial HUD binding, premature-extraction rejection, objective completion, success, and death handling.
- Master wiring is in draft #11 at `8a46cfb1e8c8598f91cbef2532e5320ab476e8e5`. The local candidate used post-#8 dev plus the exact #7 head and the Master wiring. Godot 4.6.3 import, startup, five focused suites, and all 10 integration checks passed. The test physically traverses the route using injected player input. A separate encounter verifies actual guard damage and player hitscan. Review #7, land it in dev after approval, rerun the full gate on the resulting tree, then do a rendered keyboard/mouse playthrough and review #11. Cycle 02 remains queued behind acceptance.

The repository owner explicitly authorized merges for #5, #6 and #8. GitHub rejected self-approval. Commit-anchored technical reviews documented the decisions and GitHub accepted the authorized sequential merges to dev. #7 awaits independent approval.

### Cycle 02 queue

Begin after #10 acceptance. First verify a clean rendered keyboard/mouse session, reproducible startup and mission replay, and a stable HUD at common resolutions. Then scope Android touch controls and safe-area checks under UI-002. Defer new islands, enemy expansions, and equipment until the Island 01 baseline is accepted.
