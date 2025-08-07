-- Config.lua
-- Centralized configuration management.

DpsHelper = DpsHelper or {}
DpsHelper.Config = {}
DpsHelper.Config.DB = DpsHelperDB or {}
DpsHelperDB = DpsHelper.Config.DB

local defaults = {
    showRecommendations = true,
    highlightColor = {1, 1, 0, 0.5},
    uiScale = 1.0,
    enableDebug = true,
    currentClass = "unknown",
    currentSpec = "unknown",
}

function DpsHelper.Config:Initialize()
    if not DpsHelper.Config.initialized then
        for key, value in pairs(defaults) do
            if DpsHelper.Config.DB[key] == nil then
                DpsHelper.Config.DB[key] = value
            end
        end
        DpsHelper.Config.initialized = true
        if DpsHelper.Utils then
            DpsHelper.Utils:Print("Config initialized.")
        end
    end
end

function DpsHelper.Config:Get(key)
    return DpsHelper.Config.DB[key]
end

function DpsHelper.Config:Set(key, value)
    DpsHelper.Config.DB[key] = value
end

-- Initialize Config immediately
DpsHelper.Config:Initialize()