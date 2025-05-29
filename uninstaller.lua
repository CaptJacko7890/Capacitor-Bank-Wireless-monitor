local fs = require("filesystem")
local term = require("term")
local computer = require("computer")

term.clear()
term.setCursor(1, 1)
print("=== Uninstaller ===")
os.sleep(0.5)

-- List of files to delete
local files = {
  "/home/main.lua",
  "/home/autorun.lua",
  "/autorun.lua"
}

-- Delete each file if it exists
for _, path in ipairs(files) do
  if fs.exists(path) then
    local success, err = fs.remove(path)
    if success then
      print("Deleted: " .. path)
    else
      print("Failed to delete " .. path .. ": " .. tostring(err))
    end
  else
    print("Not found: " .. path)
  end
end

-- Delete this uninstaller script using arg[0]
local selfPath = arg and arg[0]
if selfPath and fs.exists(selfPath) then
  print("Uninstaller will delete itself in 3 seconds...")
  os.sleep(3)

  local success, err = fs.remove(selfPath)
  if success then
    print("Uninstaller deleted itself successfully.")
  else
    print("Failed to delete uninstaller: " .. tostring(err))
  end
else
  print("Could not determine uninstaller path. Self-deletion skipped.")
end

-- Optional: Reboot
print("Cleanup complete. Rebooting in 3 seconds...")
os.sleep(3)
computer.shutdown(true)
