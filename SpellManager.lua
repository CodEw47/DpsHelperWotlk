-- SpellManager.lua
-- Manages spell and item detection and caching for all classes in WoW 3.3.5 (WotLK).

DpsHelper = DpsHelper or {}
DpsHelper.SpellManager = DpsHelper.SpellManager or {}
DpsHelper.SpellManager.Cache = DpsHelper.SpellManager.Cache or {}
DpsHelper.SpellManager.PoisonCache = DpsHelper.SpellManager.PoisonCache or {}
DpsHelper.SpellManager.scanned = false  -- Flag para evitar rescans de spellbook
DpsHelper.SpellManager.scannedInventory = false  -- Flag para evitar rescans de 
local talentSpells = {
    ROGUE = { ["Blade Flurry"] = 13877, ["Adrenaline Rush"] = 13750, ["Killing Spree"] = 51690, ["Shadow Dance"] = 51713, ["Preparation"] = 14185, ["Shadowstep"] = 36554 },
    MAGE = { ["Arcane Power"] = 12042, ["Icy Veins"] = 12472 },
    WARLOCK = { ["Haunt"] = 48181 }, -- Metamorphosis removido, pois é específico de Demonology
    DRUID = { ["Berserk"] = 50334 },
    DEATHKNIGHT = { ["Unholy Blight"] = 49194 },
    PRIEST = { ["Vampiric Embrace"] = 15286 }
}

local spellNames = {
    ROGUE = {
        { name = "Sinister Strike", id = 48638 },
        { name = "Eviscerate", id = 48668 },
        { name = "Rupture", id = 48672 },
        { name = "Slice and Dice", id = 5171 },
        { name = "Fan of Knives", id = 51723 },
        { name = "Mutilate", id = 1329 },
        { name = "Envenom", id = 32645 },
        { name = "Hunger for Blood", id = 51662 },
        { name = "Backstab", id = 53 },
        { name = "Hemorrhage", id = 16511 },
        { name = "Ambush", id = 8676 },
        { name = "Garrote", id = 48676 }
    },
    WARRIOR = { "Heroic Strike", "Cleave", "Slam", "Rend", "Mortal Strike", "Overpower", "Execute", "Bloodthirst", "Whirlwind", "Shield Slam", "Devastate", "Revenge", "Shield Block", "Battle Shout", "Commanding Shout", "Berserker Rage", "Recklessness" },
    PALADIN = { "Crusader Strike", "Divine Storm", "Hammer of the Righteous", "Judgement of Light", "Judgement of Wisdom", "Seal of Command", "Seal of Righteousness", "Seal of Vengeance", "Holy Shock", "Flash of Light", "Holy Light", "Consecration", "Avenging Wrath", "Divine Plea", "Hammer of Wrath" },
    HUNTER = { "Aimed Shot", "Arcane Shot", "Steady Shot", "Multi-Shot", "Serpent Sting", "Chimera Shot", "Explosive Shot", "Kill Shot", "Aspect of the Hawk", "Aspect of the Viper", "Rapid Fire", "Hunter's Mark", "Volley" },
    PRIEST = { "Shadow Word: Pain", "Vampiric Touch", "Mind Blast", "Mind Flay", "Shadow Word: Death", "Power Word: Shield", "Flash Heal", "Greater Heal", "Prayer of Mending", "Renew", "Penance", "Dispersion" },
    SHAMAN = { "Stormstrike", "Earth Shock", "Flame Shock", "Frost Shock", "Lava Lash", "Fire Nova", "Magma Totem", "Searing Totem", "Windfury Weapon", "Earthbind Totem", "Healing Wave", "Lesser Healing Wave", "Chain Heal", "Riptide", "Shamanistic Rage" },
    MAGE = { "Fireball", "Frostbolt", "Arcane Missiles", "Pyroblast", "Scorch", "Fire Blast", "Frost Nova", "Blizzard", "Ice Lance", "Arcane Barrage", "Living Bomb", "Mirror Image" },
    WARLOCK = {
        { name = "Corruption", id = 172 },
        { name = "Curse of Agony", id = 980 },
        { name = "Curse of Doom", id = 603 },
        { name = "Unstable Affliction", id = 30108 },
        { name = "Immolate", id = 348 },
        { name = "Incinerate", id = 29722 },
        { name = "Shadow Bolt", id = 686 },
        { name = "Chaos Bolt", id = 50796 }, -- Destruction-specific
        { name = "Conflagrate", id = 17962 }, -- Destruction-specific
        { name = "Soul Fire", id = 6353 },
        { name = "Searing Pain", id = 5676 },
        { name = "Shadowfury", id = 30283 }, -- Destruction-specific
        { name = "Drain Life", id = 689 },
        { name = "Haunt", id = 48181 }, -- Affliction-specific
        { name = "Siphon Life", id = 63106 } -- Affliction-specific
    },
    DRUID = { "Moonfire", "Insect Swarm", "Starfire", "Wrath", "Starfall", "Hurricane", "Rip", "Rake", "Ferocious Bite", "Mangle (Cat)", "Mangle (Bear)", "Lifebloom", "Regrowth", "Rejuvenation", "Wild Growth", "Swipe (Bear)", "Maul" },
    DEATHKNIGHT = { "Icy Touch", "Plague Strike", "Obliterate", "Blood Strike", "Frost Strike", "Howling Blast", "Death Coil", "Death and Decay", "Scourge Strike", "Blood Boil", "Rune Strike", "Heart Strike", "Anti-Magic Shell", "Bone Shield" }
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

function DpsHelper.SpellManager:InitializeTalentCache()
    local playerClass = select(2, UnitClass("player")):upper()
    for name, spellID in pairs(talentSpells[playerClass] or {}) do
        if type(spellID) == "number" and spellID > 0 then
            if IsSpellKnown(spellID) then
                self.Cache[name] = { id = spellID, type = "spell", buffName = nil }
            elseif DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:Print("Talent spell not known: " .. name .. " (ID: " .. spellID .. ")")
            end
        elseif DpsHelper.Config:Get("enableDebug") then
            DpsHelper.Utils:Print("Invalid spellID for talent spell: " .. name .. " (ID: " .. tostring(spellID) .. ")")
        end
    end
end

function DpsHelper.SpellManager:ScanSpellbook()
    if self.scanned then return end
    local playerClass = select(2, UnitClass("player")):upper()
    local playerSpec = DpsHelper.Config:Get("currentSpec"):gsub("^%l", string.upper)
    local specSpells = spellNames[playerClass][playerSpec] or spellNames[playerClass] or {}
    self.Cache = self.Cache or {}
    for _, spellData in ipairs(specSpells) do
        local name = spellData.name
        local spellID = spellData.id
        if name and spellID > 0 then
            if IsSpellKnown(spellID) then
                self.Cache[name] = { id = spellID, type = "spell" }
                if DpsHelper.Config:Get("enableDebug") then
                    DpsHelper.Utils:Print("Spell cached: " .. name .. " (ID: " .. spellID .. ")")
                end
            elseif DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:Print("Spell not known: " .. name .. " (ID: " .. spellID .. ")")
            end
        end
    end
    self:InitializeTalentCache()
    self.scanned = true
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:Print("Spellbook scanned for " .. playerClass .. " (" .. playerSpec .. ")")
    end
end

function DpsHelper.SpellManager:ScanInventory()
    if self.scannedInventory then return end  -- Evita rescans desnecessários
    local playerClass = select(2, UnitClass("player")):upper()
    for name, data in pairs(itemNames[playerClass] or {}) do
        if GetItemCount(data.itemID) > 0 then
            self.Cache[name] = { id = data.itemID, type = "item", buffName = data.buffName, spellID = data.spellID }
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:Print("Item cached: " .. name .. " (ID: " .. data.itemID .. ")")
            end
        end
    end
    for name, data in pairs(itemNames.ALL or {}) do
        local trinket1, trinket2 = GetInventoryItemID("player", 13), GetInventoryItemID("player", 14)
        if trinket1 == data.itemID or trinket2 == data.itemID then
            self.Cache[name] = { id = data.itemID, type = "item", buffName = data.buffName, spellID = data.spellID }
            if DpsHelper.Config:Get("enableDebug") then
                DpsHelper.Utils:Print("Trinket cached: " .. name .. " (ID: " .. data.itemID .. ")")
            end
        end
    end
    self.scannedInventory = true
    if DpsHelper.Config:Get("enableDebug") then
        DpsHelper.Utils:Print("Inventory scanned")
    end
end

function DpsHelper.SpellManager:UpdateCache()
    self:ScanSpellbook()
    self:ScanInventory()
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
        DpsHelper.Utils:Print("Checking poison: " .. poisonName .. " - Applied: " .. tostring(isApplied))
    end
    return isApplied
end

function DpsHelper.SpellManager:GetSpellID(name)
    if not name then return 0 end
    if not self.Cache[name] then
        self:UpdateCache()
    end
    local entry = self.Cache[name] or { id = 0, type = "unknown", buffName = nil }
    return entry.id
end

function DpsHelper.SpellManager:IsSpellUsable(name)
    local entry = self.Cache[name] or { id = 0, type = "unknown", buffName = nil }
    if entry.id == 0 then
        self:GetSpellID(name)
        entry = self.Cache[name] or { id = 0, type = "unknown", buffName = nil }
    end
    if entry.id == 0 then
        return false
    end
    if entry.type == "spell" then
        local usable, noMana = IsUsableSpell(name)
        local start, duration = GetSpellCooldown(name)
        return usable and (start == 0 or duration <= 1.5) and not noMana
    elseif entry.type == "item" then
        local count = GetItemCount(entry.id)
        local start, duration = GetItemCooldown(entry.id)
        local isEquipped = false
        local playerClass = select(2, UnitClass("player")):upper()
        if itemNames.ALL and itemNames.ALL[name] and itemNames.ALL[name].spellID then
            local trinket1, trinket2 = GetInventoryItemID("player", 13), GetInventoryItemID("player", 14)
            isEquipped = trinket1 == entry.id or trinket2 == data.itemID
        end
        local hasWeapon = itemNames[playerClass] and itemNames[playerClass][name] and (GetInventoryItemID("player", 16) or GetInventoryItemID("player", 17))
        if hasWeapon and self:IsPoisonApplied(name) then
            return false
        end
        local buffRemaining = entry.buffName and DpsHelper.Utils:GetBuffRemainingTime("player", entry.buffName) or 0
        return (count > 0 or isEquipped) and (start == 0 or duration <= 1.5) and (not entry.buffName or buffRemaining <= 0)
    end
    return false
end

DpsHelper.Utils:Print("SpellManager.lua loaded")