-- Filtration pressure display
-- Reads a single "Filtration" device and shows:
--   * a vertical input-pressure bar  (left),  scaled 0 .. 10 MPa
--   * a vertical output-pressure bar (right), scaled 0 .. 10 MPa
--   * a big pressure-differential read-out in the middle
--
-- Technique mirrors scripted_screens_gas_analyzer.lua.

-- === Configuration ====================================================
local DEVICE_NAME  = "Filtration"   -- in-game name of the Filtration device
local DEVICE_HASH  = -348054045     -- prefab/type hash of the Filtration device
local MAX_PRESSURE = 10000          -- kPa shown at the top of each bar (10 MPa)
-- ======================================================================

local ui  = ss.ui.surface("main")
local LT  = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

local deviceNameHash = hash(DEVICE_NAME)

ss.ui.activate("main")
ui:clear()

local size = ui:size()
local W, H = size.w, size.h

-- Layout ---------------------------------------------------------------
local barY = H * 0.14
local barH = H * 0.72

local inX,  inW  = W * 0.06, W * 0.16
local outX, outW = W * 0.78, W * 0.16

-- Background -----------------------------------------------------------
ui:element({
    id = "bg", type = "panel",
    rect = { unit = "px", x = 0, y = 0, w = W, h = H },
    style = { bg = "#000000" },
})

-- Left: input pressure bar ---------------------------------------------
ui:element({
    id = "in_title", type = "label",
    rect = { unit = "px", x = inX, y = barY - H * 0.09, w = inW, h = H * 0.08 },
    props = { text = "Input" },
    style = { font_size = 13, color = "#64748B", align = "center" },
})

local inBar = ui:element({
    id = "in_bar", type = "progress",
    rect = { unit = "px", x = inX, y = barY, w = inW, h = barH },
    props = { value = 0, min = 0, max = MAX_PRESSURE, direction = "btt" },
    style = { bg = "#111827", fill = "#22C55E" },
})

local inLabel = ui:element({
    id = "in_label", type = "label",
    rect = { unit = "px", x = inX, y = barY + barH + H * 0.01, w = inW, h = H * 0.08 },
    props = { text = "0 kPa" },
    style = { font_size = 13, color = "#E2E8F0", align = "center" },
})

-- Center: pressure differential ----------------------------------------
ui:element({
    id = "diff_title", type = "label",
    rect = { unit = "px", x = W * 0.25, y = H * 0.30, w = W * 0.50, h = H * 0.08 },
    props = { text = "Differential (In - Out)" },
    style = { font_size = 15, color = "#64748B", align = "center" },
})

local diffLabel = ui:element({
    id = "diff_label", type = "label",
    rect = { unit = "px", x = W * 0.20, y = H * 0.40, w = W * 0.60, h = H * 0.20 },
    props = { text = "0 kPa" },
    style = { font_size = 40, color = "#E2E8F0", align = "center" },
})

-- Right: output pressure bar -------------------------------------------
ui:element({
    id = "out_title", type = "label",
    rect = { unit = "px", x = outX, y = barY - H * 0.09, w = outW, h = H * 0.08 },
    props = { text = "Output" },
    style = { font_size = 13, color = "#64748B", align = "center" },
})

local outBar = ui:element({
    id = "out_bar", type = "progress",
    rect = { unit = "px", x = outX, y = barY, w = outW, h = barH },
    props = { value = 0, min = 0, max = MAX_PRESSURE, direction = "btt" },
    style = { bg = "#111827", fill = "#22C55E" },
})

local outLabel = ui:element({
    id = "out_label", type = "label",
    rect = { unit = "px", x = outX, y = barY + barH + H * 0.01, w = outW, h = H * 0.08 },
    props = { text = "0 kPa" },
    style = { font_size = 13, color = "#E2E8F0", align = "center" },
})

ui:commit()

-- Helpers --------------------------------------------------------------
local function readPressure(logicType)
    local p = ic.batch_read_name(DEVICE_HASH, deviceNameHash, logicType, LBM.Average)
    if p ~= p or p < 0 then p = 0 end -- guard against NaN / negatives
    return p
end

-- Pick a bar fill color based on how close the value is to the 10 MPa cap.
local function fillColor(value)
    if value >= MAX_PRESSURE * 0.85 then return "#EF4444" end
    if value >= MAX_PRESSURE * 0.65 then return "#EAB308" end
    return "#22C55E"
end

-- Format a pressure for the small bar labels (kPa below 1 MPa, MPa above).
local function fmtPressure(p)
    if p >= 1000 then
        return string.format("%.2f MPa", p / 1000)
    end
    return string.format("%d kPa", math.floor(p))
end

-- Tick -----------------------------------------------------------------
local accum = 0
function tick(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = accum - 0.5

    local pIn  = readPressure(LT.PressureInput)
    local pOutA = readPressure(LT.PressureOutput)
    local pOutB = readPressure(LT.PressureOutput2)
    local pOut = math.max(pOutA, pOutB) -- least differential

    -- Bars are clamped to the 0 .. 10 MPa display range.
    inBar:set_props({ value = math.min(pIn,  MAX_PRESSURE) })
    outBar:set_props({ value = math.min(pOut, MAX_PRESSURE) })
    inBar:set_style({ fill = fillColor(pIn) })
    outBar:set_style({ fill = fillColor(pOut) })

    inLabel:set_props({ text = fmtPressure(pIn) })
    outLabel:set_props({ text = fmtPressure(pOut) })

    -- Differential = input - output (the actual readings, not the clamped bars).
    local diff = pIn - pOut
    local sign = ""
    if diff > 0 then sign = "+" end
    if diff < 0 then sign = "-" end
    local mag = math.abs(diff)

    local diffText
    if mag >= 1000 then
        diffText = string.format("%s%.2f MPa", sign, mag / 1000)
    else
        diffText = string.format("%s%d kPa", sign, math.floor(mag))
    end
    diffLabel:set_props({ text = diffText })

    local diffColor = "#E2E8F0"
    if diff > 0 then diffColor = "#22C55E" end
    if diff < 0 then diffColor = "#EF4444" end
    diffLabel:set_style({ color = diffColor })

    ui:commit()
end
