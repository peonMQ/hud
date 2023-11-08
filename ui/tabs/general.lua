local imgui = require 'ImGui'
local mq = require 'mq'
local icons = require 'mq/icons'
local logger = require 'knightlinc/Write'
local renderCombobox = require 'ui/controls/combobox'

---@type string[]
local validLogLevels = {}
for k,v in pairs(logger.loglevels) do
  validLogLevels[v.level] = k
end

local function renderGeneralTab(settings)
  imgui.Text("Lock HUD")
  settings.ui.locked, _ = imgui.Checkbox("##LockHUD", settings.ui.locked)
  imgui.Text("HUD render order")
  settings.ui.layoutType, _ = imgui.RadioButton("Name", settings.ui.layoutType, 1)
  if next(settings.groups) then
    imgui.SameLine()
    settings.ui.layoutType, _ = imgui.RadioButton("Group", settings.ui.layoutType, 2)
  end

  imgui.Text("Opacity")
  settings.ui.opacity, _ = imgui.SliderFloat("##Opacity", settings.ui.opacity, 0.0, 1.0)
  imgui.Text("Scale")
  settings.ui.scale, _ = imgui.SliderFloat("##Scale", settings.ui.scale, 0.7, 1.3)
  settings.loglevel = renderCombobox("Loglevel", settings.loglevel, validLogLevels, function(option) return option:gsub("^%l", string.upper) end, "Sets the console loglevel for HUD")
end

return renderGeneralTab