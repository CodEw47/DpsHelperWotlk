-- Rotations\Warlock\Destruction.lua

-- Rotation logic for Warlock Destruction in WoW 3.3.5, optimized for burst DPS.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.WARLOCK = DpsHelper.Rotations.WARLOCK or {}

DpsHelper.Rotations.WARLOCK.Destruction = DpsHelper.Rotations.WARLOCK.Destruction or {}
function DpsHelper.Rotations.WARLOCK.Destruction:GetRotationQueue()

local queue = {}

local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

DpsHelper.Utils:DebugPrint(2, "Destruction: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" .. (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
-- Verificar estados de buffs, debuffs e procs

local backdraft = DpsHelper.Utils:GetBuffRemainingTime("player", "Backdraft") > 0

local empoweredImp = DpsHelper.Utils:GetBuffRemainingTime("player", "Empowered Imp") > 0

local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

local isExecutePhase = targetHealthPercent <= 0.35

local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")
-- Rotação AoE

if target and isAoE then

local spells = {

{ name = "Hellfire", id = 1949, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Hellfire") and UnitHealth("player") / UnitHealthMax("player") > 0.5

end, priority = 1 },

{ name = "Rain of Fire", id = 5740, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Rain of Fire")

end, priority = 2 },

{ name = "Seed of Corruption", id = 47836, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Seed of Corruption") and manaPercent > 0.2

end, priority = 3 }

}
local validSpells = {}

for _, spell in ipairs(spells) do

if spell.condition() then table.insert(validSpells, spell) end

end
table.sort(validSpells, function(a, b) return a.priority < b.priority end)
for i = 1, math.min(3, #validSpells) do

table.insert(queue, { name = validSpells[i].name, spellID = validSpells[i].id, type = "spell", priority = validSpells[i].priority })

end

-- Rotação Single-Target

elseif target then

local spells = {

{ name = "Chaos Bolt", id = 50796, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Chaos Bolt")

end, priority = 1 },

{ name = "Conflagrate", id = 17962, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Conflagrate")

end, priority = 2 },

{ name = "Soul Fire", id = 6353, condition = function()

return empoweredImp and DpsHelper.SpellManager:IsSpellUsable("Soul Fire")

end, priority = 3 },

{ name = "Immolate", id = 348, condition = function()

return DpsHelper.Utils:GetDebuffRemainingTime("target", "Immolate") <= 2 and DpsHelper.SpellManager:IsSpellUsable("Immolate")

end, priority = 4 },

{ name = "Incinerate", id = 29722, condition = function()

return backdraft and DpsHelper.SpellManager:IsSpellUsable("Incinerate")

end, priority = 5 },

{ name = "Shadow Bolt", id = 686, condition = function()

return isExecutePhase and DpsHelper.SpellManager:IsSpellUsable("Shadow Bolt")

end, priority = 6 },

{ name = "Incinerate", id = 29722, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Incinerate")

end, priority = 7 }

}
local validSpells = {}

for _, spell in ipairs(spells) do

if spell.condition() then table.insert(validSpells, spell) end

end
table.sort(validSpells, function(a, b) return a.priority < b.priority end)
for i = 1, math.min(3, #validSpells) do

table.insert(queue, { name = validSpells[i].name, spellID = validSpells[i].id, type = "spell", priority = validSpells[i].priority })

end

end
-- Fallback para alvo inválido: Life Tap se necessário

if not target and manaPercent < 0.4 and DpsHelper.SpellManager:IsSpellUsable("Life Tap") and UnitHealth("player") / UnitHealthMax("player") > 0.3 then

table.insert(queue, { name = "Life Tap", spellID = 1454, type = "spell", priority = 1 })

end
return queue

end