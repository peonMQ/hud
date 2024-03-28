local mq = require 'mq'

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

---@return ImVec4
function Color:Unpack()
  return ImVec4(self.R, self.G, self.B, self.A)
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
---@return ImVec4
function ColorTransition:ByPercent(percentage)
  local percent = tonumber(percentage)
  if not percent then
    return self.Max:Unpack()
  end

  percent = math.min(100, math.max(percentage, 0))
  local newRed = self.Max.R + ((self.Min.R - self.Max.R) * (100-percent)/100);
	local newGreen = self.Max.G + ((self.Min.G - self.Max.G) * (100-percent)/100);
	local newBlue = self.Max.B + ((self.Min.B - self.Max.B) * (100-percent)/100);
  return ImVec4(newRed, newGreen, newBlue, 1);
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
---@field public Color ImVec4
local HUDItem = {Text="", Color = White:Unpack()}

---@param text string
---@param color? ImVec4
---@return HUDItem
local function newHUDItem (text, color)
  return { Text = text or "NA", Color = color or White:Unpack() };
end

---@param data HUDInfo
local function name(data)
  if data.HasCounters then
    return newHUDItem(data.Name, Red:Unpack())
  end

  if data.IsInRaid then
    return newHUDItem(data.Name, Cyan:Unpack())
  end

  if data.IsGrouped then
    return newHUDItem(data.Name, Green:Unpack())
  end

  return newHUDItem(data.Name);
end

---@param data HUDInfo
local function level(data)
  return newHUDItem(""..data.Level)
end

---@param data HUDInfo
local function pctHP(data)
  return newHUDItem(data.PctHPs.."%", hpTransition:ByPercent(data.PctHPs))
end

---@param data HUDInfo
local function pctMana(data)
  if data.MaxMana > 0 then
    return newHUDItem(data.PctMana.."%", mpTransition:ByPercent(data.PctMana))
  end

  return newHUDItem("")
end

---@param data HUDInfo
local function pctExp(data)
  if data.PctExp < 100 then
    return newHUDItem(string.format("%.2f", data.PctExp).."%", PastelGreen:Unpack())
  end

  return newHUDItem("-", PastelGreen:Unpack())
end

---@param data HUDInfo
local function distance(data)
  local distanceText = "%s"
  local distanceColor = nil
  if data.Id == mq.TLO.Me.ID() then
    distanceText = ""
  elseif data.ZoneShortName == mq.TLO.Zone.ShortName() then
    local spawnDistance = mq.TLO.Spawn(data.Id).Distance3D()
    if spawnDistance then
      local distancePercent = 100 - (math.min(spawnDistance, 500) / 500 * 100)
      distanceColor = distTransition:ByPercent(distancePercent)
      distanceText = string.format(distanceText, string.format("%.2f", spawnDistance))
    end
  else
    distanceColor = Orange:Unpack()
    local instanceId = data.InstanceId
    if instanceId > 0 then
      local text = string.format("%s[%d]", data.ZoneShortName, instanceId)
      distanceText = string.format(distanceText, text)
    else
      distanceText = string.format(distanceText, data.ZoneShortName)
    end
  end

  return newHUDItem(distanceText, distanceColor)
end

---@param data HUDInfo
local function target(data)
  local targetText = ""
  local targetColor = White
  if data.TargetId then
    local spawn = mq.TLO.Spawn(data.TargetId)
    if spawn() then
      local targetName = string.format("[%d] %s", spawn.ID(), spawn.CleanName())
      if string.len(targetName) > 20 then
        targetName = string.sub(targetName, 0, 18)..".."
      end
      targetText = targetName

      if spawn.Type() == "NPC" then
        targetColor = Green
      end
    end
  end

  return newHUDItem(targetText, targetColor:Unpack())
end

---@param data HUDInfo
local function pet(data)
  local petText = ""
  if data.PetPctHPs then
    petText = data.PetPctHPs.."%"
  end
  return newHUDItem(petText, hpTransition:ByPercent(data.PetPctHPs))
end

---@param data HUDInfo
local function casting(data)
  local castingText = ""
  if data.Casting then
    castingText = data.Casting
  end

  return newHUDItem(castingText, Yellow:Unpack())
end

---@param data HUDInfo
local function pids(data)
  local pidsText = "NA"
  if data.RunningScripts or data.RunningScripts:len() == 0 then
    pidsText = data.RunningScripts
  end
  return newHUDItem(pidsText, White:Unpack())
end


---@class HUDBot
---@field public Name HUDItem
---@field public Level HUDItem
---@field public PctHP HUDItem
---@field public PctMana HUDItem
---@field public PctExp HUDItem
---@field public Distance HUDItem
---@field public Target HUDItem
---@field public Casting HUDItem
---@field public Pet HUDItem
local HUDBot = {Name=HUDItem, Level=HUDItem, PctHP=HUDItem, PctMana=HUDItem, PctExp=HUDItem, Distance=HUDItem, Target=HUDItem, Casting=HUDItem, Pet=HUDItem, PIDs=HUDItem}

---@param data HUDInfo
---@return HUDBot
function HUDBot:New (data)
  self.__index = self
  local o = setmetatable({}, self)
  o.Name = name(data)
  o.Level = level(data)
  o.PctHP = pctHP(data)
  o.PctMana = pctMana(data)
  o.PctExp = pctExp(data)
  o.Distance = distance(data)
  o.Target = target(data)
  o.Pet = pet(data)
  o.Casting = casting(data)
  o.PIDs = pids(data)
  return o
end

---@param data HUDInfo
function HUDBot:Update (data)
  self.Name = name(data)
  self.Level = level(data)
  self.PctHP = pctHP(data)
  self.PctMana = pctMana(data)
  self.PctExp = pctExp(data)
  self.Distance = distance(data)
  self.Target = target(data)
  self.Pet = pet(data)
  self.Casting = casting(data)
  self.PIDs = pids(data)
end

return HUDBot