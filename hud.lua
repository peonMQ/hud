--- @type Mq
local mq = require 'mq'
local configuration = require('utils/configloader')
local logger = require 'utils/logging'
local luautil = require 'utils/lua'
--- @type ImGui
require 'ImGui'

local groupLayoutMode = configuration("grouplayout", nil, "data/HUD") or {}
local useGroupLayoutMode = next(groupLayoutMode)

-- https://jsfiddle.net/dkLec6xs/
--[[
rgb(229, 0, 51) red
rgb(143,205,81) green
rgb(0,153,255) blue
rgb(0,255,255) cyan
]]

---@class Color
---@field public R number
---@field public G number
---@field public B number
---@field public A number
local Color = {R = 0, G = 0, B = 0, A = 1}

---@param r number
---@param g number
---@param b number
---@param a? number
---@return Color
function Color:new (r, g, b, a)
  self.__index = self
  local o = setmetatable({}, self)
  o.R = r or 0
  o.G = g or 0
  o.B = b or 0
  o.A = a or 1
  return o
end

---@return number, number, number, number
function Color:Unpack()
  return self.R, self.G, self.B, self.A
end

---@class ColorTransition
---@field public Max Color
---@field public Min Color
local ColorTransition = {Max = Color, Min = Color}

---@param max Color
---@param min Color
---@return ColorTransition
function ColorTransition:new (max, min)
  self.__index = self
  local o = setmetatable({}, self)
  o.Max = max or Color
  o.Min = min or Color
  return o
end

---@param percentage integer
---@return Color
function ColorTransition:ByPercent(percentage)
  if percentage == "NULL"  then
    return self.Max
  end

  local newRed = self.Max.R + ((self.Min.R - self.Max.R) * (100-percentage)/100);
	local newGreen = self.Max.G + ((self.Min.G - self.Max.G) * (100-percentage)/100);
	local newBlue = self.Max.B + ((self.Min.B - self.Max.B) * (100-percentage)/100);
  return Color:new(newRed, newGreen, newBlue);
end

local White = Color:new(1, 1, 1)
local Green = Color:new(0.56, 0.8, 0.32)
local PastelGreen = Color:new(0.4, 1, 0.8)
local Blue = Color:new(0, 0.6, 1)
local Cyan = Color:new(0, 1, 1)
local DarkCyan = Color:new(0.4, 0.6, 0.6)
local Yellow = Color:new(1, 1, 0)
local Orange = Color:new(1, 0.4, 0)
local BloodOrange = Color:new(1, 0.2, 0)
local Red = Color:new(0.9, 0, 0.2)

local hpTransition = ColorTransition:new(Cyan, Red)
local mpTransition = ColorTransition:new(Blue, Red)
local distTransition = ColorTransition:new(DarkCyan, Orange)

---@class HUDItem
---@field public Text string
---@field public Color Color
local HUDItem = {Text="", Color = White}

---@param text string
---@param color? Color
---@return HUDItem
function HUDItem:new (text, color)
  self.__index = self
  local o = setmetatable({}, self)
  o.Text = text or "NA"
  o.Color = color or White
  return o
end


---@class HUDBot
---@field public Name HUDItem
---@field public Level HUDItem
---@field public PctHP HUDItem
---@field public PctMana HUDItem
---@field public XP HUDItem
---@field public Distance HUDItem
---@field public Target HUDItem
---@field public Casting HUDItem
---@field public Pet HUDItem
local HUDBot = {Name=HUDItem, Level=HUDItem, PctHP=HUDItem, PctMana=HUDItem, XP=HUDItem, Distance=HUDItem, Target=HUDItem, Casting=HUDItem, NamPete=HUDItem}

---@param netbot netbot
---@return HUDBot
function HUDBot:new (netbot)
  self.__index = self
  local o = setmetatable({}, self)
  o.Name = HUDItem:new(netbot.Name())
  o.Level = HUDItem:new(""..netbot.Level())
  o.PctHP = HUDItem:new(netbot.PctHPs().."%", hpTransition:ByPercent(netbot.PctHPs()))
  if netbot.MaxMana() ~= "NULL" and netbot.MaxMana() > 0 then
    o.PctMana = HUDItem:new(netbot.PctMana().."%", mpTransition:ByPercent(netbot.PctMana()))
  else
    o.PctMana = HUDItem:new("")
  end

  if netbot.PctExp() ~= "NULL" and netbot.PctExp() < 100 then
    o.XP = HUDItem:new(string.format("%.2f", netbot.PctExp()).."%", PastelGreen)
  else
    o.XP = HUDItem:new("-", PastelGreen)
  end

  local distanceText = "%s"
  local distanceColor = nil
  if netbot.ID() == mq.TLO.Me.ID() then
    distanceText = ""
  elseif netbot.InZone() then
    local spawnDistance = mq.TLO.Spawn(netbot.ID()).Distance3D()
    if spawnDistance then
      local distancePercent = 100 - (math.min(spawnDistance, 500) / 500 * 100)
      distanceColor = distTransition:ByPercent(distancePercent)
      distanceText = string.format(distanceText, string.format("%.2f", spawnDistance))
    end
  else
    distanceColor = Orange
    distanceText = string.format(distanceText, mq.TLO.Zone(netbot.Zone()).ShortName())
  end

  o.Distance = HUDItem:new(distanceText, distanceColor)

  local targetText = ""
  if netbot.TargetID() then
    local spawn = mq.TLO.Spawn(netbot.TargetID())
    if spawn() then
      local targetName = string.format("[%d] %s", spawn.ID(), spawn.CleanName())
      if string.len(targetName) > 20 then
        targetName = string.sub(targetName, 0, 18)..".."
      end
      targetText = targetName
    end
  end
  o.Target = HUDItem:new(targetText, BloodOrange)

  local petText = ""
  if netbot.PetID() ~= "NULL"and netbot.PetID() > 0 then
    petText = netbot.PetHP().."%"
  end
  o.Pet = HUDItem:new(petText, hpTransition:ByPercent(netbot.PetHP()))

  local castingText = ""
  if netbot.Casting() ~= "NULL" then
    castingText = netbot.Casting()
  end
  o.Casting = HUDItem:new(castingText, Yellow)
  return o
end

---@type HUDBot[]
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
  ImGui.PushStyleVar(ImGuiStyleVar.ItemInnerSpacing, 2, 2)
  if hudItem.Text == "" then
    ImGui.Text("")
    return
  end

  ImGui.PushStyleColor(ImGuiCol.Text, hudItem.Color:Unpack())
  ImGui.Text(hudItem.Text)
  ImGui.PopStyleColor(1)
  ImGui.PopStyleVar(1)
end

local function renderHutBot(hudBot)
  ImGui.TableNextColumn()
  renderItem(hudBot.Name)
  ImGui.TableNextColumn()
  renderItem(hudBot.Level)
  ImGui.TableNextColumn()
  renderItem(hudBot.PctHP)
  ImGui.TableNextColumn()
  renderItem(hudBot.PctMana)
  ImGui.TableNextColumn()
  renderItem(hudBot.XP)
  ImGui.TableNextColumn()
  renderItem(hudBot.Distance)
  ImGui.TableNextColumn()
  renderItem(hudBot.Target)
  ImGui.TableNextColumn()
  renderItem(hudBot.Pet)
  ImGui.TableNextColumn()
  renderItem(hudBot.Casting)
end

local function PushStyleCompact()
  local style = ImGui.GetStyle()
  ImGui.PushStyleVar(ImGuiStyleVar.WindowPadding, 0, 0)
end

local function PopStyleCompact()
  ImGui.PopStyleVar(1)
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

local HUDLocked = false
local checkBoxPressed = false

-- ImGui main function for rendering the UI window
local hud = function()
  local renderSpacing = false
  ImGui.SetNextWindowBgAlpha(.3)
  PushStyleCompact()
  if HUDLocked then
    openGUI, shouldDrawGUI = ImGui.Begin('HUD', openGUI, windowFlagsLock)
  else
    openGUI, shouldDrawGUI = ImGui.Begin('HUD', openGUI, windowFlags)
  end
  ImGui.SetWindowSize(430, 277)
  if shouldDrawGUI then
    ImGui.SetWindowFontScale(.9)
    if ImGui.BeginTable('hud_table', 9, tableFlags) then
      ImGui.TableSetupColumn('Name', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Name)
      ImGui.TableSetupColumn('Lvl', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Level)
      ImGui.TableSetupColumn('HP', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_HP)
      ImGui.TableSetupColumn('MP', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_MP)
      ImGui.TableSetupColumn('XP', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_XP)
      ImGui.TableSetupColumn('Dist', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Distance)
      ImGui.TableSetupColumn('Tar', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Target)
      ImGui.TableSetupColumn('Pet', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Pet)
      ImGui.TableSetupColumn('Cast', ImGuiTableColumnFlags.WidthFixed, -1.0, ColumnID_Casting)
    end

    ImGui.TableHeadersRow()

    if useGroupLayoutMode then
      for i=1,#groupLayoutMode do
        for k,v in pairs(groupLayoutMode[i]) do
          local hudBot = hudData[v]
          if hudBot then
            if renderSpacing then
              ImGui.TableNextRow()
              ImGui.TableNextRow()
              ImGui.TableNextRow()
              renderSpacing = false
            end

            renderHutBot(hudBot)
          end
        end

        renderSpacing = true
      end
    else
      for i=1,#hudData do
        local hudBot = hudData[i]
        renderHutBot(hudBot)
      end
    end

    for column=0,9 do
      ImGui.PushID(column)
      if ImGui.TableGetHoveredColumn() > 0 and ImGui.IsMouseReleased(1) then
        ImGui.OpenPopup("TablePopup", ImGuiPopupFlags.NoOpenOverExistingPopup)
      end
      if ImGui.BeginPopup("TablePopup") then
        HUDLocked, checkBoxPressed = ImGui.Checkbox("Lock HUD", HUDLocked)
        if checkBoxPressed then
          ImGui.CloseCurrentPopup()
        end
        ImGui.EndPopup()
      end
      ImGui.PopID()
    end

    ImGui.EndTable()
  end
  ImGui.End()
  PopStyleCompact()
  if not openGUI then
      terminate = true
  end
end

mq.imgui.init('hud', hud)

local function createDefaultSortedData()
  local newData = {}
  for i=1,mq.TLO.NetBots.Counts() do
    local name = mq.TLO.NetBots.Client(i)()
    local netbot = mq.TLO.NetBots(name) --[[@as netbot]]
    local hudBot = HUDBot:new(netbot)
    -- logger.Info("HUD %d %s %s %s", i, name, netbot.Name(), hudBot.Name.Text)
    table.insert(newData, hudBot)
  end

  return newData
end

local function createGroupLayoutData()
  local newData = {}
  for i=1,mq.TLO.NetBots.Counts() do
    local name = mq.TLO.NetBots.Client(i)()
    local netbot = mq.TLO.NetBots(name) --[[@as netbot]]
    local hudBot = HUDBot:new(netbot)
    -- logger.Info("HUD %d %s %s %s", i, name, netbot.Name(), hudBot.Name.Text)
    newData[name] = hudBot
  end

  return newData
end

while not terminate do
  if useGroupLayoutMode then
    hudData = createGroupLayoutData()
  else
    hudData = createDefaultSortedData()
  end

  mq.delay(500)
end