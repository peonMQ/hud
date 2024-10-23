local mq = require('mq')
local logger = require('knightlinc.Write')
local plugins = require('plugins')

logger.prefix = string.format("\at%s\ax", "[HUD]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

plugins.EnsureIsLoaded("mq2debuffs")

local actor = require('actor')
local settingsOpt = require('settings')
local hudInit = require('hud')

local settings = settingsOpt.LoadConfig()
logger.loglevel = settings.loglevel

local hud = hudInit(settings, settingsOpt.SaveConfig)

-- Am I the foreground instance?
---@return boolean
local function is_orchestrator()
  return mq.TLO.EverQuest.Foreground() -- or mq.TLO.FrameLimiter.Status() == "Foreground"
end

while not hud.ShouldTerminate() do
  actor.Process(settings)
  hud.Update()
  hud.ShouldDrawGui(is_orchestrator())
  mq.delay(settings.update_frequency)
end

