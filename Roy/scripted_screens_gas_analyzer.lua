-- Gas analyzer display
-- Reads a Pipe Analyzer and shows:
--   * the icon of the primary (dominant) gas in the network, centered
--   * a vertical colored stacked bar (left) with one segment per gas
--   * a vertical pressure bar (right), scaled 0 kPa .. 40 MPa
--
-- Inspired by scripted_screens_atmos_v2.lua.

-- === Configuration ====================================================
local ANALYZER_NAME = "Pipe Analyzer" -- in-game name of the Pipe Analyzer
local MAX_PRESSURE  = 40000           -- kPa shown at the top of the right bar (40 MPa)
-- ======================================================================

local ui  = ss.ui.surface("main")
local LT  = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

local pipeAnalyzerTypeHash = 435685051
local pipeAnalyzerNameHash = hash(ANALYZER_NAME)

-- Gas table: each entry maps a Pipe Analyzer ratio reading to a color + icon.
-- Add or remove rows here to match the gases you care about. The `ratio`
-- field uses the LogicType enum names exposed by this StationeersLua build.
local gases = {
    { name = "Oxygen",            ratio = LT.RatioOxygen,           color = "#3B82F6", icon = ss.ui.icons.gas.Oxygen },
    { name = "Nitrogen",          ratio = LT.RatioNitrogen,         color = "#CBD5E1", icon = ss.ui.icons.gas.Nitrogen },
    { name = "Carbon Dioxide",    ratio = LT.RatioCarbonDioxide,    color = "#6B7280", icon = ss.ui.icons.gas.CarbonDioxide },
    { name = "Methane",           ratio = LT.RatioMethane,          color = "#EAB308", icon = ss.ui.icons.gas.Methane },
    { name = "Pollutant",         ratio = LT.RatioPollutant,        color = "#84CC16", icon = ss.ui.icons.gas.Pollutant },
    { name = "Nitrous Oxide",     ratio = LT.RatioNitrousOxide,     color = "#EC4899", icon = ss.ui.icons.gas.NitrousOxide },
    { name = "Water",             ratio = LT.RatioWater,            color = "#06B6D4", icon = ss.ui.icons.gas.Water },
    { name = "Steam",             ratio = LT.RatioSteam,            color = "#22D3EE", icon = ss.ui.icons.gas.Steam },
    { name = "Hydrogen",          ratio = LT.RatioHydrogen,         color = "#EF4444", icon = ss.ui.icons.gas.Hydrogen },
    { name = "Helium",            ratio = LT.RatioHelium,           color = "#A78BFA", icon = ss.ui.icons.gas.Helium },
    { name = "Hydrazine",         ratio = LT.RatioHydrazine,        color = "#F97316", icon = ss.ui.icons.gas.Hydrazine },
    { name = "Hydrochloric Acid", ratio = LT.RatioHydrochloricAcid, color = "#A3E635", icon = ss.ui.icons.gas.HydrochloricAcid },
    { name = "Ozone",             ratio = LT.RatioOzone,            color = "#6366F1", icon = ss.ui.icons.gas.Ozone },
    { name = "Silanol",           ratio = LT.RatioSilanol,          color = "#D946EF", icon = ss.ui.icons.gas.Silanol },
    { name = "Polluted Water",    ratio = LT.RatioPollutedWater,    color = "#4D7C0F", icon = ss.ui.icons.gas.PollutedWater },
}

ss.ui.activate("main")
ui:clear()

local size = ui:size()
local W, H = size.w, size.h

-- Layout ---------------------------------------------------------------
local barY = H * 0.14
local barH = H * 0.72

local stackX = W * 0.06
local stackW = W * 0.16

local pressX = W * 0.78
local pressW = W * 0.16

local iconSize = math.min(W * 0.36, H * 0.46)
local iconX = (W / 2) - (iconSize / 2)
local iconY = H * 0.20

-- Background -----------------------------------------------------------
ui:element({
    id = "bg", type = "panel",
    rect = { unit = "px", x = 0, y = 0, w = W, h = H },
    style = { bg = "#0B1120" },
})

-- Left: stacked gas-mix bar (drawn on a canvas in tick) ----------------
ui:element({
    id = "stack_title", type = "label",
    rect = { unit = "px", x = stackX, y = barY - H * 0.09, w = stackW, h = H * 0.08 },
    props = { text = "Gas Mix" },
    style = { font_size = 13, color = "#64748B", align = "center" },
})

ui:element({
    id = "stack", type = "canvas",
    rect = { unit = "px", x = stackX, y = barY, w = stackW, h = barH },
})

-- Center: primary gas icon + name --------------------------------------
local primaryIcon = ui:element({
    id = "primary_icon", type = "icon",
    rect = { unit = "px", x = iconX, y = iconY, w = iconSize, h = iconSize },
    props = { name = gases[1].icon },
    style = { tint = gases[1].color },
})

local primaryLabel = ui:element({
    id = "primary_label", type = "label",
    rect = { unit = "px", x = W * 0.25, y = iconY + iconSize, w = W * 0.50, h = H * 0.10 },
    props = { text = "--" },
    style = { font_size = 22, color = "#E2E8F0", align = "center" },
})

local primaryPct = ui:element({
    id = "primary_pct", type = "label",
    rect = { unit = "px", x = W * 0.25, y = iconY + iconSize + H * 0.09, w = W * 0.50, h = H * 0.08 },
    props = { text = "" },
    style = { font_size = 15, color = "#64748B", align = "center" },
})

-- Right: pressure bar --------------------------------------------------
ui:element({
    id = "press_title", type = "label",
    rect = { unit = "px", x = pressX, y = barY - H * 0.09, w = pressW, h = H * 0.08 },
    props = { text = "Pressure" },
    style = { font_size = 13, color = "#64748B", align = "center" },
})

local pressBar = ui:element({
    id = "press_bar", type = "progress",
    rect = { unit = "px", x = pressX, y = barY, w = pressW, h = barH },
    props = { value = 0, min = 0, max = MAX_PRESSURE, direction = "btt" },
    style = { bg = "#111827", fill = "#22C55E" },
})

local pressLabel = ui:element({
    id = "press_label", type = "label",
    rect = { unit = "px", x = pressX, y = barY + barH + H * 0.01, w = pressW, h = H * 0.08 },
    props = { text = "0 kPa" },
    style = { font_size = 13, color = "#E2E8F0", align = "center" },
})

ui:commit()

-- Helpers --------------------------------------------------------------
local function readRatios()
    local raw, total = {}, 0
    for i = 1, #gases do
        local r = ic.batch_read_name(pipeAnalyzerTypeHash, pipeAnalyzerNameHash, gases[i].ratio, LBM.Average)
        if r ~= r or r < 0 then r = 0 end -- guard against NaN / negatives
        raw[i] = r
        total = total + r
    end
    return raw, total
end

-- Draw the stacked gas-mix bar onto the "stack" canvas, segments
-- proportional to each gas ratio, stacked from the bottom up.
local function drawStack(raw, total)
    ui:canvas_clear("stack", "#111827")
    if total > 0 then
        local cum = 0
        for i = 1, #gases do
            local frac = raw[i] / total
            if frac > 0.001 then
                local segH = frac * barH
                local y = barH - cum - segH
                ui:canvas_rect("stack", 0, y, stackW, segH, gases[i].color)
                cum = cum + segH
            end
        end
    end
    ui:canvas_rect_outline("stack", 0, 0, stackW, barH, "#1E293B", 2)
    ui:canvas_apply("stack")
end

-- Tick -----------------------------------------------------------------
local accum = 0
function tick(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = accum - 0.5

    local raw, total = readRatios()
    drawStack(raw, total)

    -- Primary gas = largest ratio.
    local primary = 1
    for i = 2, #gases do
        if raw[i] > raw[primary] then primary = i end
    end
    if total > 0 then
        local primaryFrac = raw[primary] / total
        local g = gases[primary]
        primaryIcon:set_props({ name = g.icon })
        primaryIcon:set_style({ tint = g.color })
        primaryLabel:set_props({ text = g.name })
        primaryPct:set_props({ text = string.format("%.1f%% of mix", primaryFrac * 100) })
    else
        primaryLabel:set_props({ text = "Empty" })
        primaryPct:set_props({ text = "" })
    end

    -- Pressure bar.
    local pressure = ic.batch_read_name(pipeAnalyzerTypeHash, pipeAnalyzerNameHash, LT.Pressure, LBM.Average)
    if pressure ~= pressure or pressure < 0 then pressure = 0 end
    pressBar:set_props({ value = pressure })

    local fill = "#22C55E"
    if pressure >= MAX_PRESSURE * 0.85 then
        fill = "#EF4444"
    elseif pressure >= MAX_PRESSURE * 0.65 then
        fill = "#EAB308"
    end
    pressBar:set_style({ fill = fill })

    if pressure >= 1000 then
        pressLabel:set_props({ text = string.format("%.2f MPa", pressure / 1000) })
    else
        pressLabel:set_props({ text = string.format("%d kPa", math.floor(pressure)) })
    end

    ui:commit()
end
