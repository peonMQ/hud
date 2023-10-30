local mq = require 'mq'
local logger = require 'knightlinc/Write'
local config =  {}

---@param filePath string
---@return boolean
local function fileExists(filePath)
  local f = io.open(filePath, "r")
  if f ~= nil then io.close(f) return true else return false end
end

---@param filePath string
---@return table
local function loadConfig (filePath)
  local f = assert(loadfile(filePath))
  return f()
end

local configDir = mq.configDir
local serverName = mq.TLO.MacroQuest.Server()
local configFilePath = string.format("%s/%s/%s", configDir, serverName, "data/HUD.lua")
if fileExists(configFilePath) then
  logger.Info("Loading config from <%s>...", configFilePath)
  config = loadConfig(configFilePath)
end


return config