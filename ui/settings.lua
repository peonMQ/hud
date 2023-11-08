local imgui = require 'ImGui'
local mq = require 'mq'
local logger = require 'knightlinc/Write'
local renderGeneralTab = require 'ui/tabs/general'
local renderGroupTab = require 'ui/tabs/groups'

local _open, _showUI = false, true

local function renderSettingsWindow(settings, writeSettingsFile)
  if imgui.BeginTabBar("HUDSETTINGSTAB##", ImGuiTabBarFlags.None) then
    if imgui.BeginTabItem("General") then
      renderGeneralTab(settings)
      imgui.EndTabItem()
    end
    if imgui.BeginTabItem("Groups") then
      renderGroupTab(settings)
      imgui.EndTabItem()
    end
    imgui.EndTabBar()
  end
  if imgui.Button("Apply") then
    writeSettingsFile(settings)
  end
end

local function init(settings, writeSettingsFile)
  local function settingsWindow()
      if _open then
          _open, _showUI = imgui.Begin('Hud Settings', _open)
          imgui.SetWindowSize(500, 200, ImGuiCond.FirstUseEver)
          if _showUI then
              renderSettingsWindow(settings, writeSettingsFile)
          end
          imgui.End()
      end
  end

  mq.imgui.init('settingswindow', settingsWindow)
end
 
return {
  Init = init,
  OpenSettings = function() _open = true end
}