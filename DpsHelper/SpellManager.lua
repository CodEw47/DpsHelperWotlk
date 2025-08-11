-- SpellManager.lua
-- Manages spell and item detection and caching for all classes in WoW 3.3.5 (WotLK).

DpsHelper = DpsHelper or {}
DpsHelper.SpellManager = DpsHelper.SpellManager or {}
DpsHelper.SpellManager.Cache = DpsHelper.SpellManager.Cache or {}
DpsHelper.SpellManager.PoisonCache = DpsHelper.SpellManager.PoisonCache or {}
DpsHelper.SpellManager.scanned = false
DpsHelper.SpellManager.scannedInventory = false

local talentSpells = {
    ROGUE = { ["Blade Flurry"] = 13877, ["Adrenaline Rush"] = 13750, ["Killing Spree"] = 51690, ["Shadow Dance"] = 51713, ["Preparation"] = 14185, ["Shadowstep"] = 36554 },
    MAGE = { ["Arcane Power"] = 12042, ["Icy Veins"] = 12472 },
    WARLOCK = { ["Haunt"] = 48181, ["Metamorphosis"] = 47241 },
    DRUID = { ["Berserk"] = 50334 },
    DEATHKNIGHT = { ["Unholy Blight"] = 49194 },
    PRIEST = { ["Vampiric Embrace"] = 15286 }
}

local spellNames = {
    ROGUE = {
        { name = "Sinister Strike", id = 48638 },
        { name = "Slice and Dice", id = 5171 },
        { name = "Rupture", id = 48672 },
        { name = "Eviscerate", id = 48668 },
        { name = "Expose Armor", id = 26866 },
        { name = "Tricks of the Trade", id = 57934 },
        { name = "Fan of Knives", id = 51723 },
        { name = "Shiv", id = 5938 },
        { name = "Vanish", id = 26889 },
        { name = "Feint", id = 48659 },
        { name = "Evasion", id = 26669 },
        { name = "Cloak of Shadows", id = 31224 },
        { name = "Gouge", id = 1776 },
        { name = "Kick", id = 1766 },
        { name = "Sprint", id = 11305 },
        { name = "Blind", id = 2094 },
        { name = "Distract", id = 1725 },
        { name = "Pick Pocket", id = 921 },
        { name = "Sap", id = 51724 },
        { name = "Stealth", id = 1784 }
    }
}

local itemNames = {
    ROGUE = {
        ["Instant Poison IX"] = { itemID = 43231, buffName = nil },
        ["Deadly Poison IX"] = { itemID = 43233, buffName = nil },
        ["Crippling Poison II"] = { itemID = 3776, buffName = nil },
        ["Mind-Numbing Poison III"] = { itemID = 11202, buffName = nil },
        ["Wound Poison V"] = { itemID = 27187, buffName = nil }
    },
    ALL = {
        ["Deathbringer's Will"] = { itemID = 50362, buffName = nil, spellID = 71484 },
        ["Whispering Fanged Skull"] = { itemID = 50342, buffName = nil, spellID = 71401 },
        ["Needle-Encrusted Scorpion"] = { itemID = 50198, buffName = nil, spellID = 71403 }
    }
}

function DpsHelper.SpellManager:ScanSpellbook()
    if self.scanned then return end
    local playerClass = select(2, UnitClass("player")):upper()
    self.Cache = {} -- Limpar o cache antes de escanear
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(2,"Cleared SpellManager cache for " .. playerClass)
    end

    -- Obter número de abas do spellbook
    local numTabs = GetNumSpellTabs()
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(2,"Scanning " .. numTabs .. " spellbook tabs for " .. playerClass)
    end

    -- Iterar por cada aba do spellbook
    for tabIndex = 1, numTabs do
        local tabName, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(2,"Scanning tab: " .. (tabName or "Unknown") .. " (offset: " .. offset .. ", numSpells: " .. numSpells .. ")")
        end

        -- Iterar pelos feitiços da aba
        for i = 1, numSpells do
            local name = GetSpellName(i + offset, "spell")
            if name then
                -- Tentar obter o spellID via GetSpellLink
                local spellLink = GetSpellLink(i + offset, "spell")
                local spellID = nil
                if spellLink then
                    spellID = tonumber(spellLink:match("|Hspell:(%d+)|h"))
                end
                -- Fallback para GetSpellInfo se GetSpellLink falhar
                if not spellID or spellID <= 0 then
                    spellID = select(7, GetSpellInfo(name)) or 0
                end
                if spellID and spellID > 0 and IsSpellKnown(spellID) then
                    if not IsPassiveSpell(i + offset, "spell") then
                        self.Cache[name] = { id = spellID, type = "spell" }
                        if DpsHelper.Config:Get("enableDebug") then
                            DpsHelper.Utils:DebugPrint(2,"Spell cached: " .. name .. " (ID: " .. spellID .. ") from tab: " .. (tabName or "Unknown"))
                        end
                    elseif DpsHelper.Config:Get("enableDebug") then
                        DpsHelper.Utils:DebugPrint(2,"Passive spell skipped: " .. name .. " (ID: " .. spellID .. ") from tab: " .. (tabName or "Unknown"))
                    end
                else
                    if DpsHelper.Config:Get("enableDebug") then
                        DpsHelper.Utils:DebugPrint(2,"Invalid spellID for: " .. name .. " (SpellLink: " .. (spellLink or "nil") .. ") from tab: " .. (tabName or "Unknown"))
                    end
                end
            else
                if DpsHelper.Config:Get("enableDebug") then
                    DpsHelper.Utils:DebugPrint(2,"No spell found at index: " .. (i + offset) .. " in tab: " .. (tabName or "Unknown"))
                end
            end
        end
    end

    -- Cachear feitiços de talentos
    for name, spellID in pairs(talentSpells[playerClass] or {}) do
        if type(spellID) == "number" and spellID > 0 and IsSpellKnown(spellID) then
            self.Cache[name] = { id = spellID, type = "spell", buffName = nil }
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:DebugPrint(2,"Talent spell cached: " .. name .. " (ID: " .. spellID .. ")")
            end
        elseif DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(2,"Talent spell not known: " .. name .. " (ID: " .. tostring(spellID) .. ")")
        end
    end

    self.scanned = true
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(2,"Spellbook scanned for " .. playerClass)
        self:DebugCache() -- Exibir o conteúdo do cache após o escaneamento
    end
end

function DpsHelper.SpellManager:ScanInventory()
    if self.scannedInventory then return end
    local playerClass = select(2, UnitClass("player")):upper()
    self.Cache = self.Cache or {}
    for name, itemData in pairs(itemNames[playerClass] or {}) do
        if GetItemCount(itemData.itemID) > 0 then
            self.Cache[name] = { id = itemData.itemID, type = "item", buffName = itemData.buffName }
            DpsHelper.Utils:DebugPrint(2,"Item cached: " .. name .. " (ID: " .. itemData.itemID .. ")")
        end
    end
    for name, itemData in pairs(itemNames.ALL or {}) do
        if GetItemCount(itemData.itemID) > 0 then
            self.Cache[name] = { id = itemData.itemID, type = "item", buffName = itemData.buffName }
            DpsHelper.Utils:DebugPrint(2,"Item cached: " .. name .. " (ID: " .. itemData.itemID .. ")")
        end
    end
    self.scannedInventory = true
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(2,"Inventory scanned")
        self:DebugCache() -- Exibir o conteúdo do cache após o escaneamento do inventário
    end
end

function DpsHelper.SpellManager:IsPoisonApplied(poisonName)
    if self.PoisonCache[poisonName] ~= nil then return self.PoisonCache[poisonName] end
    local enchantTooltip = CreateFrame("GameTooltip", "DpsHelperEnchantTooltip", UIParent, "GameTooltipTemplate")
    local hasMainHandEnchant, mainHandExpiration, _, _, hasOffHandEnchant, offHandExpiration = GetWeaponEnchantInfo()
    local isApplied = false
    if hasMainHandEnchant and mainHandExpiration > 0 then
        enchantTooltip:ClearLines()
        enchantTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        enchantTooltip:SetInventoryItem("player", 16)
        for i = 1, enchantTooltip:NumLines() do
            local lineText = _G["DpsHelperEnchantTooltipTextLeft" .. i]:GetText()
            if lineText and string.find(lineText, poisonName) then
                isApplied = true
                break
            end
        end
    end
    if hasOffHandEnchant and offHandExpiration > 0 then
        enchantTooltip:ClearLines()
        enchantTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        enchantTooltip:SetInventoryItem("player", 17)
        for i = 1, enchantTooltip:NumLines() do
            local lineText = _G["DpsHelperEnchantTooltipTextLeft" .. i]:GetText()
            if lineText and string.find(lineText, poisonName) then
                isApplied = true
                break
            end
        end
    end
    self.PoisonCache[poisonName] = isApplied
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(2,"Checking poison: " .. poisonName .. " - Applied: " .. tostring(isApplied))
    end
    return isApplied
end

function DpsHelper.SpellManager:GetSpellID(name)
    if not name then return 0 end
    if not self.Cache[name] then
        self:ScanSpellbook()
        self:ScanInventory()
    end
    local entry = self.Cache[name] or { id = 0, type = "unknown", buffName = nil }
    if DpsHelper.Config:Get("enableDebug") and entry.id == 0 then
        DpsHelper.Utils:DebugPrint(2,"SpellManager: Spell not found in cache: " .. name)
    end
    return entry.id
end

function DpsHelper.SpellManager:IsSpellUsable(name)
    local entry = self.Cache[name] or { id = 0, type = "unknown", buffName = nil }
    if entry.id == 0 then
        self:GetSpellID(name)
        entry = self.Cache[name] or { id = 0, type = "unknown", buffName = nil }
    end
    if entry.id == 0 then
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(2,"SpellManager: Spell not found in cache: " .. name)
        end
        return false
    end
    if entry.type == "spell" then
        local usable, noMana = IsUsableSpell(name)
        local start, duration = GetSpellCooldown(name)
        local isOnCooldown = start > 0 and duration > 0 and (start + duration - GetTime()) > 1.5
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(2,"SpellManager: Checking " .. name .. ": usable=" .. tostring(usable) .. ", noMana=" .. tostring(noMana) .. ", isOnCooldown=" .. tostring(isOnCooldown))
        end
        return usable and not isOnCooldown and not noMana
    elseif entry.type == "item" then
        local count = GetItemCount(entry.id)
        local start, duration = GetItemCooldown(entry.id)
        local isEquipped = false
        local playerClass = select(2, UnitClass("player")):upper()
        if itemNames.ALL and itemNames.ALL[name] and itemNames.ALL[name].spellID then
            local trinket1, trinket2 = GetInventoryItemID("player", 13), GetInventoryItemID("player", 14)
            isEquipped = trinket1 == entry.id or trinket2 == entry.id
        end
        local hasWeapon = itemNames[playerClass] and itemNames[playerClass][name] and (GetInventoryItemID("player", 16) or GetInventoryItemID("player", 17))
        if hasWeapon and self:IsPoisonApplied(name) then
            return false
        end
        local buffRemaining = entry.buffName and DpsHelper.Utils:GetBuffRemainingTime("player", entry.buffName) or 0
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(2,"SpellManager: Checking item " .. name .. ": count=" .. count .. ", isEquipped=" .. tostring(isEquipped) .. ", buffRemaining=" .. buffRemaining .. ", isOnCooldown=" .. tostring(start > 0 and duration > 0))
        end
        return (count > 0 or isEquipped) and (start == 0 or duration <= 1.5) and (not entry.buffName or buffRemaining <= 0)
    end
    return false
end

function DpsHelper.SpellManager:DebugCache()
    if not DpsHelper.Config:Get("enableDebug") then return end
    DpsHelper.Utils:DebugPrint(2,"=== SpellManager Cache Contents ===")
    local spellCount, itemCount = 0, 0
    for name, data in pairs(self.Cache) do
        if data.type == "spell" then
            DpsHelper.Utils:DebugPrint(2,"Spell: " .. name .. " (ID: " .. data.id .. ")")
            spellCount = spellCount + 1
        elseif data.type == "item" then
            DpsHelper.Utils:DebugPrint(2,"Item: " .. name .. " (ID: " .. data.id .. ")")
            itemCount = itemCount + 1
        end
    end
    DpsHelper.Utils:DebugPrint(2,"Total Spells Cached: " .. spellCount .. ", Total Items Cached: " .. itemCount)

    -- Verificar feitiços esperados para Rogue Combat
    local playerClass = select(2, UnitClass("player")):upper()
    if playerClass == "ROGUE" then
        DpsHelper.Utils:DebugPrint(2,"=== Checking Expected Rogue Combat Spells ===")
        for _, spellData in ipairs(spellNames.ROGUE) do
            local spellName, spellID = spellData.name, spellData.id
            if self.Cache[spellName] then
                DpsHelper.Utils:DebugPrint(2,"Found: " .. spellName .. " (ID: " .. self.Cache[spellName].id .. ")")
            else
                local isKnown = IsSpellKnown(spellID)
                DpsHelper.Utils:DebugPrint(2,"Missing: " .. spellName .. " (ID: " .. spellID .. ", Known: " .. tostring(isKnown) .. ")")
            end
        end
    end
    DpsHelper.Utils:DebugPrint(2,"=== End of Cache Contents ===")
end

DpsHelper.Utils:DebugPrint(2,"SpellManager.lua loaded")