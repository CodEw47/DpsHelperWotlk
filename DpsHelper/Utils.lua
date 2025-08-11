-- Utils.lua
-- Utility functions for DpsHelper with debug levels.

DpsHelper = DpsHelper or {}
DpsHelper.Utils = DpsHelper.Utils or {}
DpsHelper.Utils.AuraCache = DpsHelper.Utils.AuraCache or { player = {}, target = {} }
DpsHelper.Utils.RecentSpells = DpsHelper.Utils.RecentSpells or {}
DpsHelper.Utils.DebugLevel = 1 -- 1=Important, 2=Verbose

function DpsHelper.Utils:DebugPrint(level, message)
    if DpsHelper.Config:Get("enableDebug") and level <= self.DebugLevel then
        print("|cFF33FF99DpsHelper (Level " .. level .. "):|r " .. message)
    end
end

function DpsHelper.Utils:MarkSpellUsed(spellName)
    self.RecentSpells[spellName] = GetTime()
end

function DpsHelper.Utils:IsSpellRecentlyUsed(spellName)
    local lastUsed = self.RecentSpells[spellName] or 0
    return (GetTime() - lastUsed) < 2
end

function DpsHelper.Utils:UpdateAuraCache(unit)
    if not UnitExists(unit) then return end
    local cache = self.AuraCache[unit] or {}
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitBuff(unit, i)
        if not name then break end
        cache[name] = { duration = duration or 0, expirationTime = expirationTime or 0 }
    end
    if unit == "target" then
        for i = 1, 40 do
            local name, _, _, _, duration, expirationTime = UnitDebuff(unit, i)
            if not name then break end
            cache[name] = { duration = duration or 0, expirationTime = expirationTime or 0 }
        end
    end
    self.AuraCache[unit] = cache
end

function DpsHelper.Utils:GetBuffRemainingTime(unit, buffName)
    for i = 1, 40 do
        local name, _, _, _, _, duration, expirationTime = UnitBuff(unit, i)
        if name == buffName then
            if duration and expirationTime and type(expirationTime) == "number" and expirationTime > GetTime() then
                return expirationTime - GetTime()
            end
            return 0
        end
    end
    return 0
end

function DpsHelper.Utils:GetDebuffRemainingTime(unit, debuffName)
    for i = 1, 40 do
        local name, _, _, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if name == debuffName then
            if duration and expirationTime and type(expirationTime) == "number" and type(duration) == "number" and expirationTime > GetTime() then
                return expirationTime - GetTime()
            end
            return 0
        end
    end
    return 0
end

function DpsHelper.Utils:GetDebuffRemainingTimeBySpellID(unit, spellID)
    if not UnitExists(unit) then return 0 end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if name and GetSpellInfo(spellID) == name and duration and expirationTime > 0 then
            local remaining = expirationTime - GetTime()
            if remaining > 0 then return remaining end
        end
    end
    return 0
end

function DpsHelper.Utils:GetCurrentSoulShards()
    return UnitPower("player", 7)
end

function DpsHelper.Utils:GetSpellCooldownRemaining(spellName)
    local start, duration = GetSpellCooldown(spellName)
    return (start == 0 or not duration) and 0 or (start + duration - GetTime())
end

function DpsHelper.Utils:IsTargetAliveFor(duration)
    if not UnitExists("target") or UnitHealth("target") <= 0 then return false end
    local targetName = UnitName("target") or ""
    local classification = UnitClassification("target") or "normal"
    if string.find(string.lower(targetName), "dummy") or string.find(string.lower(targetName), "manequim") or classification == "trivial" then
        local combatTime = self:GetCombatTime() or 0
        return (60 - combatTime) >= duration
    end
    return UnitHealth("target") / UnitHealthMax("target") > 0.2
end

function DpsHelper.Utils:GetCombatTime()
    return self.combatStartTime and (GetTime() - self.combatStartTime) or 0
end

function DpsHelper.Utils:GetCurrentMana()
    return UnitPower("player", 0)
end

function DpsHelper.Utils:IsTargetBossOrElite()
    if not UnitExists("target") then return false end
    local classification = UnitClassification("target")
    return classification == "worldboss" or classification == "elite" or classification == "rareelite"
end

function DpsHelper.Utils:IsInCombat()
    return UnitAffectingCombat("player")
end

function DpsHelper.Utils:GetNumberOfEnemiesNearby(range)
    local count = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and not UnitIsDeadOrGhost(unit) then
            local distance = self:GetDistanceToUnit(unit)
            if distance <= range then
                count = count + 1
            end
        end
    end
    return count
end

function DpsHelper.Utils:GetDistanceToUnit(unit)
    local x1, y1 = GetPlayerMapPosition("player")
    local x2, y2 = GetPlayerMapPosition(unit)
    if x1 and y1 and x2 and y2 then
        return math.sqrt((x2 - x1)^2 + (y2 - y1)^2) * 100
    end
    return math.huge
end

DpsHelper.Utils:DebugPrint(1, "Utils.lua loaded")
