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

local pipeAnalyzerHash = 435685051
local mixedHash = hash("Mixed")
local historyLength = 50
local pressureHistory = {}

for i = 1, historyLength do
    pressureHistory[i] = 0    
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
local function createAirlockCell(id, title, history, column, row, maxPressure)
    maxPressure = maxPressure or 200
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
            warn = 0.65,
            danger = 0.85,
            label = "kPa",
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

local title = createTitle("title", "Mixed Gasses")
local m_label, m_gauge, m_spark = createAirlockCell("m", "Dirty", pressureHistory, 1, 1, 50000)

ui:commit()

local accum = 0
function tick(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = accum - 0.5
    
    local pressure = ic.batch_read_name(pipeAnalyzerHash, mixedHash, LT.Pressure, LBM.Average)    
    table.remove(pressureHistory, 1)    
    pressureHistory[#pressureHistory + 1] = pressure
    m_spark:set_props({ data = pressureHistory })
   
    ui:commit()
end