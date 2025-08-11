-- Config.lua
-- Centralized configuration management.

DpsHelper = DpsHelper or {}
DpsHelper.Config = {}
DpsHelper.Config.DB = DpsHelperDB or {}
DpsHelperDB = DpsHelper.Config.DB

local defaults = {
    showRecommendations = true,
    highlightColor = {1, 1, 0, 0.5},
    uiScale = 0.8,
    enableDebug = false,
    currentClass = "unknown",
    currentSpec = "unknown",
    useCurseOfDoom = true, -- Prefer Curse of Doom on bosses
    debuffRefreshThreshold = 4 -- Threshold for recasting debuffs
}

function DpsHelper.Config:Initialize()
    if self.initialized then return end
    for key, value in pairs(defaults) do
        if self.DB[key] == nil then
            self.DB[key] = value
        end
    end
    self.initialized = true
end

function DpsHelper.Config:Get(key)
    return self.DB[key]
end

function DpsHelper.Config:Set(key, value)
    self.DB[key] = value
end

DpsHelper.Config:Initialize()