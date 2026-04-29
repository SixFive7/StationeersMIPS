-- TODO: align title 
-- TODO: make spinners green by default and red when the airlock cycles (read the status of the doors)

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

local gasSensorHash = -1252983604
local pipeAnalyzerHash = 435685051
local aHash = hash("A")
local bHash = hash("B")
local mHash = hash("M")
local historyLength = 50
local pressureAHistory = {}
local pressureMHistory = {}
local pressureBHistory = {}
local pressureTHistory = {}

for i = 1, historyLength do
    pressureAHistory[i] = 0
    pressureMHistory[i] = 0
    pressureBHistory[i] = 0
    pressureTHistory[i] = 0
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
    local x = 0 --(W / 2) - (size.w / 2)
    local y = 0    
    local label = ui:element({
        id = id .. "_title",
        type = "label",
        rect = { unit = "px", x = x, y = y, w = W, h = cellHeight },
        props = { text = title },
        style = { font_size = 20, color = "#22C55E" }
    })

    return title
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

local title = createTitle("title", "Airlock Status")
local m_label, m_gauge, m_spark = createAirlockCell("m", "Airlock", pressureAHistory, 1, 1)
local t_label, t_gauge, t_spark = createAirlockCell("t", "Buffers", pressureTHistory, 2, 1, 1000)
local b_label, b_gauge, b_spark = createAirlockCell("b", "Side B", pressureBHistory, 1, 2)
local a_label, a_gauge, a_spark = createAirlockCell("a", "Side A", pressureMHistory, 2, 2)

local spinner = createSpinner("tl", 1, 1)
local spinner2 = createSpinner("tr", 2, 1)
local spinner3 = createSpinner("bl", 1, 2)
local spinner4 = createSpinner("br", 2, 2)

ui:commit()

local accum = 0
function tick(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = accum - 0.5
    
    local pressure = 0
    
    pressure = ic.batch_read_name(gasSensorHash, aHash, LT.Pressure, LBM.Average)    
    table.remove(pressureAHistory, 1)    
    pressureAHistory[#pressureAHistory + 1] = pressure
    
    pressure = ic.batch_read_name(gasSensorHash, mHash, LT.Pressure, LBM.Average)
    table.remove(pressureMHistory, 1)
    pressureMHistory[#pressureMHistory + 1] = pressure
    
    pressure = ic.batch_read_name(gasSensorHash, bHash, LT.Pressure, LBM.Average)
    table.remove(pressureBHistory, 1)
    pressureBHistory[#pressureBHistory + 1] = pressure

    pressure = ic.batch_read_name(pipeAnalyzerHash, mHash, LT.Pressure, LBM.Average)
    table.remove(pressureTHistory, 1)
    pressureTHistory[#pressureTHistory + 1] = pressure

    b_gauge:set_props({ value = pressureBHistory[#pressureBHistory] })
    b_spark:set_props({ data = pressureBHistory })

    m_gauge:set_props({ value = pressureMHistory[#pressureMHistory] })
    m_spark:set_props({ data = pressureMHistory })

    a_gauge:set_props({ value = pressureAHistory[#pressureAHistory] })
    a_spark:set_props({ data = pressureAHistory })

    t_gauge:set_props({ value = pressureTHistory[#pressureTHistory] })
    t_spark:set_props({ data = pressureTHistory })

    spinner:set_style({ color = "#65ff51"})

    ui:commit()
end