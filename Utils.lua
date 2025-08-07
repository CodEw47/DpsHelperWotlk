-- Utils.lua
-- Utility functions for DpsHelper.

DpsHelper = DpsHelper or {}
DpsHelper.Utils = DpsHelper.Utils or {}

function DpsHelper.Utils:Print(message)
    if DpsHelper.Config:Get("enableDebug") then
        print("DpsHelper: " .. message)
    end
end

-- Obtém o tempo restante de um buff em uma unidade
function DpsHelper.Utils:GetBuffRemainingTime(unit, buffName)
    if not UnitExists(unit) then
        DpsHelper.Utils:Print("GetBuffRemainingTime: Unit " .. tostring(unit) .. " does not exist")
        return 0
    end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitBuff(unit, i)
        if name == buffName then
            if expirationTime and expirationTime > 0 and duration and duration > 0 then
                local remaining = expirationTime - GetTime()
                DpsHelper.Utils:Print(string.format("GetBuffRemainingTime: %s on %s, remaining: %.2f seconds", buffName, unit, remaining))
                return remaining
            else
                DpsHelper.Utils:Print("GetBuffRemainingTime: " .. buffName .. " found, but no valid expiration/duration")
                return 0
            end
        end
    end
    DpsHelper.Utils:Print("GetBuffRemainingTime: " .. buffName .. " not found on " .. unit)
    return 0
end

-- Obtém o tempo restante de um debuff em uma unidade
function DpsHelper.Utils:GetDebuffRemainingTime(unit, debuffName)
    if not UnitExists(unit) then
        DpsHelper.Utils:Print("GetDebuffRemainingTime: Unit " .. tostring(unit) .. " does not exist")
        return 0
    end
    for i = 1, 40 do
        local name, _, _, _, duration, expirationTime = UnitDebuff(unit, i)
        if name == debuffName then
            if expirationTime and expirationTime > 0 and duration and duration > 0 then
                local remaining = expirationTime - GetTime()
                DpsHelper.Utils:Print(string.format("GetDebuffRemainingTime: %s on %s, remaining: %.2f seconds", debuffName, unit, remaining))
                return remaining
            else
                DpsHelper.Utils:Print("GetDebuffRemainingTime: " .. debuffName .. " found, but no valid expiration/duration")
                return 0
            end
        end
    end
    DpsHelper.Utils:Print("GetDebuffRemainingTime: " .. debuffName .. " not found on " .. unit)
    return 0
end

-- Verifica se um feitiço é utilizável
function DpsHelper.Utils:IsSpellUsable(spellName)
    if not spellName then
        DpsHelper.Utils:Print("IsSpellUsable: Nil spellName")
        return false
    end
    local spellID = DpsHelper.SpellManager and DpsHelper.SpellManager:GetSpellID(spellName) or 0
    if spellID == 0 then
        DpsHelper.Utils:Print("IsSpellUsable: Invalid spellID for " .. spellName)
        return false
    end
    local usable, noMana = IsUsableSpell(spellName)
    local start, duration = GetSpellCooldown(spellName)
    local isKnown = IsSpellKnown(spellID) or GetSpellInfo(spellName)
    local isOffCooldown = start == 0 or (duration and duration <= 1.5)
    local canUse = usable and isKnown and isOffCooldown and not noMana
    DpsHelper.Utils:Print(string.format("IsSpellUsable('%s' ID:%d): Usável=%s, NoMana=%s, Known=%s, CD=%s/%s, Resultado=%s",
        spellName, spellID, tostring(usable), tostring(noMana), tostring(isKnown), tostring(start), tostring(duration), tostring(canUse)))
    return canUse
end

-- Obtém o tempo restante de cooldown de um feitiço
function DpsHelper.Utils:GetSpellCooldownRemaining(spellName)
    local start, duration = GetSpellCooldown(spellName)
    local remaining = (start == 0 or not duration) and 0 or (start + duration - GetTime())
    DpsHelper.Utils:Print(string.format("GetSpellCooldownRemaining('%s'): Start=%s, Duration=%s, Remaining=%.2f", spellName, tostring(start), tostring(duration), remaining))
    return remaining
end

-- Obtém a energia atual (Rogue, Druid em Cat Form)
function DpsHelper.Utils:GetCurrentEnergy()
    local energy = UnitPower("player", 3) -- 3 = Energy
    DpsHelper.Utils:Print("GetCurrentEnergy: " .. energy)
    return energy
end

-- Obtém a raiva atual (Warrior, Druid em Bear Form)
function DpsHelper.Utils:GetCurrentRage()
    local rage = UnitPower("player", 1) -- 1 = Rage
    DpsHelper.Utils:Print("GetCurrentRage: " .. rage)
    return rage
end

-- Obtém a mana atual (Mage, Priest, Paladin, Shaman, Warlock, Druid)
function DpsHelper.Utils:GetCurrentMana()
    local mana = UnitPower("player", 0) -- 0 = Mana
    DpsHelper.Utils:Print("GetCurrentMana: " .. mana)
    return mana
end

-- Obtém o poder rúnico atual (Death Knight)
function DpsHelper.Utils:GetCurrentRunicPower()
    local runicPower = UnitPower("player", 6) -- 6 = Runic Power
    DpsHelper.Utils:Print("GetCurrentRunicPower: " .. runicPower)
    return runicPower
end

-- Obtém a energia focal atual (Hunter)
function DpsHelper.Utils:GetCurrentFocus()
    local focus = UnitPower("player", 2) -- 2 = Focus
    DpsHelper.Utils:Print("GetCurrentFocus: " .. focus)
    return focus
end

-- Obtém o poder sagrado atual (Paladin)
function DpsHelper.Utils:GetCurrentHolyPower()
    local holyPower = UnitPower("player", 9) -- 9 = Holy Power (WotLK não usa, mas incluído para compatibilidade futura)
    DpsHelper.Utils:Print("GetCurrentHolyPower: " .. holyPower)
    return holyPower
end

-- Obtém o número de pontos de combo (Rogue, Druid em Cat Form)
function DpsHelper.Utils:GetCurrentComboPoints()
    local cp = GetComboPoints("player", "target") or 0
    DpsHelper.Utils:Print("GetCurrentComboPoints: " .. cp)
    return cp
end

-- Verifica se o alvo estará vivo por um tempo mínimo
function DpsHelper.Utils:IsTargetAliveFor(duration)
    if not UnitExists("target") or UnitHealth("target") <= 0 then
        DpsHelper.Utils:Print("IsTargetAliveFor: No target or target is dead")
        return false
    end
    local healthFraction = UnitHealth("target") / UnitHealthMax("target")
    local isAlive = healthFraction > 0.2
    DpsHelper.Utils:Print(string.format("IsTargetAliveFor(%.1f): HealthFraction=%.2f, Result=%s", duration, healthFraction, tostring(isAlive)))
    return isAlive
end

-- Verifica se há múltiplos alvos próximos
function DpsHelper.Utils:HasMultipleTargets()
    local enemies = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and UnitIsEnemy("player", unit) and not UnitIsDead(unit) then
            enemies = enemies + 1
        end
    end
    local hasMultiple = enemies > 1
    DpsHelper.Utils:Print("HasMultipleTargets: Enemies=" .. enemies .. ", Result=" .. tostring(hasMultiple))
    return hasMultiple
end

-- Obtém o número de inimigos em um raio específico
function DpsHelper.Utils:GetEnemiesInRange(range)
    local enemies = 0
    for i = 1, 40 do
        local unit = "nameplate" .. i
        if UnitExists(unit) and UnitCanAttack("player", unit) and UnitIsEnemy("player", unit) and not UnitIsDead(unit) then
            local distance = GetDistanceBetween("player", unit) or 100
            if distance <= range then
                enemies = enemies + 1
            end
        end
    end
    DpsHelper.Utils:Print("GetEnemiesInRange(" .. range .. "): Enemies=" .. enemies)
    return enemies
end

-- Verifica se o jogador está atrás do alvo
function DpsHelper.Utils:IsBehindTarget()
    local isBehind = not UnitIsUnit("target", "player") and CheckInteractDistance("target", 3) -- Aproximação para "atrás do alvo"
    DpsHelper.Utils:Print("IsBehindTarget: Result=" .. tostring(isBehind))
    return isBehind
end

-- Verifica se o jogador está ao alcance de ataque corpo a corpo
function DpsHelper.Utils:IsInMeleeRange()
    local inRange = CheckInteractDistance("target", 3) or IsSpellInRange("Sinister Strike", "target") == 1 or IsSpellInRange("Heroic Strike", "target") == 1
    DpsHelper.Utils:Print("IsInMeleeRange: Result=" .. tostring(inRange))
    return inRange
end

-- Verifica se o alvo está sob controle de multidão
function DpsHelper.Utils:IsTargetCCed()
    if not UnitExists("target") then
        DpsHelper.Utils:Print("IsTargetCCed: No target")
        return false
    end
    local ccEffects = {"Polymorph", "Sap", "Fear", "Cyclone", "Entangling Roots", "Frost Nova", "Hammer of Justice"}
    for _, effect in ipairs(ccEffects) do
        if DpsHelper.Utils:GetDebuffRemainingTime("target", effect) > 0 then
            DpsHelper.Utils:Print("IsTargetCCed: Found " .. effect .. " on target")
            return true
        end
    end
    DpsHelper.Utils:Print("IsTargetCCed: No CC found")
    return false
end

-- Verifica se o jogador está em stealth (Rogue)
function DpsHelper.Utils:IsInStealth()
    local isStealthed = IsStealthed() or DpsHelper.Utils:GetBuffRemainingTime("player", "Stealth") > 0 or DpsHelper.Utils:GetBuffRemainingTime("player", "Shadow Dance") > 0
    DpsHelper.Utils:Print("IsInStealth: Result=" .. tostring(isStealthed))
    return isStealthed
end

-- Verifica se o jogador tem um aspecto ativo (Hunter)
function DpsHelper.Utils:HasAspect(aspectName)
    local hasAspect = DpsHelper.Utils:GetBuffRemainingTime("player", aspectName) > 0
    DpsHelper.Utils:Print("HasAspect(" .. aspectName .. "): Result=" .. tostring(hasAspect))
    return hasAspect
end

-- Verifica se o jogador tem um selo ativo (Paladin)
function DpsHelper.Utils:HasSeal(sealName)
    local hasSeal = DpsHelper.Utils:GetBuffRemainingTime("player", sealName) > 0
    DpsHelper.Utils:Print("HasSeal(" .. sealName .. "): Result=" .. tostring(hasSeal))
    return hasSeal
end

-- Verifica se o jogador está em uma forma específica (Druid)
function DpsHelper.Utils:IsInForm(formName)
    local formID = GetShapeshiftForm()
    local forms = {
        ["Bear Form"] = 1,
        ["Cat Form"] = 3,
        ["Moonkin Form"] = 5,
        ["Tree of Life"] = 2,
        ["Travel Form"] = 4
    }
    local isInForm = formID == forms[formName]
    DpsHelper.Utils:Print("IsInForm(" .. formName .. "): FormID=" .. formID .. ", Result=" .. tostring(isInForm))
    return isInForm
end

-- Verifica se o jogador está em uma postura específica (Warrior)
function DpsHelper.Utils:IsInStance(stanceName)
    local stanceID = GetShapeshiftForm()
    local stances = {
        ["Battle Stance"] = 1,
        ["Defensive Stance"] = 2,
        ["Berserker Stance"] = 3
    }
    local isInStance = stanceID == stances[stanceName]
    DpsHelper.Utils:Print("IsInStance(" .. stanceName .. "): StanceID=" .. stanceID .. ", Result=" .. tostring(isInStance))
    return isInStance
end

-- Verifica se o jogador tem uma aura ativa (Death Knight)
function DpsHelper.Utils:HasPresence(presenceName)
    local hasPresence = DpsHelper.Utils:GetBuffRemainingTime("player", presenceName) > 0
    DpsHelper.Utils:Print("HasPresence(" .. presenceName .. "): Result=" .. tostring(hasPresence))
    return hasPresence
end

-- Verifica se um totem específico está ativo (Shaman)
function DpsHelper.Utils:HasTotem(totemName)
    for i = 1, 4 do
        local haveTotem, name = GetTotemInfo(i)
        if haveTotem and name == totemName then
            DpsHelper.Utils:Print("HasTotem(" .. totemName .. "): Found on slot " .. i)
            return true
        end
    end
    DpsHelper.Utils:Print("HasTotem(" .. totemName .. "): Not found")
    return false
end

-- Verifica se runas estão disponíveis (Death Knight)
function DpsHelper.Utils:HasRunes(runeType, count)
    local available = 0
    for i = 1, 6 do
        local _, _, ready = GetRuneCooldown(i)
        local rType = GetRuneType(i)
        if ready and (runeType == "any" or rType == runeType) then
            available = available + 1
        end
    end
    local hasRunes = available >= count
    DpsHelper.Utils:Print(string.format("HasRunes(%s, %d): Available=%d, Result=%s", runeType, count, available, tostring(hasRunes)))
    return hasRunes
end

-- Verifica se o jogador tem veneno nas armas (Rogue)
function DpsHelper.Utils:HasWeaponPoison()
    local minDuration = 5
    local instant = DpsHelper.Utils:GetBuffRemainingTime("player", "Instant Poison") or 0
    local deadly = DpsHelper.Utils:GetBuffRemainingTime("player", "Deadly Poison") or 0
    local hasPoison = instant > minDuration or deadly > minDuration
    DpsHelper.Utils:Print("HasWeaponPoison: Instant=" .. instant .. ", Deadly=" .. deadly .. ", Result=" .. tostring(hasPoison))
    return hasPoison
end

-- Verifica se o jogador está em combate
function DpsHelper.Utils:IsInCombat()
    local inCombat = UnitAffectingCombat("player")
    DpsHelper.Utils:Print("IsInCombat: Result=" .. tostring(inCombat))
    return inCombat
end

-- Verifica se o alvo é um boss ou elite
function DpsHelper.Utils:IsTargetBossOrElite()
    if not UnitExists("target") then
        DpsHelper.Utils:Print("IsTargetBossOrElite: No target")
        return false
    end
    local classification = UnitClassification("target")
    local isBossOrElite = classification == "worldboss" or classification == "elite" or classification == "rareelite"
    DpsHelper.Utils:Print("IsTargetBossOrElite: Classification=" .. tostring(classification) .. ", Result=" .. tostring(isBossOrElite))
    return isBossOrElite
end