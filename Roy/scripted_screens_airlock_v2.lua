local ui = ss.ui.surface("main")
local LT = ic.enums.LogicType
local LBM = ic.enums.LogicBatchMethod

ss.ui.activate("main")
ui:clear()

-- Get screen dimensions
local size = ui:size()
local W, H = size.w, size.h -- TODO: use screen sizes for layout
local margin = 20
local columnWidth = (W - margin) / 3
local rowHeight = (H - margin) / 3

local sensorHash = -1252983604 -- Gas Sensor
local pipeAnalyzerHash = 435685051
local aHash = hash("A")
local bHash = hash("B")
local mHash = hash("M")
local pressure = 0
local historyLength = 50
local pressureAHistory = {}
local pressureMHistory = {}
local pressureBHistory = {}

for i = 1, historyLength do
    pressureAHistory[i] = 0
    pressureMHistory[i] = 0
    pressureBHistory[i] = 0
end

local title = ui:element({
    id = "title",
    type = "label",
    rect = { unit = "px", x = (W / 2) - 60, y = -45, w = columnWidth - margin, h = rowHeight },
    props = { text = "Airlock Status" },
    style = { font_size = 18, color = "#22C55E" }
})

local a_label = ui:element({
    id = "a_label",
    type = "label",
    rect = { unit = "px", x = margin + columnWidth * 2, y = 0, w = columnWidth - margin, h = rowHeight },
    props = { text = "Side A" },
    style = { font_size = 18, color = "#22C55E" }
})

local a_status = ui:element({
    id = "a",
    type = "label",
    rect = { unit = "px", x = margin + columnWidth * 2, y = margin, w = columnWidth - margin, h = rowHeight },
    props = { text = "A" },
    style = { font_size = 18, color = "#22C55E" }
})

local a_spark = ui:element({ id = "a_spark", type = "sparkline",
    rect = { unit = "px", x = margin + columnWidth * 2, y = margin + rowHeight, w = columnWidth - margin, h = rowHeight },
    props = { data = pressureAHistory, min = 0, max = 200 },
    style = { bg = "#111827", line_color = "#22C55E", fill_color = "#22C55E20" },
})

local m_label = ui:element({
    id = "m_label",
    type = "label",
    rect = { unit = "px", x = margin + columnWidth * 1, y = 0, w = columnWidth - margin, h = rowHeight },
    props = { text = "Airlock"  },
    style = { font_size = 18, color = "#22C55E" }
})

local m_status = ui:element({
    id = "airlock",
    type = "label",
    rect = { unit = "px", x = margin + columnWidth * 1, y = margin, w = columnWidth - margin, h = rowHeight },
    props = { text = "M"  },
    style = { font_size = 18, color = "#22C55E" }
})

local m_spark = ui:element({ id = "m_spark", type = "sparkline",
    rect = { unit = "px", x = margin + columnWidth * 1, y = margin + rowHeight, w = columnWidth - margin, h = rowHeight },
    props = { data = pressureMHistory, min = 0, max = 200 },
    style = { bg = "#111827", line_color = "#22C55E", fill_color = "#22C55E20" },
})

local b_label = ui:element({
    id = "b_label",
    type = "label",
    rect = { unit = "px", x = margin, y = 0, w = columnWidth - margin, h = rowHeight },
    props = { text = "Side B"  },
    style = { font_size = 18, color = "#22C55E" }
})

local b_status = ui:element({
    id = "b",
    type = "label",
    rect = { unit = "px", x = margin, y = margin, w = columnWidth - margin, h = rowHeight },
    props = { text = "B"  },
    style = { font_size = 18, color = "#22C55E" }
})

local b_spark = ui:element({ id = "b_spark", type = "sparkline",
    rect = { unit = "px", x = margin, y = margin + rowHeight, w = columnWidth - margin, h = rowHeight },
    props = { data = pressureBHistory, min = 0, max = 200 },
    style = { bg = "#111827", line_color = "#22C55E", fill_color = "#22C55E20" },
})

local buffer_label = ui:element({
    id = "buffer_label",
    type = "label",
    rect = { unit = "px", x = margin, y = margin + rowHeight * 2,  w = columnWidth - margin, h = rowHeight },
    props = { text = "Buffer Tanks"  },
    style = { font_size = 18, color = "#22C55E" }
})

local buffer_gauge = ui:element({
    id = "buffer_gauge", type = "gauge",
    rect = { unit = "px", x = margin + columnWidth * 1, y = margin + rowHeight * 2,  w = columnWidth - margin, h = rowHeight },
    props = {
        value = 0,
        min = 0,
        max = 50000,
        warn = 0.65,
        danger = 0.85,
        label = "PRESSURE",
        unit = " kPa",
    },
    style = {
        bg = "#111827",
        arc_thickness = 8,
        font_size = 12,
        value_color = "#E2E8F0",
        label_color = "#64748B",
    }
})

ui:commit()

local accum = 0
function tick(dt)
    accum = accum + dt
    if accum < 0.5 then return end
    accum = accum - 0.5
    
    pressure = ic.batch_read_name(sensorHash, aHash, LT.Pressure, LBM.Average)    
    a_status:set_props({ text = string.format("%.3f", pressure) .. " kPa" })
    table.remove(pressureAHistory, 1)
    pressureAHistory[#pressureAHistory + 1] = pressure
    a_spark:set_props({ data = pressureAHistory })
    
    pressure = ic.batch_read_name(sensorHash, mHash, LT.Pressure, LBM.Average)
    m_status:set_props({ text = string.format("%.3f", pressure) .. " kPa" })
    table.remove(pressureMHistory, 1)
    pressureMHistory[#pressureMHistory + 1] = pressure
    m_spark:set_props({ data = pressureMHistory })
    
    pressure = ic.batch_read_name(sensorHash, bHash, LT.Pressure, LBM.Average)
    b_status:set_props({ text = string.format("%.3f", pressure) .. " kPa" })
    table.remove(pressureBHistory, 1)
    pressureBHistory[#pressureBHistory + 1] = pressure
    b_spark:set_props({ data = pressureBHistory })
    
    pressure = ic.batch_read_name(pipeAnalyzerHash, mHash, LT.Pressure, LBM.Average)
    buffer_label:set_props({ text = "Buffer Tanks: " .. string.format("%.3f", pressure) .. " kPa" })
    buffer_gauge:set_props({ value = pressure })
    
    ui:commit()
end