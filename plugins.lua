local mq = require('mq')
local logger = require('knightlinc.Write')

local plugins = {}

---@param plugin string Name of the plugin we want to check if is loaded
---@return boolean
plugins.IsLoaded = function(plugin)
  return mq.TLO.Plugin(plugin).IsLoaded()
end

---@param plugin string Name of the plugin we want to ensure is loaded. Causes fatal exception if not.
plugins.EnsureIsLoaded = function(plugin)
  if plugins.IsLoaded(plugin) then
    logger.Debug("<%s> is loaded...", plugin)
    return
  end

  logger.Debug("Loading <%s>...", plugin)
  mq.cmd("/plugin " .. plugin)
  mq.delay(1000)
  if not plugins.IsLoaded(plugin) then
    logger.Fatal("Unable to load <%s>...", plugin)
  end
end

return plugins