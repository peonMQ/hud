local imgui = require('ImGui')
local icons = require('mq/icons')


local leftPanelWidth = 200
local selectedGroup = 0
local function LeftPaneWindow(groups)
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("left", leftPanelWidth, y-21) then
    for k,v in ipairs(groups) do
      if imgui.Button(icons.FA_TRASH.."##delgroup"..k) then
        groups[k] = nil
      end
      imgui.SameLine()
      imgui.BeginDisabled(k == 1)
      if imgui.Button(icons.FA_CARET_UP.."##upgroup"..k) then
        table.remove(groups, k)
        table.insert(groups, k-1, v)
      end
      imgui.EndDisabled()
      imgui.SameLine()
      imgui.BeginDisabled(k == #groups)
      if imgui.Button(icons.FA_CARET_DOWN.."##downgroup"..k) then
        table.remove(groups, k)
        table.insert(groups, k+1, v)
      end
      imgui.EndDisabled()
      imgui.SameLine()
      local selected = imgui.Selectable('Group '..k, selectedGroup == k)
      if selected then
        selectedGroup = k
      end
    end
  end
  imgui.EndChild()
end

local function RightPaneWindow(group)
  local x,y = imgui.GetContentRegionAvail()
  if imgui.BeginChild("right", x, y-21) then
    if group then
      for i, value in ipairs(group) do
        imgui.Text(i..":")
        imgui.SameLine()
        local newValue, _ = imgui.InputText("##"..i, value)
        group[i] = newValue
        imgui.SameLine()
        imgui.BeginDisabled(i == 1)
        if imgui.Button(icons.FA_CARET_UP.."##upmember"..i) then
          table.remove(group, i)
          table.insert(group, i-1, value)
        end
        imgui.EndDisabled()
        imgui.SameLine()
        imgui.BeginDisabled(i == #group)
        if imgui.Button(icons.FA_CARET_DOWN.."##downmember"..i) then
          table.remove(group, i)
          table.insert(group, i+1, value)
        end
        imgui.EndDisabled()
        imgui.SameLine()
        if imgui.Button(icons.FA_TRASH.."##delmember"..i) then
          group[i] = nil
        end
      end

      if imgui.Button("Add member") then
        table.insert(group, "")
      end
    end
  end
  imgui.EndChild()
end

local function renderGroupTab(settings)
  if imgui.Button("Add group") then
    table.insert(settings.groups, {})
  end
  LeftPaneWindow(settings.groups)
  imgui.SameLine()
  RightPaneWindow(settings.groups[selectedGroup])
end

return renderGroupTab