-- Airlock code
-- Set the following variables according to the side of the airlock (A, A' or B, B')
local outsideId = "A"
local insideId = "A'"
--local outsideId = "B"
--local insideId = "B'"

local outsideHash = hash(outsideId)
local insideHash = hash(insideId)

local AIRLOCK_STATUS = "Airlock Status " .. outsideId
local INSIDE_LABEL = "Inside"
local OUTSIDE_LABEL = "Outside"
local BUFFER_LABEL = "Buffer"
local FORCEFIELD_POWER_LABEL = "Forcefield APC"
local AIRLOCK_POWER_LABEL = "Airlock APC"

--
local ui = ss.ui.surface("main")
local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

ss.ui.activate("main")
ui:clear()

local size = ui:size()
local W, H = size.w, size.h
local tableSize = 0.8
local tableMargin = 0.1
local wTable = W * tableSize
local hTable = H * tableSize
local horizontalMargin = 2
local verticalMargin = 2
local cellWidth = (wTable / 2) - (horizontalMargin * 2)
local cellHeight = (hTable / 2) - (verticalMargin * 2)

local blastDoorHash = 337416191
local gasSensorHash = -1252983604
local pipeAnalyzerHash = 435685051
local apcHash = 1999523701
local apcReversedHash = -1032513487
local historyLength = 50

--
local POWER_LABEL = (outsideId == "A") and FORCEFIELD_POWER_LABEL or AIRLOCK_POWER_LABEL
local selectedApcHash = (outsideId == "A") and apcReversedHash or apcHash

local pressureInsideHistory = {}
local pressureOutsideHistory = {}
local pressureBufferHistory = {}
local powerHistory = {}

for i = 1, historyLength do
    pressureInsideHistory[i] = 0
    pressureOutsideHistory[i] = 0
    pressureBufferHistory[i] = 0
    powerHistory[i] = 0
end

-- index is one based
local function cellX(i)        
    return (tableMargin * W) + horizontalMargin + (i - 1) * (cellWidth + horizontalMargin * 2)
end

-- index is one based
local function cellY(i)    
    return (tableMargin * H) + verticalMargin + (i - 1) * (cellHeight + verticalMargin * 2)
end

-- i is 1 or 2
local function cornerX(i)
    if i == 1 then
        return 0
    else
        return W - (W * tableMargin)
    end
end

-- i is 1 or 2
local function cornerY(i)
    if i == 1 then
        return 0
    else
        return H - (H * tableMargin)
    end
end

-- column and row are one based
local function createAirlockCell(id, title, history, column, row, maxPressure, dialLabel, invert)
    maxPressure = maxPressure or 200
    dialLabel = dialLabel or "kPa"
    invert = invert or false
    local x = cellX(column)
    local y = cellY(row)
    
    local labelHeight = cellHeight * 0.25
    local label = ui:element({
        id = id .. "_label",
        type = "label",
        rect = { unit = "px", x = x, y = y, w = cellWidth, h = labelHeight },
        props = { text = title },
        style = { font_size = 16, color = "#22C55E" }
    })

    local gaugeHeight = cellHeight * 0.55
    local gauge = ui:element({
        id = id .. "_gauge",
        type = "gauge",
        rect = { unit = "px", x = x, y = y + labelHeight, w = cellWidth, h = gaugeHeight },
        props = {
            value = 0,
            min = 0,
            max = maxPressure,
            warn = 0.75,
            danger = 0.90,
            label = dialLabel,
            invert = invert
        },
        style = {
            bg = "#111827",
            arc_thickness = 8,
            font_size = 12,
            value_color = "#E2E8F0",
            label_color = "#64748B",
        }
    })

    local sparkHeight = cellHeight * 0.2
    local spark = ui:element({
        id = id .. "_spark",
        type = "sparkline",
        rect = { unit = "px", x = x, y = y + labelHeight + gaugeHeight, w = cellWidth, h = sparkHeight },
        props = { data = history, min = 0, max = maxPressure },
        style = { bg = "#111827", line_color = "#22C55E", fill_color = "#22C55E20" },
    })

    return label, gauge, spark
end

local function createTitle(id, title)
    -- NOTE: measure_text text crashes Unity!
    -- local size = ui:measure_text(title, 200, 20, true)    
    local x = (W * 0.38)  --(W / 2) - (size.w / 2)
    local y = -70
    local label = ui:element({
        id = id .. "_title",
        type = "label",
        rect = { unit = "px", x = x, y = y, w = W, h = cellHeight },
        props = { text = title },
        style = { font_size = 20, color = "#22C55E" }
    })

    return label
end

local function createSpinner(id, column, row)    
    local x = cornerX(column)
    local y = cornerY(row)
    local w = tableMargin * W
    local h = tableMargin * H
    local spinner = ui:element({
        id = id .. "_spinner", type = "spinner",
        rect = { unit = "px", x = x, y = y, w = w, h = h },
        style = { color = "#f83838", thickness = h / 3 },
    })

    return spinner
end

local title = createTitle("title", AIRLOCK_STATUS)
local inside_label, inside_gauge, inside_spark = createAirlockCell("m", INSIDE_LABEL, pressureInsideHistory, 1, 1)
local outside_label, outside_gauge, outside_spark = createAirlockCell("a", OUTSIDE_LABEL, pressureOutsideHistory, 2, 1)
local buffer_label, buffer_gauge, buffer_spark = createAirlockCell("t", BUFFER_LABEL, pressureBufferHistory, 1, 2, 1000)
local power_label, power_gauge, power_spark = createAirlockCell("b", POWER_LABEL, powerHistory, 2, 2, 100, "%", true)

local spinner1 = createSpinner("tl", 1, 1)
local spinner2 = createSpinner("tr", 2, 1)
local spinner3 = createSpinner("bl", 1, 2)
local spinner4 = createSpinner("br", 2, 2)

ui:commit()

function updateCell(data, history, gauge, spark)    
    table.remove(history, 1)    
    history[#history + 1] = data
    gauge:set_props({ value = history[#history] })
    spark:set_props({ data = history })
end

local accum = 0
function tick(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = accum - 0.5

    local outsidePressure = ic.batch_read_name(gasSensorHash, outsideHash, LT.Pressure, LBM.Average)
    updateCell(outsidePressure, pressureOutsideHistory, outside_gauge, outside_spark) 
    
    local bufferPressure = ic.batch_read_name(pipeAnalyzerHash, outsideHash, LT.Pressure, LBM.Average)
    updateCell(bufferPressure, pressureBufferHistory, buffer_gauge, buffer_spark) 

    local insidePressure = ic.batch_read_name(gasSensorHash, insideHash, LT.Pressure, LBM.Average)
    updateCell(insidePressure, pressureInsideHistory, inside_gauge, inside_spark) 

    local power = ic.batch_read(selectedApcHash, LT.Ratio, LBM.Average)
    updateCell(power * 100, powerHistory, power_gauge, power_spark) 

    local open = ic.batch_read_name(blastDoorHash, outsideHash, LT.Open, LBM.Average)
    if open == 0 then
        spinner1:set_style({ color = "#ff5151"})
        spinner2:set_style({ color = "#ff5151"})
        spinner3:set_style({ color = "#ff5151"})
        spinner4:set_style({ color = "#ff5151"})
    else
        spinner1:set_style({ color = "#65ff51"})
        spinner2:set_style({ color = "#65ff51"})
        spinner3:set_style({ color = "#65ff51"})
        spinner4:set_style({ color = "#65ff51"})
    end
    

    ui:commit()
end