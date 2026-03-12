# Copilot instructions for `dzVents`

These instructions apply first when working in `domoticz\scripts\dzVents`.

## Scope and source of truth

- Read `.github\tasks\todo\RETROCONCEPTION_dzVents.md` before changing architecture or behavior.
- Read `.github\tasks\todo\PLAN_ACTIONS_dzVents.md` before proposing refactoring or roadmap work.
- Read `domoticz\scripts\dzVents\global_data.lua` before editing any dzVents script because constants, helpers, device names, HTTP wrappers, and shared state are centralized there.
- If documentation and code diverge, trust the code first, then update documentation in the same change when relevant.

## Architectural rules

- Treat the dzVents folder as an event-driven system built around scenes, devices, groups, custom events, and HTTP callbacks.
- Preserve the role split between:
  - `global_*` scripts for shared helpers and shared state,
  - `Freebox_*` and `Tydom_*` for external integrations,
  - `Device_*` and `Devices_*` for business behavior,
  - `Groupes_*` for group synchronization,
  - `Scene_*` for daily orchestration.
- Keep `domoticz.globalData.scenePhase` coherent across scene-related changes.
- Preserve `uuid` propagation and log correlation across chained events and HTTP calls.

## Work priorities

Until stabilization is complete, prioritize in this order:

1. fix confirmed bugs,
2. secure shared state and scene phase handling,
3. improve HTTP error handling and integration robustness,
4. reduce hard-coded coupling,
5. refactor duplication and improve observability,
6. only then add new features.

## Confirmed weak points to treat first

When you touch the relevant scripts, check these issues first:

- `Tydom_heat_getTemp.lua`: use `nil`, not `null`.
- `global_data.lua`: avoid implicit globals such as `suffixeMode`.
- `Device_Mode_Domicile.lua`: verify previous mode tracking is updated correctly.
- `Device_Presence_Domicile.lua`: compare and store simple state values, not device objects.
- `Scene_4_Nuit_2.lua`: keep scene phase handling aligned with the rest of the scene flow.
- `global_HTTP_response.lua`: current behavior is mostly logging only, with limited resilience.
- Tydom IDs and many Domoticz object names are hard-coded and must be handled carefully.

## Editing rules for dzVents scripts

- Make small, surgical changes scoped to one functional flow at a time.
- Do not refactor multiple domains in one change unless necessary to keep behavior correct.
- Before editing a script, identify:
  - its triggers,
  - emitted custom events,
  - devices, scenes, groups, and variables it reads,
  - side effects on Domoticz, Freebox, and Tydom.
- Preserve existing event names unless a migration is explicitly part of the task.
- Do not rename Domoticz devices, groups, scenes, or user variables unless the task explicitly includes a migration plan.
- Do not remove existing `uuid` logging patterns without providing an equivalent traceability mechanism.

## Rules by domain

### Scenes

- Keep phase tracking consistent with `Device_Label_Scene_Phase.lua`.
- Verify impacts on heating, lights, shutters, and presence-driven replays.
- Avoid introducing divergent behavior between equivalent day-phase scenes unless intentional and documented.

### Presence

- Revalidate the full flow `Freebox_LAN_statuts` -> `Devices_Telephones` -> `Device_Presence_Domicile` -> downstream consumers.
- Be careful with debounce logic and replay side effects.

### Tydom

- Distinguish clearly between write flows and read/reconciliation flows.
- Avoid leaving Domoticz state inconsistent with the real Tydom state.
- Document any new external identifier or mapping.

### Freebox

- Preserve the authentication sequence unless the task explicitly redesigns it.
- Treat shell command construction as sensitive.
- Prefer robustness and safety over optimization.

### Groups

- Validate both directions: group to items and items to group.
- Avoid breaking intermediate levels or silent realignment logic.

## Validation expectations

For dzVents changes, validate at least:

- the direct script behavior,
- the full cross-script flow impacted by the change,
- shared state consistency, especially `scenePhase`,
- logging clarity for the modified path,
- related documentation when behavior or assumptions change.

## What not to do

- Do not rewrite the whole dzVents architecture in one pass.
- Do not mix bug fixes, new features, and broad refactors in the same change without a clear reason.
- Do not introduce new external dependencies casually.
- Do not assume hard-coded IDs or names are safe to change without checking all dependent scripts.
