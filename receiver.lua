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
  io.write(string.r
