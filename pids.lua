--- @type Mq
local mq = require('mq')
local logger = require('utils/logging')
local debugutils = require('utils/debug')
local luaUtils = require('utils/lua-table')

while true do
  local pids = luaUtils.Split(mq.TLO.Lua.PIDs(), ",")
  local scriptNames = {};



  for _, scriptPID in pairs(pids) do
    local scriptNamePath = mq.TLO.Lua.Script(tonumber(scriptPID)).Name()
    if scriptNamePath ~= "hud/pids" then
      local scriptNamePathVars = luaUtils.Split(scriptNamePath, "/")
      table.insert(scriptNames, scriptNamePathVars[#scriptNamePathVars])
    end
  end

  local pidNames = table.concat(scriptNames,";")
  mq.cmdf("/netnote %s", pidNames)
  mq.delay(6000)
end