local mq = require 'mq'
local utils = require 'mq.Utils'
local actors = require 'actors'
local logger = require 'knightlinc.Write'

local mailbox = 'hudinfo'

---@class HUDInfo
---@field Id number
---@field Name string
---@field PctHPs number
---@field PctMana number
---@field MaxMana number
---@field TargetId? number
---@field Level number
---@field PctExp number
---@field PetPctHPs? number
---@field Casting? string
---@field ZoneShortName string
---@field InstanceId number
---@field HasCounters? boolean
---@field IsInRaid boolean
---@field IsGrouped boolean
---@field RunningScripts string
---@field LastUpdated number

---@type table<string, HUDInfo>
local hudActors = {}

---@class HUDMessage: Message
---@field content HUDInfo
---@field reply fun()
---@field send fun(message: HUDInfo)

local function getRunningScripts()
  local pids = utils.String.Split(mq.TLO.Lua.PIDs(), ",")
  local scriptNames = {};

  for _, scriptPID in pairs(pids) do
    local pid = tonumber(scriptPID)
    if pid then
      local scriptNamePath = mq.TLO.Lua.Script(pid).Name()
      if scriptNamePath ~= "hud/pids" then
        local scriptNamePathVars = utils.String.Split(scriptNamePath, "/")
        table.insert(scriptNames, scriptNamePathVars[#scriptNamePathVars])
      end
    end
  end

  local pidNames = table.concat(scriptNames,";")
  if pidNames:len() > 200 then
    pidNames = pidNames:sub(1, 198).."++";
  end

  return pidNames
end

---@param message HUDMessage
local function handleMessage(message)
  if message.sender.character then
    local hudinfo = message.content
    hudActors[message.sender.character] = hudinfo
  end
end

-- this is then message handler, so handle all messages we expect
-- we are guaranteed that the only messages here we receive are
-- ones that we send, so assume the structure of the message
local actor = actors.register(mailbox, handleMessage)

local function broadcastHudInfo()
  local me = mq.TLO.Me;
  local hudinfo = {
    Id = me.ID(),
    Name = me.Name(),
    PctHPs = me.PctHPs(),
    PctMana = me.PctMana(),
    MaxMana = me.MaxMana() or 0,
    TargetId = mq.TLO.Target.ID(),
    Level = me.Level(),
    PctExp = me.PctExp(),
    PetPctHPs = me.Pet.PctHPs(),
    Casting = me.Casting(),
    ZoneShortName = mq.TLO.Zone.ShortName(),
    InstanceId = me.Instance(),
    HasCounters = mq.TLO.Debuff.Counters() > 0,
    IsInRaid = mq.TLO.Raid.Members() and mq.TLO.Raid.Members() > 0,
    IsGrouped = me.Grouped(),
    RunningScripts = getRunningScripts(),
    LastUpdated = mq.gettime()
  }

  actor:send(hudinfo)
end

---@param settings HUDSettings
local function cleanup(settings)
  for name, data in pairs(hudActors) do
      if mq.gettime() - (data.LastUpdated or 0) > settings.stale_data_timer*60000 then
        logger.Debug("Stale data for %s, last updated %s (ms) ago", name, mq.gettime() - (data.LastUpdated or 0))
        hudActors[name] = nil
      end
  end
end

---@param settings HUDSettings
local function process(settings)
  cleanup(settings)

  local inGame = mq.TLO.EverQuest.GameState()
  if inGame == 'INGAME' then broadcastHudInfo() end
end

return {
  Process = process,
  Data = hudActors
}

