local mq = require 'mq'
local logger = require 'knightlinc/Write'

local function isArray(t)
  local i = 0
  for _ in pairs(t) do
    i = i + 1
    if t[i] == nil then return false end
  end
  return true
end

local function iterator(table)
  if isArray(table) then
    return ipairs(table)
  end

  return pairs(table)
end

---@param node table
local function toString(node)
  local cache, stack, output = {},{},{}
  local depth = 1
  local output_str = "return {\n"

  while true do
    local size = 0
    for k,v in iterator(node) do
      size = size + 1
    end

    local cur_index = 1
    for k,v in iterator(node) do
      if (cache[node] == nil) or (cur_index >= cache[node]) then
        if (string.find(output_str,"}",output_str:len())) then
          output_str = output_str .. ",\n"
        elseif not (string.find(output_str,"\n",output_str:len())) then
          output_str = output_str .. "\n"
        end

        -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
        table.insert(output,output_str)
        output_str = ""

        local key
        if (type(k) == "number" or type(k) == "boolean") then
          key = "["..tostring(k).."]"
        else
          key = "['"..tostring(k).."']"
        end

        if (type(v) == "number" or type(v) == "boolean") then
          output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
        elseif (type(v) == "table") then
          output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
          table.insert(stack,node)
          table.insert(stack,v)
          cache[node] = cur_index+1
          break
        else
          output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
        end

        if (cur_index == size) then
          output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        else
          output_str = output_str .. ","
        end
      else
        -- close the table
        if (cur_index == size) then
          output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end
      end

      cur_index = cur_index + 1
    end

    if (size == 0) then
      output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
    end

    if (#stack > 0) then
      node = stack[#stack]
      stack[#stack] = nil
      depth = cache[node] == nil and depth + 1 or depth - 1
    else
      break
    end
  end

  -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
  table.insert(output,output_str)
  output_str = table.concat(output)

  return output_str
end

---@generic T : table
---@param default T
---@param loaded T
---@return T
local function leftJoin(default, loaded)
  local config = {}
  for key, value in pairs(default) do
    config[key] = value
    local loadedValue = loaded[key]
    if type(value) == "table" then
      if type(loadedValue or false) == "table" then
        if next(value) then
          config[key] = leftJoin(default[key] or {}, loadedValue or {})
        else
          config[key] = loadedValue
        end
      end
    elseif type(value) == type(loadedValue) then
      config[key] = loadedValue
    end
  end

  return config
end

---@alias LayoutTypes 1|2|3

---@class HUDSettings
---@field groups table
---@field layoutType LayoutTypes
---@field scale number
---@field opacity number
local settings = {
  groups = {},
  ui = {
    locked = true,
    layoutType = 1,
    scale = 1.0,
    opacity = 0.3
  }
}

---@param filePath string
---@return boolean
local function fileExists(filePath)
  local f = io.open(filePath, "r")
  if f ~= nil then io.close(f) return true else return false end
end

---@param filePath string
---@return table
local function loadConfig (filePath)
  local f = assert(loadfile(filePath))
  return f()
end

local configDir = mq.configDir
local serverName = mq.TLO.MacroQuest.Server()
local configFilePath = string.format("%s/%s/%s", configDir, serverName, "data/HUD.lua")
if fileExists(configFilePath) then
  logger.Info("Loading config from <%s>...", configFilePath)
  local loadedSettings = loadConfig(configFilePath)
  settings = leftJoin(settings, loadedSettings)
end

local function saveConfig(newSettings)
  -- mq.pickle(configFilePath, newSettings)
  local file = assert(io.open(configFilePath, "w"))
  file:write(toString(newSettings))
  file:close()
  settings = newSettings
end

return {
  LoadConfig = function() return settings end,
  SaveConfig = saveConfig
}