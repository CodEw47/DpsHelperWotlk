-- SpellManager.lua
-- Manages spell detection and caching for all classes.

DpsHelper = DpsHelper or {}
DpsHelper.SpellManager = DpsHelper.SpellManager or {}
DpsHelper.SpellManager.Cache = {}

-- Lista de feitiços por classe, incluindo habilidades principais, buffs e debuffs
local spellNames = {
    ROGUE = {
        "Sinister Strike", "Eviscerate", "Rupture", "Slice and Dice", "Fan of Knives",
        "Blade Flurry", "Adrenaline Rush", "Killing Spree", "Mutilate", "Envenom",
        "Hunger for Blood", "Backstab", "Hemorrhage", "Shadow Dance", "Preparation",
        "Shadowstep", "Instant Poison", "Deadly Poison", "Ambush", "Garrote"
    },
    WARRIOR = {
        "Heroic Strike", "Cleave", "Slam", "Rend", "Mortal Strike", "Overpower",
        "Execute", "Bladestorm", "Bloodthirst", "Whirlwind", "Shield Slam",
        "Devastate", "Revenge", "Shield Block", "Battle Shout", "Commanding Shout",
        "Berserker Rage", "Recklessness"
    },
    PALADIN = {
        "Crusader Strike", "Divine Storm", "Hammer of the Righteous", "Judgement of Light",
        "Judgement of Wisdom", "Seal of Command", "Seal of Righteousness", "Seal of Vengeance",
        "Holy Shock", "Flash of Light", "Holy Light", "Consecration", "Avenging Wrath",
        "Divine Plea", "Hammer of Wrath"
    },
    HUNTER = {
        "Aimed Shot", "Arcane Shot", "Steady Shot", "Multi-Shot", "Serpent Sting",
        "Chimera Shot", "Explosive Shot", "Kill Shot", "Aspect of the Hawk",
        "Aspect of the Viper", "Rapid Fire", "Hunter's Mark", "Volley"
    },
    PRIEST = {
        "Shadow Word: Pain", "Vampiric Touch", "Mind Blast", "Mind Flay", "Shadow Word: Death",
        "Power Word: Shield", "Flash Heal", "Greater Heal", "Prayer of Mending",
        "Renew", "Penance", "Dispersion", "Vampiric Embrace"
    },
    SHAMAN = {
        "Stormstrike", "Earth Shock", "Flame Shock", "Frost Shock", "Lava Lash",
        "Fire Nova", "Magma Totem", "Searing Totem", "Windfury Weapon",
        "Earthbind Totem", "Healing Wave", "Lesser Healing Wave", "Chain Heal",
        "Riptide", "Shamanistic Rage"
    },
    MAGE = {
        "Fireball", "Frostbolt", "Arcane Missiles", "Pyroblast", "Scorch",
        "Fire Blast", "Frost Nova", "Blizzard", "Ice Lance", "Arcane Barrage",
        "Living Bomb", "Mirror Image", "Arcane Power", "Icy Veins"
    },
    WARLOCK = {
        "Corruption", "Curse of Agony", "Curse of Doom", "Unstable Affliction",
        "Immolate", "Incinerate", "Shadow Bolt", "Chaos Bolt", "Conflagrate",
        "Soul Fire", "Searing Pain", "Metamorphosis", "Shadowfury"
    },
    DRUID = {
        "Moonfire", "Insect Swarm", "Starfire", "Wrath", "Starfall", "Hurricane",
        "Rip", "Rake", "Ferocious Bite", "Mangle (Cat)", "Mangle (Bear)",
        "Lifebloom", "Regrowth", "Rejuvenation", "Wild Growth", "Swipe (Bear)",
        "Maul", "Berserk"
    },
    DEATHKNIGHT = {
        "Icy Touch", "Plague Strike", "Obliterate", "Blood Strike", "Frost Strike",
        "Howling Blast", "Death Coil", "Death and Decay", "Scourge Strike",
        "Blood Boil", "Rune Strike", "Heart Strike", "Anti-Magic Shell",
        "Bone Shield", "Unholy Blight"
    }
}

-- Função para verificar se um feitiço está disponível (aprendido e não em cooldown)
local function IsSpellAvailable(spellName)
    local spellID = DpsHelper.SpellManager:GetSpellID(spellName)
    if spellID == 0 then return false end
    local start, duration = GetSpellCooldown(spellName)
    return spellID > 0 and (start == 0 or duration <= 1.5) -- Considera GCD
end

-- Função para atualizar o cache de feitiços
function DpsHelper.SpellManager:ScanSpellbook()
    DpsHelper.Utils:Print("Scanning spellbook...")
    wipe(self.Cache)
    local playerClass = select(2, UnitClass("player"))
    local spellsToFind = spellNames[playerClass:upper()] or {}
    
    if not spellsToFind or #spellsToFind == 0 then
        DpsHelper.Utils:Print("No spells defined for class: " .. playerClass)
        return
    end

    local numTabs = GetNumSpellTabs()
    if not numTabs or numTabs == 0 then
        DpsHelper.Utils:Print("No spell tabs available, skipping scan")
        return
    end

    for tabIndex = 1, numTabs do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex)
        for spellIndex = offset + 1, offset + numSpells do
            local spellName = GetSpellName(spellIndex, BOOKTYPE_SPELL)
            if spellName and tContains(spellsToFind, spellName) then
                local spellLink = GetSpellLink(spellIndex, BOOKTYPE_SPELL)
                local spellID = spellLink and tonumber(spellLink:match("spell:(%d+)")) or 0
                if spellID > 0 and GetSpellInfo(spellName) then
                    self.Cache[spellName] = spellID
                    DpsHelper.Utils:Print("Found " .. spellName .. " - ID: " .. spellID)
                else
                    DpsHelper.Utils:Print("Invalid spell or no spellID for " .. spellName)
                end
            end
        end
    end
end

-- Função para obter o ID de um feitiço, com verificação de cache
function DpsHelper.SpellManager:GetSpellID(spellName)
    if not self.Cache[spellName] then
        DpsHelper.Utils:Print("Spell " .. spellName .. " not found in cache, rescanning spellbook")
        self:ScanSpellbook()
    end
    return self.Cache[spellName] or 0
end

-- Função para verificar se um feitiço está disponível para uso
function DpsHelper.SpellManager:IsSpellUsable(spellName)
    local spellID = self:GetSpellID(spellName)
    if spellID == 0 then
        DpsHelper.Utils:Print("Spell " .. spellName .. " not found or not learned")
        return false
    end
    local usable, noMana = IsUsableSpell(spellName)
    local start, duration = GetSpellCooldown(spellName)
    local isOffCooldown = start == 0 or duration <= 1.5 -- Considera GCD
    local canUse = usable and isOffCooldown and not noMana
    DpsHelper.Utils:Print(string.format("IsSpellUsable('%s' ID:%d): Usável=%s, NoMana=%s, OffCooldown=%s, Resultado=%s",
        spellName, spellID, tostring(usable), tostring(noMana), tostring(isOffCooldown), tostring(canUse)))
    return canUse
end

-- Função para atualizar o cache ao aprender novos feitiços ou mudar talentos
function DpsHelper.SpellManager:UpdateOnEvent(event)
    if event == "LEARNED_SPELL_IN_TAB" or event == "PLAYER_TALENT_UPDATE" or event == "PLAYER_LOGIN" then
        DpsHelper.Utils:Print("Spellbook or talents changed, updating cache...")
        self:ScanSpellbook()
    end
end

-- Registrar eventos para atualizar o cache dinamicamente
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("LEARNED_SPELL_IN_TAB")
eventFrame:RegisterEvent("PLAYER_TALENT_UPDATE")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(self, event, addonName, ...)
    if event == "ADDON_LOADED" and addonName == "DpsHelper" then
        DpsHelper.Utils:Print("SpellManager.lua initializing after addon load...")
        self:UnregisterEvent("ADDON_LOADED")
    elseif event == "PLAYER_LOGIN" then
        DpsHelper.Utils:Print("Player logged in, scanning spellbook...")
        DpsHelper.SpellManager:ScanSpellbook()
    else
        DpsHelper.SpellManager:UpdateOnEvent(event)
    end
end)

DpsHelper.Utils:Print("SpellManager.lua defined")