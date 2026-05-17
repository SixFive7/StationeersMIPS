# CLAUDE.md

Guidance for Claude Code when working in this folder.

## What this is

This folder holds automation scripts for the game **Stationeers**, written during
Roy's playthrough. There are two kinds of files:

- `*.ic10` — **IC10 MIPS** assembly for in-game Integrated Circuit (IC10) chips.
  These control doors, vents, sensors, sorters, furnaces, solar panels, etc.
- `*.lua` — **Lua** scripts that drive in-game display screens.

Both depend on community mods. IC10 chips need extended capabilities; the Lua and
screen features come from these mods:

- **StationeersLua** — Lua scripting runtime.
  Docs: https://orbitalfoundrymodteam.github.io/StationeersLuaDocs/
- **ScriptedScreens** — programmable display surfaces.
  Docs: https://orbitalfoundrymodteam.github.io/ScriptedScreensDocs/

Other mods used in this playthrough (see `../README.md`): More Lines of Code,
Programmable Sign Mod, FloodLightMod, MorePowerMod.

IC10 reference: https://stationeers-wiki.com/IC10

## Trustworthy game data

The official wiki can lag behind the game. For accurate, up-to-date data on
gases, chemistry, and other game systems, prefer this repository:

- https://github.com/SixFive7/StationeersPlus/tree/master/Research
- Gas-phase data specifically:
  https://github.com/SixFive7/StationeersPlus/blob/master/Research/GameSystems/ChemistryGasPhaseData.md

## Gases

- Gas amounts on a device are read via the `Ratio<Gas>` LogicTypes
  (e.g. `LT.RatioOxygen`, `LT.RatioCarbonDioxide`).
- The gas list is larger than the old playthroughs: besides Oxygen, Nitrogen,
  CarbonDioxide, Pollutant, NitrousOxide, Water and Steam, the chemistry update
  added Helium, Hydrazine, HydrochloricAcid, Hydrogen, Ozone, Silanol and
  PollutedWater.
- Naming gotcha: the old **Volatiles** gas is now **Methane** — use
  `LT.RatioMethane`, *not* `LT.RatioVolatiles` (which no longer exists).
- When unsure which `Ratio*` LogicTypes a build exposes, iterate the enum:
  `for k in pairs(LT) do ... end`. See `scripted_screens_gas_analyzer.lua`.

## IC10 conventions (`*.ic10`)

- Device types are referenced by **type hash**, defined up top with
  `define NAME <hash>` (e.g. `define BLAST_DOOR 337416191`).
- Named devices on a batch use **name hashes** via `define X HASH("X")`, then
  addressed with batch-by-name instructions (`lbn`, `sbn`).
- Registers `r0`–`r3` are scratch; later registers are `alias`ed to meaningful
  names (e.g. `alias entry r14`). `ra` holds the return address for `jal`/`j ra`
  subroutine calls. The stack (`push`/`pop`) passes extra args between routines.
- Code is organized as labelled subroutines; `_underscore` labels are internal
  jump targets within a routine. Comments above each routine explain intent.
- `yield` ends the current tick — loops that wait on sensors `yield` each pass.
- Watch the 128-line / register limits (More Lines of Code mod raises the line cap).

## Lua / ScriptedScreens conventions (`*.lua`)

- Start by grabbing the surface: `local ui = ss.ui.surface("main")`, then
  `ss.ui.activate("main")` and `ui:clear()`.
- Cache enum tables: `local LT = ic.enums.LogicType`,
  `local LBM = ic.enums.LogicBatchMethod`.
- Build UI elements once with `ui:element({ id, type, rect, props, style })`,
  call `ui:commit()`, then update them inside `tick(dt)` via `set_props` /
  `set_style` followed by another `ui:commit()`.
- `tick(dt)` runs every frame; throttle real work with an `accum` accumulator
  (e.g. only act every 0.5s).
- Read device logic values with `ic.batch_read_name(typeHash, nameHash, LT.X, LBM.Y)`.
- Element types seen here: `label`, `gauge`, `sparkline`, `spinner`, `panel`,
  `progress`, `icon`, `canvas`.
- Canvas drawing functions are **methods on the `ui` object**, not globals:
  `ui:canvas_clear(id, ...)`, `ui:canvas_rect(id, ...)`, `ui:canvas_apply(id)`,
  etc. Always call `ui:canvas_apply(id)` after drawing.
- Known pitfall: `ui:measure_text` crashes Unity — avoid it (see
  `scripted_screens_airlock_v3.lua`).
- The ScriptedScreens / StationeersLua docs are AI-generated and often wrong on
  exact names/signatures — verify against in-game errors.

## Working notes

- Files ending in `_v2` / `_v3` are iterations; the highest version is current.
- Type hashes are game/mod constants — reuse the ones already defined in these
  files rather than inventing new ones.
- This is game scripting: there is no build or test step. Changes are validated
  by pasting code into the game.
