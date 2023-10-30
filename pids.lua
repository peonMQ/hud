--- @type Mq
local mq = require 'mq'
local utils = require 'mq/Utils'
local logger = require 'knightlinc/Write'

logger.prefix = string.format("\at%s\ax", "[PIDs]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

logger.Info("Starting running script tracking and storing info to NetBots.Note...")
while true do
  local pids = utils.String.Split(mq.TLO.Lua.PIDs(), ",")
  local scriptNames = {};

  for _, scriptPID in pairs(pids) do
    local scriptNamePath = mq.TLO.Lua.Script(tonumber(scriptPID)).Name()
    if scriptNamePath ~= "hud/pids" then
      local scriptNamePathVars = utils.String.Split(scriptNamePath, "/")
      table.insert(scriptNames, scriptNamePathVars[#scriptNamePathVars])
    end
  end

  local pidNames = table.concat(scriptNames,";")
  if pidNames:len() > 200 then
    pidNames = pidNames:sub(1, 198).."++";
  end

  logger.Debug("Current running scripts: %s", pidNames)
  mq.cmdf("/netnote %s", pidNames)
  mq.delay(6000)
end