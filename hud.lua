local mq = require 'mq'
local imgui = require 'ImGui'
local configuration = require 'utils/configloader'
local logger = require 'utils/logging'
local hudBot = require 'hudbot'

local generalSettings = configuration("general", {scale = 1.0}, "data/HUD")
local groupLayoutMode = configuration("grouplayout", nil, "data/HUD") or {}
local useGroupLayoutMode = next(groupLayoutMode)

---@type table<string, HUDBot>
local hudData = {}

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false
local windowFlags = bit32.bor(ImGuiWindowFlags.NoDecoration, ImGuiWindowFlags.NoDocking, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.NoFocusOnAppearing, ImGuiWindowFlags.NoNav)
local windowFlagsLock = bit32.bor(windowFlags, ImGuiWindowFlags.NoMove)
local tableFlags = bit32.bor(ImGuiTableFlags.PadOuterX, ImGuiTableFlags.Hideable)

---@param hudItem HUDItem
local function renderItem(hudItem)
  imgui.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, 2, 2)
  if hudItem.Text == "" then
    imgui.Text("")
    return
  end

  imgui.PushStyleColor(ImGuiCol.Text, hudItem.Color)
  imgui.Text(hudItem.Text)
  imgui.PopStyleColor(1)
  imgui.PopStyleVar(1)
end

---@param hudBot HUDBot
local function renderHutBot(hudBot)
  imgui.TableNextColumn()
  renderItem(hudBot.Name)
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

local HUDLocked = false
local checkBoxPressed = false

-- ImGui main function for rendering the UI window
local hud = function()
  local renderSpacing = false
  imgui.SetNextWindowBgAlpha(.3)
  PushStyleCompact()
  if HUDLocked then
    openGUI, shouldDrawGUI = imgui.Begin('HUD', openGUI, windowFlagsLock)
  else
    openGUI, shouldDrawGUI = imgui.Begin('HUD', openGUI, windowFlags)
  end
  PopStyleCompact()
  imgui.SetWindowSize(430, 277)
  if shouldDrawGUI then
    imgui.SetWindowFontScale(generalSettings.scale)
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
    end

    imgui.TableHeadersRow()

    if useGroupLayoutMode then
      for i=1,#groupLayoutMode do
        for k,v in pairs(groupLayoutMode[i]) do
          local chrHudBot = hudData[v]
          if chrHudBot then
            if renderSpacing then
              imgui.TableNextRow()
              imgui.TableNextRow()
              imgui.TableNextRow()
              renderSpacing = false
            end

            renderHutBot(chrHudBot)
          end
        end

        renderSpacing = true
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
        HUDLocked, checkBoxPressed = imgui.Checkbox("Lock HUD", HUDLocked)
        if checkBoxPressed then
          imgui.CloseCurrentPopup()
        end
        imgui.EndPopup()
      end
      imgui.PopID()
    end

    imgui.EndTable()
  end
  imgui.End()
  if not openGUI then
      terminate = true
  end
end

mq.imgui.init('hud', hud)

local function udpateHudData()
  for name, _ in pairs(hudData) do
    if mq.TLO.NetBots(name).ID() == "NULL" then
      logger.Warn("NetBot %s not found, removing from HUD...", name)
      hudData[name] = nil
    end
  end

  for i=1,mq.TLO.NetBots.Counts() do
    local name = mq.TLO.NetBots.Client(i)()
    if name ~= "NULL" then
      local netbot = mq.TLO.NetBots(name) --[[@as netbot]]
      if not hudData[name] then
        hudData[name] = hudBot:New(netbot)
      else
        hudData[name]:Update(netbot)
      end
    else
      logger.Warn("NetBot <%s> is NULL, skipping...", i)
    end
  end
end

local function mainLoop()
  while not terminate do
    udpateHudData()
    mq.delay(500)
  end
end

---@return boolean
local function shouldTerminate()
    return terminate
end

return {
    MainLoop = mainLoop,
    ShouldTerminate = shouldTerminate,
    Update = udpateHudData,
}
