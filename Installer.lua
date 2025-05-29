local term = require("term")
local event = require("event")
local component = require("component")
local computer = require("computer")
local internet = component.internet
local gpu = component.gpu
local fs = require("filesystem")

gpu.setResolution(50, 15)

-- === Corrected Raw File URLs ===
local urls = {
  sender = "https://raw.githubusercontent.com/CaptJacko7890/Capacitor-Bank-Wireless-monitor/main/sender.lua",
  receiver = "https://raw.githubusercontent.com/CaptJacko7890/Capacitor-Bank-Wireless-monitor/main/receiver.lua",
  uninstaller = "https://raw.githubusercontent.com/CaptJacko7890/Capacitor-Bank-Wireless-monitor/refs/heads/main/uninstaller.lua"
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

-- === Download and Save File ===
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
    os.sleep(0)
  end

  file:close()
  return true
end

-- === Copy File Helper ===
local function copyFile(src, dest)
  local srcFile = io.open(src, "r")
  if not srcFile then return false, "Failed to open source file." end
  local content = srcFile:read("*a")
  srcFile:close()

  local destFile = io.open(dest, "w")
  if not destFile then return false, "Failed to write destination file." end
  destFile:write(content)
  destFile:close()
  return true
end

-- === Install Function ===
local function install(type)
  term.clear()
  term.setCursor(1, 1)
  print("Installing " .. type .. " script...")

  local mainPath = "/home/main.lua"
  local homeAutorunPath = "/home/autorun.lua"
  local rootAutorunPath = "/autorun.lua"
  local uninstallerPath = "/home/uninstaller.lua"

  -- Download script to /home/main.lua
  fs.remove(mainPath)
  local ok, err = download(urls[type], mainPath)
  if not ok then
    print("Download failed: " .. (err or "unknown error"))
    return
  end

  print("Downloaded successfully!")

  -- Remove previous autorun files
  fs.remove(homeAutorunPath)
  fs.remove(rootAutorunPath)

  -- Copy main.lua to autorun locations
  local ok1, err1 = copyFile(mainPath, homeAutorunPath)
  local ok2, err2 = copyFile(mainPath, rootAutorunPath)

  if not ok1 then print("Failed to create /home/autorun.lua: " .. (err1 or "")) end
  if not ok2 then print("Failed to create /autorun.lua: " .. (err2 or "")) end

  -- === Download uninstaller ===
  print("Downloading uninstaller...")
  fs.remove(uninstallerPath)
  local ok3, err3 = download(urls.uninstaller, uninstallerPath)
  if ok3 then
    print("Uninstaller saved to: " .. uninstallerPath)
  else
    print("Failed to download uninstaller: " .. (err3 or "unknown error"))
  end

  print("Install complete!")
  print("Script will autorun on next boot.")

  -- === 5-Second Reboot Countdown ===
  for i = 5, 1, -1 do
    term.setCursor(1,13)
    io.write(string.format("Rebooting in " .. i .. " second(s)..."))
    os.sleep(1)
  end

  computer.shutdown(true)
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
