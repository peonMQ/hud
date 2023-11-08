local mq = require 'mq'
local logger = require 'knightlinc/Write'

logger.prefix = string.format("\at%s\ax", "[HUD]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

local settingsOpt = require 'settings'
local hudInit = require 'hud'

local settings = settingsOpt.LoadConfig()
logger.loglevel = settings.loglevel

local hud = hudInit(settings, settingsOpt.SaveConfig)

while not hud.ShouldTerminate() do
  hud.Update(logger)
  mq.delay(500)
end
