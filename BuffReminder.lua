-- BuffReminder.lua
-- Manages buff, item, and pet checks for all classes in WoW 3.3.5.

DpsHelper = DpsHelper or {}
DpsHelper.BuffReminder = DpsHelper.BuffReminder or {}
DpsHelper.SpellManager.PoisonCache = {}

local enchantTooltip = CreateFrame("GameTooltip", "DpsHelperEnchantTooltip", UIParent, "GameTooltipTemplate")

-- Função para verificar se um veneno está aplicado nas armas
function DpsHelper.SpellManager:IsPoisonApplied(poisonName)
    if self.PoisonCache[poisonName] ~= nil then return self.PoisonCache[poisonName] end
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

    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:Print("Checking poison: " .. poisonName .. " - Applied: " .. tostring(isApplied))
    end
    self.PoisonCache[poisonName] = isApplied
    return isApplied
end

local classBuffs = {
    WARLOCK = {
        Destruction = {
            buffs = {
                { name = "Fel Armor", id = 28176, condition = function() return true end },
                { name = "Demon Armor", id = 706, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Fel Armor") end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Summon Imp", id = 688 },
        },
        Affliction = {
            buffs = {
                { name = "Fel Armor", id = 28176, condition = function() return true end },
                { name = "Demon Armor", id = 706, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Fel Armor") end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Summon Imp", id = 688 },
        },
    },
    ROGUE = {
        Combat = {
            buffs = {
                { name = "Slice and Dice", id = 5171, condition = function() return InCombatLockdown() end },
            },
            items = {
                { name = "Instant Poison IX", id = 43231, condition = function() return GetItemCount(43231) > 0 and not DpsHelper.SpellManager:IsPoisonApplied("Instant Poison IX") end },
                { name = "Deadly Poison IX", id = 43233, condition = function() return GetItemCount(43233) > 0 and not DpsHelper.SpellManager:IsPoisonApplied("Deadly Poison IX") end },
                { name = "Flask of Endless Rage", id = 46376, condition = function() return GetItemCount(46376) > 0 end },
            },
        },
    },
    HUNTER = {
        Marksmanship = {
            buffs = {
                { name = "Aspect of the Hawk", id = 13165, condition = function() return true end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46376, condition = function() return GetItemCount(46376) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Call Pet", id = 883 },
        },
    },
    DEATHKNIGHT = {
        Unholy = {
            buffs = {
                { name = "Horn of Winter", id = 57330, condition = function() return true end },
                { name = "Bone Shield", id = 49222, condition = function() return true end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46376, condition = function() return GetItemCount(46376) > 0 end },
            },
        },
    },
    PALADIN = {
        Retribution = {
            buffs = {
                { name = "Seal of Vengeance", id = 31801, condition = function() return true end },
                { name = "Blessing of Might", id = 19740, condition = function() return true end },
            },
            items = {
                { name = "Flask of Relentless Assault", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
            },
        },
    },
    WARRIOR = {
        Fury = {
            buffs = {
                { name = "Battle Shout", id = 6673, condition = function() return true end },
                { name = "Commanding Shout", id = 469, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Battle Shout") end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46376, condition = function() return GetItemCount(46376) > 0 end },
            },
        },
    },
    DRUID = {
        Balance = {
            buffs = {
                { name = "Moonkin Form", id = 24858, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
            },
        },
        Feral = {
            buffs = {
                { name = "Cat Form", id = 768, condition = function() return true end },
                { name = "Savage Roar", id = 52610, condition = function() return InCombatLockdown() end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46376, condition = function() return GetItemCount(46376) > 0 end },
            },
        },
    },
    MAGE = {
        Fire = {
            buffs = {
                { name = "Arcane Intellect", id = 1459, condition = function() return true end },
                { name = "Molten Armor", id = 30482, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
            },
        },
        Frost = {
            buffs = {
                { name = "Arcane Intellect", id = 1459, condition = function() return true end },
                { name = "Icy Veins", id = 12472, condition = function() return InCombatLockdown() end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
            },
        },
    },
    SHAMAN = {
        Elemental = {
            buffs = {
                { name = "Lightning Shield", id = 324, condition = function() return true end },
                { name = "Water Shield", id = 52127, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Lightning Shield") end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
            },
        },
    },
}

function DpsHelper.BuffReminder:GetMissingBuffs()
    local playerClass = select(2, UnitClass("player")):upper()
    local playerSpec = (DpsHelper.Config:Get("currentSpec") or "unknown"):gsub("^%l", string.upper)
    local buffs = classBuffs[playerClass] and classBuffs[playerClass][playerSpec] or { buffs = {}, items = {}, pet = nil }
    local missing = { buffs = {}, items = {}, pet = nil }

    for _, buff in ipairs(buffs.buffs or {}) do
        local remaining = DpsHelper.Utils:GetBuffRemainingTime("player", buff.name)
        if remaining == 0 and buff.condition() then
            table.insert(missing.buffs, { name = buff.name, id = buff.id })
            DpsHelper.Utils:Print("Missing buff: " .. buff.name)
        end
    end

    for _, item in ipairs(buffs.items or {}) do
        local buffName = GetItemInfo(item.id) or item.name
        local remaining = buffName and DpsHelper.Utils:GetBuffRemainingTime("player", buffName) or 0
        if remaining == 0 and item.condition() then
            table.insert(missing.items, { name = item.name, id = item.id })
            DpsHelper.Utils:Print("Missing item buff: " .. item.name)
        end
    end

    if buffs.pet and buffs.pet.condition() then
        missing.pet = { action = buffs.pet.action, id = buffs.pet.id }
        DpsHelper.Utils:Print("Missing pet: " .. (buffs.pet.action or "Unknown"))
    end

    return missing
end

function DpsHelper.BuffReminder:GetRotationPrequesites()
    local queue = {}
    local missing = DpsHelper.BuffReminder:GetMissingBuffs()

    for _, buff in ipairs(missing.buffs) do
        if DpsHelper.SpellManager:IsSpellUsable(buff.name) then
            table.insert(queue, { name = buff.name, spellID = buff.id, type = "buff", priority = 0 })
            DpsHelper.Utils:Print("Added buff to queue: " .. buff.name)
            return queue -- Retorna imediatamente se houver buff ausente
        end
    end
    for _, item in ipairs(missing.items) do
        table.insert(queue, { name = item.name, spellID = item.id, type = "item", priority = 0 })
        DpsHelper.Utils:Print("Added item to queue: " .. item.name)
        return queue -- Retorna imediatamente se houver item ausente
    end
    if missing.pet then
        table.insert(queue, { name = missing.pet.action, spellID = missing.pet.id, type = "pet", priority = 0 })
        DpsHelper.Utils:Print("Added pet summon to queue: " .. (missing.pet.action or "Unknown"))
        return queue -- Retorna imediatamente se pet estiver ausente
    end

    return queue
end

function DpsHelper.BuffReminder:Initialize()
    DpsHelper.Utils:Print("BuffReminder.lua loaded")
end