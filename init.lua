local mq = require 'mq'
local configuration = require 'utils/configloader'
local logger = require 'utils/logging'
local hudInit = require 'hud'

local generalSettings = configuration("general", {scale = 1.0}, "data/HUD")
local groupLayoutMode = configuration("grouplayout", nil, "data/HUD") or {}

local hud = hudInit(generalSettings, groupLayoutMode)

local function mainLoop()
  while not hud.ShouldTerminate() do
    hud.Update(logger)
    mq.delay(500)
  end
end
