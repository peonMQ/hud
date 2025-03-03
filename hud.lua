local mq = require('mq')
local imgui = require('ImGui')
local logger = require('knightlinc.Write')
local hudBot = require('hudbot')
local actor = require('actor')
local settingsUI = require('ui.settings')

local function init(settings, writeSettingsFile)
  settingsUI.Init(settings, writeSettingsFile)
  ---@type table<string, HUDBot>
  local hudData = {}

  -- GUI Control variables
  local openGUI = true
  local shouldDrawGUI = true
  local terminate = false
  local windowFlags = bit32.bor(ImGuiWindowFlags.NoResize, ImGuiWindowFlags.NoScrollbar, ImGuiWindowFlags.NoDocking, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoFocusOnAppearing, ImGuiWindowFlags.NoNav)
  local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable)

  ---@param hudItem HUDItem
  local function renderItem(hudItem)
    imgui.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, 2, 2)
    if hudItem.Text == "" then
      imgui.Text("")
    else
      imgui.PushStyleColor(ImGuiCol.Text, hudItem.Color)
      imgui.Text(hudItem.Text)
      imgui.PopStyleColor(1)
    end

    imgui.PopStyleVar(1)
  end

  ---@param hudBot HUDBot
  local function renderHutBot(hudBot)
    imgui.TableNextColumn()
    renderItem(hudBot.Name)
    if imgui.IsItemClicked(ImGuiMouseButton.Left) then
      mq.cmdf("/mqtarget %s", hudBot.Name.Text)
    end
    imgui.TableNextColumn()
    renderItem(hudBot.Level)
    imgui.TableNextColumn()
    renderItem(hudBot.PctHP)
    imgui.TableNextColumn()
    renderItem(hudBot.PctMana)
    imgui.TableNextColumn()
    renderItem(hudBot.PctExp)
    imgui.TableNextColumn()
    renderItem(hudBot.Distance)
    imgui.TableNextColumn()
    renderItem(hudBot.Target)
    imgui.TableNextColumn()
    renderItem(hudBot.Pet)
    imgui.TableNextColumn()
    renderItem(hudBot.Casting)
    imgui.TableNextColumn()
    renderItem(hudBot.PIDs)
  end

  local function PushStyleCompact()
    local style = imgui.GetStyle()
    imgui.PushStyleVar(ImGuiStyleVar.WindowPadding, 0, 0)
  end

  local function PopStyleCompact()
    imgui.PopStyleVar(1)
  end

  local ColumnID_Name = 0
  local ColumnID_Level = 1
  local ColumnID_HP = 2
  local ColumnID_MP = 3
  local ColumnID_XP = 4
  local ColumnID_Distance = 5
  local ColumnID_Target = 6
  local ColumnID_Pet = 7
  local ColumnID_Casting = 8
  local ColumnID_PIDs = 9

  local eq_path = mq.TLO.EverQuest.Path()
  eq_path = eq_path:gsub('.*%\\', '') -- https://stackoverflow.com/questions/74408159/lua-help-to-get-an-end-of-string-after-last-special-character

  -- ImGui main function for rendering the UI window
  local hud = function()
    if not openGUI then return end
    local flags = windowFlags
    if settings.ui.locked then
      flags = bit32.bor(flags, ImGuiWindowFlags.NoMove)
    end
    if not settings.ui.showNavBar then
      flags = bit32.bor(flags, ImGuiWindowFlags.NoTitleBar, ImGuiWindowFlags.NoCollapse)
    end

    imgui.SetNextWindowBgAlpha(settings.ui.opacity)
    PushStyleCompact()
    openGUI, shouldDrawGUI = imgui.Begin(('HUD###hud_%s'):format(eq_path), openGUI, flags) -- https://discord.com/channels/511690098136580097/866047684242309140/1268289663546949773
    PopStyleCompact()
    if shouldDrawGUI then
      imgui.SetWindowSize(430, 277)
      imgui.SetWindowFontScale(settings.ui.scale)
      if imgui.BeginTable('hud_table', 10, tableFlags) then
        imgui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Name)
        imgui.TableSetupColumn('Lvl', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Level)
        imgui.TableSetupColumn('HP', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_HP)
        imgui.TableSetupColumn('MP', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_MP)
        imgui.TableSetupColumn('XP', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_XP)
        imgui.TableSetupColumn('Dist', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Distance)
        imgui.TableSetupColumn('Tar', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Target)
        imgui.TableSetupColumn('Pet', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Pet)
        imgui.TableSetupColumn('Cast', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Casting)
        imgui.TableSetupColumn('PIDs', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_PIDs)

        imgui.TableHeadersRow()

        if settings.ui.layoutType == 2 then
          for i, groupNames in ipairs(settings.groups) do
            local renderGroupSpacing = i > 1 and i <= #settings.groups
            for k,name in ipairs(groupNames) do
              local hudBotData = hudData[name]
              if hudBotData then
                if renderGroupSpacing then
                  imgui.TableNextRow()
                  imgui.TableNextRow()
                  imgui.TableNextRow()
                end

                renderHutBot(hudBotData)
                renderGroupSpacing = false
              end
            end
          end
        else
          for _, netbot in pairs(hudData) do
            renderHutBot(netbot)
          end
        end

        for column=0,9 do
          imgui.PushID(column)
          if imgui.TableGetHoveredColumn() > 0 and imgui.IsMouseReleased(1) then
            imgui.OpenPopup("TablePopup", ImGuiPopupFlags.NoOpenOverExistingPopup)
          end
          if imgui.BeginPopup("TablePopup") then
            imgui.Text("Settings")
            if imgui.IsItemClicked(ImGuiMouseButton.Left) then
              settingsUI.OpenSettings()
              imgui.CloseCurrentPopup()
            end
            imgui.EndPopup()
          end
          imgui.PopID()
        end

        imgui.EndTable()
      end
    elseif not settings.ui.showNavBar then
      settings.ui.showNavBar = true
    end

    imgui.End()
    if not openGUI then
        terminate = true
    end
  end

  mq.imgui.init('hud', hud)

  local function updateHudData()
    for name, _ in pairs(hudData) do
      if not actor.Data[name] then
        logger.Debug("<HudBot data for %s not found, removing from HUD...", name)
        hudData[name] = nil
      end
    end

    for name, data in pairs(actor.Data) do
      if not hudData[name] then
        hudData[name] = hudBot:New(data)
      else
        hudData[name]:Update(data)
      end
    end
  end

  ---@return boolean
  local function shouldTerminate()
      return terminate
  end

  ---@param doDraw boolean
  local function shouldDrawGui(doDraw)
    openGUI = doDraw
  end

  return {
    ShouldDrawGui = shouldDrawGui,
    ShouldTerminate = shouldTerminate,
    Update = updateHudData,
  }

end

mq.bind("/hudsettings", settingsUI.OpenSettings)

return init