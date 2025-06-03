local component = require("component")
local event = require("event")
local term = require("term")
local os = require("os")
local gpu = component.gpu
local tunnel = component.tunnel -- Linked card
local serialization = require("serialization")

gpu.setResolution(50, 15)

local screenWidth, screenHeight = gpu.getResolution()
term.clear()
term.setCursorBlink(false)

local lastReceiveTime = os.time()
local connectionStatus = "Waiting for data..."
local lastStatus = connectionStatus
local latestData = nil
local lastDrawnData = nil
local lastStatusCheck = os.clock()
local checkInterval = 1
local timeout = 10

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

local function drawUI(data, force)
  if not force and connectionStatus == lastStatus and serialization.serialize(data) == serialization.serialize(lastDrawnData) then
    return -- Skip if nothing changed
  end
  lastStatus = connectionStatus
  lastDrawnData = data

  term.clear()
  centerText("=== Capacitor Bank Monitor ===", 2, 0x00FF00)

  if data then
    local percent = data.stored / data.max
    centerText(string.format("Stored Energy: %d / %d", data.stored, data.max), 4)
    centerText(string.format("Charge Level : %.1f%%", percent * 100), 5)
    drawProgressBar(6, percent)
    centerText(string.format("Input Rate   : %.2f RF/t", data.input), 8)
    centerText(string.format("Output Rate  : %.2f RF/t", data.output), 9)
  else
    centerText("No data received yet.", 5, 0x888888)
  end

  centerText("Status: " .. connectionStatus, 11, connectionStatus == "Connected" and 0x00FF00 or 0xFFAA00)
  centerText("Press Q to quit.", screenHeight - 2, 0xFF5555)
end

drawUI(nil, true)

local running = true
while running do
  local evt = {event.pull(0.1)}

  if evt[1] == "key_down" then
    local charCode = evt[3]
    if charCode and string.char(charCode):lower() == "q" then
      running = false
      break
    end
  end

  if evt[1] == "modem_message" and evt[6] == "cap_data" then
    local ok, data = pcall(serialization.unserialize, evt[7])
    if ok and data then
      latestData = data
      lastReceiveTime = os.time()
      connectionStatus = "Connected"
      drawUI(latestData, true)
    end
  end

  -- Periodic status check
  if os.clock() - lastStatusCheck > checkInterval then
    lastStatusCheck = os.clock()
    if os.time() - lastReceiveTime > timeout then
      if connectionStatus ~= "Waiting for data..." then
        connectionStatus = "Waiting for data..."
        drawUI(latestData, true)
      end
    else
      drawUI(latestData, false)
    end
  end
end

term.setCursor(1, screenHeight)
gpu.setForeground(0xFFFFFF)
print("Receiver shutting down...")
