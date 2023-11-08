local mq = require 'mq'
local logger = require 'knightlinc/Write'

logger.prefix = string.format("\at%s\ax", "[HUD]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

local settings = require 'settings'
local hudInit = require 'hud'

local hud = hudInit(settings.LoadConfig(), settings.SaveConfig)

while not hud.ShouldTerminate() do
  hud.Update(logger)
  mq.delay(500)
end
