--- @type Mq
local mq = require 'mq'
local configuration = require('utils/configloader')
local logger = require 'utils/logging'
local luautil = require 'utils/lua'
--- @type ImGui
require 'ImGui'

local groupLayoutMode = configuration.LoadConfig("grouplayout", nil, "data/HUD") or {}
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
---@field public Size integer
---@field public Color Color
local HUDItem = {Text="", Size = 0, Color = White}

---@param text string
---@param size integer
---@param color? Color
---@return HUDItem
function HUDItem:new (text, size, color)
  self.__index = self
  local o = setmetatable({}, self)
  o.Text = text or "NA"
  o.Size = size or 0
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
  o.Name = HUDItem:new(netbot.Name(), 90)
  o.Level = HUDItem:new(""..netbot.Level(), 20)
  o.PctHP = HUDItem:new("HP:"..netbot.PctHPs().."%", 60, hpTransition:ByPercent(netbot.PctHPs()))
  if netbot.MaxMana() ~= "NULL" and netbot.MaxMana() > 0 then
    o.PctMana = HUDItem:new("MP:"..netbot.PctMana().."%", 60, mpTransition:ByPercent(netbot.PctMana()))
  else 
    o.PctMana = HUDItem:new("", 60)
  end

  if netbot.PctExp() ~= "NULL" and netbot.PctExp() < 100 then
    o.XP = HUDItem:new("XP:"..string.format("%.2f", netbot.PctExp()).."%", 62, PastelGreen)
  else
    o.XP = HUDItem:new("XP: -", 62, PastelGreen)
  end

  local distanceText = "D:%s"
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
  o.Distance = HUDItem:new(distanceText, 60, distanceColor)

  local targetText = ""
  if netbot.TargetID() then
    local spawn = mq.TLO.Spawn(netbot.TargetID())
    if spawn() then
      local targetName = string.format("[%d] %s", spawn.ID(), spawn.CleanName())
      if string.len(targetName) > 20 then
        targetName = string.sub(targetName, 0, 18)..".."
      end
      targetText = "T:"..targetName
    end
  end
  o.Target = HUDItem:new(targetText, 140, BloodOrange)
  
  local petText = ""
  if netbot.PetID() ~= "NULL"and netbot.PetID() > 0 then
    petText = "P:"..netbot.PetHP().."%"
  end
  o.Pet = HUDItem:new(petText, 60, hpTransition:ByPercent(netbot.PetHP()))
  
  local castingText = ""
  if netbot.Casting() ~= "NULL" then
    castingText = netbot.Casting()
  end
  o.Casting = HUDItem:new(castingText, 120, Yellow)
  return o
end

---@type HUDBot[]
local hudData = {}

-- GUI Control variables
local openGUI = true
local shouldDrawGUI = true
local terminate = false
local windowFlags = bit32.bor(ImGuiWindowFlags.NoDecoration, ImGuiWindowFlags.NoDocking, ImGuiWindowFlags.AlwaysAutoResize, ImGuiWindowFlags.NoSavedSettings, ImGuiWindowFlags.NoFocusOnAppearing, ImGuiWindowFlags.NoNav)

local function PushStyleCompact()
  local style = ImGui.GetStyle()
  ImGui.PushStyleVar(ImGuiStyleVar.FramePadding, ImVec2.new(style.FramePadding.x, style.FramePadding.y * 0.70))
  ImGui.PushStyleVar(ImGuiStyleVar.ItemSpacing, ImVec2.new(style.ItemSpacing.x, style.ItemSpacing.y * 0.70))
end

local function PopStyleCompact()
    ImGui.PopStyleVar(2)
end

---@param hudItem HUDItem
---@param xStart? integer
local function renderItem(hudItem, xStart)
  if hudItem.Text == "" then
    return xStart + hudItem.Size
  end

  local x = xStart or 0
  if x ~= 0 then
    ImGui.SameLine(x)
  end
  ImGui.PushStyleColor(ImGuiCol.Text, hudItem.Color:Unpack())
  ImGui.Text(hudItem.Text)
  ImGui.PopStyleColor(1)
  return x + hudItem.Size
end

local function renderHutBut(hudBot)
  local xStart = renderItem(hudBot.Name)
  xStart = renderItem(hudBot.Level, xStart)
  xStart = renderItem(hudBot.PctHP, xStart)
  xStart = renderItem(hudBot.PctMana, xStart)
  xStart = renderItem(hudBot.XP, xStart)
  xStart = renderItem(hudBot.Distance, xStart)
  xStart = renderItem(hudBot.Target, xStart)
  xStart = renderItem(hudBot.Pet, xStart)
  xStart = renderItem(hudBot.Casting, xStart)
end

-- ImGui main function for rendering the UI window
local hud = function()
  local renderSpacing = false
  ImGui.SetNextWindowBgAlpha(.3)
  openGUI, shouldDrawGUI = ImGui.Begin('HUD', openGUI, windowFlags)
  if shouldDrawGUI then
    PushStyleCompact()
    ImGui.SetWindowFontScale(.9)
    if useGroupLayoutMode then
      for i=1,#groupLayoutMode do
        for k,v in pairs(groupLayoutMode[i]) do
          local hudBot = hudData[v]
          if hudBot then
            if renderSpacing then
              ImGui.Spacing()
              ImGui.Spacing()
              renderSpacing = false
            end
            
            renderHutBut(hudBot)
          end
        end
        
        renderSpacing = true
      end
    else
      for i=1,#hudData do
        local hudBot = hudData[i]
        renderHutBut(hudBot)
      end
    end
        
    PopStyleCompact()
  end
  ImGui.End()
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