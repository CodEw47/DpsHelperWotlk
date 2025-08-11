DpsHelper = DpsHelper or {}
DpsHelper.BuffReminder = DpsHelper.BuffReminder or {}
DpsHelper.SpellManager.PoisonCache = DpsHelper.SpellManager.PoisonCache or {}

local enchantTooltip = CreateFrame("GameTooltip", "DpsHelperEnchantTooltip", UIParent, "GameTooltipTemplate")

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
        DpsHelper.Utils:DebugPrint(1, "Checking poison: " .. poisonName .. " - Applied: " .. tostring(isApplied))
    end
    self.PoisonCache[poisonName] = isApplied
    return isApplied
end

local classBuffs = {
    WARLOCK = {
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
        Demonology = {
            buffs = {
                { name = "Fel Armor", id = 28176, condition = function() return true end },
                { name = "Demon Armor", id = 706, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Fel Armor") end },
                { name = "Life Tap", id = 1454, condition = function()
                    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
                    local usable = DpsHelper.SpellManager:IsSpellUsable("Life Tap")
                    return manaPercent < 0.5 and usable
                end},
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Summon Felguard", id = 30146 },
        },
    },
    MAGE = {
        Arcane = {
            buffs = {
                { name = "Arcane Intellect", id = 1459, condition = function() return true end },
                { name = "Mage Armor", id = 6117, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
        Fire = {
            buffs = {
                { name = "Arcane Intellect", id = 1459, condition = function() return true end },
                { name = "Molten Armor", id = 30482, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
        Frost = {
            buffs = {
                { name = "Arcane Intellect", id = 1459, condition = function() return true end },
                { name = "Frost Armor", id = 7302, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
    },
    HUNTER = {
        BeastMastery = {
            buffs = {
                { name = "Aspect of the Viper", id = 34074, condition = function()
                    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
                    return manaPercent < 0.3 and DpsHelper.SpellManager:IsSpellUsable("Aspect of the Viper")
                end},
                { name = "Aspect of the Hawk", id = 13165, condition = function()
                    return not DpsHelper.Utils:GetBuffRemainingTime("player", "Aspect of the Viper")
                end},
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Call Pet", id = 883 },
        },
        Marksmanship = {
            buffs = {
                { name = "Aspect of the Viper", id = 34074, condition = function()
                    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
                    return manaPercent < 0.3 and DpsHelper.SpellManager:IsSpellUsable("Aspect of the Viper")
                end},
                { name = "Aspect of the Hawk", id = 13165, condition = function()
                    return not DpsHelper.Utils:GetBuffRemainingTime("player", "Aspect of the Viper")
                end},
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Call Pet", id = 883 },
        },
        Survival = {
            buffs = {
                { name = "Aspect of the Viper", id = 34074, condition = function()
                    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
                    return manaPercent < 0.3 and DpsHelper.SpellManager:IsSpellUsable("Aspect of the Viper")
                end},
                { name = "Aspect of the Hawk", id = 13165, condition = function()
                    return not DpsHelper.Utils:GetBuffRemainingTime("player", "Aspect of the Viper")
                end},
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Call Pet", id = 883 },
        },
    },
    ROGUE = {
        Assassination = {
            buffs = {
                { name = "Deadly Poison", id = 2823, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Deadly Poison") end },
                { name = "Instant Poison", id = 8679, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Instant Poison") end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
        Combat = {
            buffs = {
                { name = "Instant Poison", id = 8679, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Instant Poison") end },
                { name = "Wound Poison", id = 13219, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Wound Poison") end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
        Subtlety = {
            buffs = {
                { name = "Deadly Poison", id = 2823, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Deadly Poison") end },
                { name = "Instant Poison", id = 8679, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Instant Poison") end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
    },
    WARRIOR = {
        Arms = {
            buffs = {
                { name = "Battle Shout", id = 6673, condition = function() return true end },
                { name = "Commanding Shout", id = 469, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Battle Shout") end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
        },
        Fury = {
            buffs = {
                { name = "Battle Shout", id = 6673, condition = function() return true end },
                { name = "Commanding Shout", id = 469, condition = function() return not DpsHelper.Utils:GetBuffRemainingTime("player", "Battle Shout") end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
        },
    },
    PALADIN = {
        Retribution = {
            buffs = {
                { name = "Blessing of Might", id = 19740, condition = function() return true end },
                { name = "Seal of Command", id = 20375, condition = function() return true end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
        },
    },
    DEATHKNIGHT = {
        Frost = {
            buffs = {
                { name = "Horn of Winter", id = 57330, condition = function() return true end },
                { name = "Frost Presence", id = 48266, condition = function() return true end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
        },
        Unholy = {
            buffs = {
                { name = "Horn of Winter", id = 57330, condition = function() return true end },
                { name = "Unholy Presence", id = 48265, condition = function() return true end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
            pet = { condition = function() return not UnitExists("pet") or UnitIsDead("pet") end, action = "Raise Dead", id = 46584 },
        },
    },
    SHAMAN = {
        Elemental = {
            buffs = {
                { name = "Lightning Shield", id = 324, condition = function() return true end },
                { name = "Water Shield", id = 52127, condition = function()
                    local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
                    return manaPercent < 0.5 and DpsHelper.SpellManager:IsSpellUsable("Water Shield")
                end},
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
        Enhancement = {
            buffs = {
                { name = "Lightning Shield", id = 324, condition = function() return true end },
                { name = "Windfury Weapon", id = 8232, condition = function() return not DpsHelper.SpellManager:IsPoisonApplied("Windfury Weapon") end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
        },
    },
    PRIEST = {
        Shadow = {
            buffs = {
                { name = "Inner Fire", id = 588, condition = function() return true end },
                { name = "Vampiric Embrace", id = 15286, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
    },
    DRUID = {
        Balance = {
            buffs = {
                { name = "Moonkin Form", id = 24858, condition = function() return true end },
                { name = "Mark of the Wild", id = 1126, condition = function() return true end },
            },
            items = {
                { name = "Flask of the Frost Wyrm", id = 46377, condition = function() return GetItemCount(46377) > 0 end },
                { name = "Elixir of Mighty Agility", id = 40093, condition = function() return GetItemCount(40093) > 0 end },
            },
        },
        FeralCat = {
            buffs = {
                { name = "Cat Form", id = 768, condition = function() return true end },
                { name = "Mark of the Wild", id = 1126, condition = function() return true end },
            },
            items = {
                { name = "Flask of Endless Rage", id = 46379, condition = function() return GetItemCount(46379) > 0 end },
                { name = "Elixir of Mighty Strength", id = 40073, condition = function() return GetItemCount(40073) > 0 end },
            },
        },
    },
}

function DpsHelper.BuffReminder:GetMissingBuffs()
    local playerClass = select(2, UnitClass("player")):upper()
    local playerSpec = (DpsHelper.Config:Get("currentSpec") or "unknown"):gsub("^%l", string.upper)
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(1, "BuffReminder: Checking buffs for class=" .. playerClass .. ", spec=" .. playerSpec)
    end
    local buffs = classBuffs[playerClass] and classBuffs[playerClass][playerSpec] or { buffs = {}, items = {}, pet = nil }
    local missing = { buffs = {}, items = {}, pet = nil }

    for _, buff in ipairs(buffs.buffs or {}) do
        local remaining = DpsHelper.Utils:GetBuffRemainingTime("player", buff.name)
        if remaining == 0 and buff.condition() then
            table.insert(missing.buffs, { name = buff.name, id = buff.id })
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:DebugPrint(1, "BuffReminder: Missing buff: " .. buff.name .. " (ID: " .. buff.id .. ")")
            end
        end
    end

    for _, item in ipairs(buffs.items or {}) do
        local buffName = GetItemInfo(item.id) or item.name
        local remaining = buffName and DpsHelper.Utils:GetBuffRemainingTime("player", buffName) or 0
        if remaining == 0 and item.condition() then
            table.insert(missing.items, { name = item.name, id = item.id })
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:DebugPrint(1, "BuffReminder: Missing item buff: " .. item.name .. " (ID: " .. item.id .. ")")
            end
        end
    end

    if buffs.pet and buffs.pet.condition() then
        missing.pet = { action = buffs.pet.action, id = buffs.pet.id }
        if DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:DebugPrint(1, "BuffReminder: Missing pet: " .. (buffs.pet.action or "Unknown") .. " (ID: " .. buffs.pet.id .. ")")
        end
    end

    return missing
end

function DpsHelper.BuffReminder:Initialize()
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:DebugPrint(1, "BuffReminder.lua loaded")
    end
end