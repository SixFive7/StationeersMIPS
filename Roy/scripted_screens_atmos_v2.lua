local ui = ss.ui.surface("main")
local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

local pipeAnalyzerTypeHash = 435685051
local pipeAnalyzerNameHash = hash("Pipe Analyzer")

ss.ui.activate("main")
ui:clear()

local size = ui:size()
local W, H = size.w, size.h
local historyLength = 50
local pressureHistory = {}
local temperatureHistory = {}

for i = 1, historyLength do
    pressureHistory[i] = 0    
    temperatureHistory[i] = 0
end

function leftPad(str, requiredLength)
    str = tostring(str)

    if #str >= requiredLength then
        return str
    end

    local padding = string.rep(" ", requiredLength - #str)
    return padding .. str
end

local function createCell(id, title)  
    local x = W * 0.01
    local y = H * 0.01
    local w = W * 0.98
    local h = H * 0.98

    local spark = ui:element({
        id = id .. "_spark",
        type = "sparkline",
        rect = { unit = "px", x = x, y = y, w = w, h = h },
        props = { min = 0, max = 1 },
        style = { bg = "#111827", line_color = "#888888", fill_color = "#333333" },
    })
        
    local label = ui:element({
        id = id .. "_label",
        type = "label",
        rect = { unit = "px", x = x, y = y, w = w, h = h },
        props = { text = title },
        style = { font_size = 90, color = "#ffffff" }
    })

    return label, spark
end

local m_label, m_spark = createCell("m", "Status")

ui:commit()

local accum = 0
local state = 0
function tick(dt)
    accum = accum + dt
    state = state + dt
    if accum < 0.5 then return end
    accum = accum - 0.5
    
    local pressure = math.floor(ic.batch_read_name(pipeAnalyzerTypeHash, pipeAnalyzerNameHash, LT.Pressure, LBM.Average))        
    local fill = math.floor((pressure / 40000.0) * 100.0)
    table.remove(pressureHistory, 1)    
    pressureHistory[#pressureHistory + 1] = pressure

    local temperature = math.floor(ic.batch_read_name(pipeAnalyzerTypeHash, pipeAnalyzerNameHash, LT.Temperature, LBM.Average))
    table.remove(temperatureHistory, 1)    
    temperatureHistory[#temperatureHistory + 1] = temperature

    local padding = 8

    if state < 2 then        
        m_label:set_props({ text = leftPad("Pressure", padding) .. "\n" .. leftPad(pressure, padding) .. "\n" .. leftPad("kPA", padding) })
        m_spark:set_props({ data = pressureHistory, min = 0, max = 40000 })
    elseif state < 4 then
        m_label:set_props({ text = leftPad(temperature .. "K", 8) })
        m_spark:set_props({ data = temperatureHistory, min = 0, max = 40000 })
    else
        m_label:set_props({ text = leftPad(fill .. "%", 8) })
        m_spark:set_props({ data = pressureHistory, min = 0, max = 40000 })
    end
    
    if state >= 6 then    
        state = 0
    end

    ui:commit()
end