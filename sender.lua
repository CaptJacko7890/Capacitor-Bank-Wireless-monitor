local component = require("component")
local event = require("event")
local term = require("term")
local os = require("os")
local gpu = component.gpu
local serialization = require("serialization")

gpu.setResolution(50, 15)

local capBank = component.capacitor_bank -- replace if your address is custom
local modem = component.modem
local port = 619

modem.open(port)

local screenWidth, screenHeight = gpu.getResolution()
term.clear()
term.setCursorBlink(false)

local function centerText(text, y, color)
  color = color or 0xFFFFFF
  local x = math.floor((screenWidth - #text) / 2) + 1
  gpu.setForeground(color)
  term.setCursor(x, y)
  io.write(text)
end

local function drawProgressBar(y, percent)
  local barWidth = screenWidth - 10
  local filled = math.floor(barWidth * percent)
  local empty = barWidth - filled

  local x = math.floor((screenWidth - barWidth) / 2)
  term.setCursor(x, y)

  gpu.setForeground(0x00FF00)
  io.write(string.rep("█", filled))

  gpu.setForeground(0x222222)
  io.write(string.rep("░", empty))
end

local function drawUI(data)
  term.clear()
  centerText("=== Capacitor Data Sender ===", 2, 0x00FF00)
  centerText("Sending capacitor data...", 4, 0xFFFFFF)

  if data then
    local percent = data.stored / data.max
    centerText(string.format("Stored Energy: %d / %d", data.stored, data.max), 6)
    centerText(string.format("Charge Level : %.1f%%", percent * 100), 7)
    drawProgressBar(8, percent)
    centerText(string.format("Input Rate   : %.2f RF/t", data.input), 10)
    centerText(string.format("Output Rate  : %.2f RF/t", data.output), 11)
  else
    centerText("Unable to read capacitor data", 6, 0xFF5555)
  end

  centerText("Press Q to quit.", screenHeight - 2, 0xFF5555)
end

local function getCapData()
  return {
    stored = capBank.getEnergyStored(),
    max = capBank.getMaxEnergyStored(),
    input = capBank.getAverageInputPerTick(),
    output = capBank.getAverageOutputPerTick()
  }
end

drawUI(getCapData())

local running = true
while running do
  local evt = {event.pull(0.5)}

  if evt[1] == "key_down" then
    local charCode = evt[3]
    if charCode and string.char(charCode):lower() == "q" then
      running = false
      break
    end
  end

  -- Send updated data
  local data = getCapData()
  local serialized = serialization.serialize(data)
  modem.broadcast(port, "cap_data", serialized)
  drawUI(data)
end

term.setCursor(1, screenHeight)
gpu.setForeground(0xFFFFFF)
print("Sender shutting down...")
