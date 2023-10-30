local mq = require 'mq'
local logger = require 'knightlinc/Write'
local settings = require 'settings'
local hudInit = require 'hud'

logger.prefix = string.format("\at%s\ax", "[HUD]")
logger.postfix = function () return string.format(" %s", os.date("%X")) end

local generalSettings = settings.general or {scale = 1.0}
local groupLayoutMode = settings.grouplayout or {}
local hud = hudInit(generalSettings, groupLayoutMode)

while not hud.ShouldTerminate() do
  hud.Update(logger)
  mq.delay(500)
end
