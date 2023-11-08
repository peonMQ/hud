local imgui = require 'ImGui'
local mq = require 'mq'
local icons = require 'mq/icons'
local logger = require 'knightlinc/Write'

local valueChanged = false

local function renderGeneralTab(settings, writeSettingsFile)
  settings.ui.locked, valueChanged = imgui.Checkbox("Lock HUD", settings.ui.locked)
  if valueChanged and writeSettingsFile then
    writeSettingsFile(settings)
  end

  settings.ui.layoutType, valueChanged = imgui.RadioButton("Name", settings.ui.layoutType, 1)

  if next(settings.groups) then
    imgui.SameLine()
    settings.ui.layoutType, valueChanged = imgui.RadioButton("Group", settings.ui.layoutType, 2)
    if valueChanged and writeSettingsFile then
      writeSettingsFile(settings)
    end
  end

  settings.ui.opacity, valueChanged = imgui.SliderFloat("Opacity", settings.ui.opacity, 0.0, 1.0)
  if valueChanged and writeSettingsFile then
    writeSettingsFile(settings)
  end
  settings.ui.scale, valueChanged = imgui.SliderFloat("Scale", settings.ui.scale, 0.7, 1.3)
  if valueChanged and writeSettingsFile then
    writeSettingsFile(settings)
  end
end

return renderGeneralTab