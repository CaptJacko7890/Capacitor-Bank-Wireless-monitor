local term = require("term")
local event = require("event")
local component = require("component")
local internet = component.internet
local gpu = component.gpu
local fs = require("filesystem")

gpu.setResolution(50, 15)
-- === Corrected Raw File URLs ===
local urls = {
  sender = "https://raw.githubusercontent.com/CaptJacko7890/Capacitor-Bank-Wireless-monitor/main/sender.lua",
  receiver = "https://raw.githubusercontent.com/CaptJacko7890/Capacitor-Bank-Wireless-monitor/main/receiver.lua"
}

-- === Basic UI ===
local function drawMenu(selected)
  term.clear()
  term.setCursor(1, 1)
  print("=== OpenComputers Installer ===")
  print("")
  print((selected == "sender"   and "> " or "  ") .. "[1] Install Sender")
  print((selected == "receiver" and "> " or "  ") .. "[2] Install Receiver")
  print("")
  print("Use UP/DOWN arrows and ENTER to select.")
end

-- === Download and Install ===
local function download(url, path)
  print("Downloading from: " .. url)
  local handle, reason = internet.request(url)
  if not handle then return false, "Failed to open URL: " .. tostring(reason) end

  local file, err = io.open(path, "w")
  if not file then return false, "Failed to open file: " .. tostring(err) end

  while true do
    local chunk, reason = handle.read()
    if chunk then
      file:write(chunk)
    elseif reason then
      file:close()
      return false, "Download error: " .. tostring(reason)
    else
      break
    end
    os.sleep(0) -- yield for coroutine-based network IO
  end

  file:close()
  return true
end

local function install(type)
  term.clear()
  term.setCursor(1, 1)
  print("Installing " .. type .. " script...")

  fs.remove("/home/main.lua")
  local ok, err = download(urls[type], "/home/main.lua")
  if not ok then
    print("Download failed: " .. (err or "unknown error"))
    return
  end

  print("Downloaded successfully!")

  -- Remove previous autorun scripts if they exist
  fs.remove("/home/autorun.lua")
  fs.remove("/autorun.lua")

  -- Create symlink in home (optional, mostly cosmetic)
  os.execute("ln -s /home/main.lua /home/autorun.lua")

  -- Create symlink in root for boot autorun
  os.execute("ln -s /home/main.lua /autorun.lua")

  print("Install complete! Script will autorun at next boot.")
end


-- === Main loop ===
local options = {"sender", "receiver"}
local index = 1
drawMenu(options[index])

while true do
  local _, _, _, key = event.pull("key_down")
  if key == 200 then -- up arrow
    index = index == 1 and #options or index - 1
    drawMenu(options[index])
  elseif key == 208 then -- down arrow
    index = index == #options and 1 or index + 1
    drawMenu(options[index])
  elseif key == 28 then -- enter
    install(options[index])
    break
  end
end
