-- Rotations\Priest\Shadow.lua

-- Rotation logic for Priest Shadow in WoW 3.3.5, optimized for DoTs and mind blasts.
DpsHelper = DpsHelper or {}

DpsHelper.Rotations = DpsHelper.Rotations or {}

DpsHelper.Rotations.PRIEST = DpsHelper.Rotations.PRIEST or {}

DpsHelper.Rotations.PRIEST.Shadow = DpsHelper.Rotations.PRIEST.Shadow or {}
function DpsHelper.Rotations.PRIEST.Shadow:GetRotationQueue()

local queue = {}

local target = UnitExists("target") and UnitCanAttack("player", "target") and not UnitIsDeadOrGhost("target")

local isAoE = DpsHelper.Utils:GetNumberOfEnemiesNearby(10) >= 3

local isBossOrElite = target and DpsHelper.Utils:IsTargetBossOrElite()

DpsHelper.Utils:DebugPrint(2, "Shadow: Checking rotation for target=" .. (target and "valid" or "invalid") .. ", AoE=" .. (isAoE and "true" or "false") .. ", Boss/Elite=" .. (isBossOrElite and "true" or "false"))
-- Verificar estados de buffs, debuffs e procs

local shadowWeaving = DpsHelper.Utils:GetDebuffRemainingTime("target", "Shadow Weaving") > 0

local manaPercent = UnitPower("player", 0) / UnitPowerMax("player")

local targetHealthPercent = target and UnitHealth("target") / UnitHealthMax("target") or 1

local isExecutePhase = targetHealthPercent <= 0.25
-- Rotação AoE

if target and isAoE then

local spells = {

{ name = "Mind Sear", id = 48045, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Mind Sear")

end, priority = 1 }

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

{ name = "Vampiric Touch", id = 34914, condition = function()

return DpsHelper.Utils:GetDebuffRemainingTime("target", "Vampiric Touch") <= 2 and DpsHelper.SpellManager:IsSpellUsable("Vampiric Touch")

end, priority = 1 },

{ name = "Devouring Plague", id = 48300, condition = function()

return DpsHelper.Utils:GetDebuffRemainingTime("target", "Devouring Plague") <= 2 and DpsHelper.SpellManager:IsSpellUsable("Devouring Plague")

end, priority = 2 },

{ name = "Shadow Word: Pain", id = 589, condition = function()

return DpsHelper.Utils:GetDebuffRemainingTime("target", "Shadow Word: Pain") <= 2 and DpsHelper.SpellManager:IsSpellUsable("Shadow Word: Pain")

end, priority = 3 },

{ name = "Mind Blast", id = 8092, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Mind Blast")

end, priority = 4 },

{ name = "Shadow Word: Death", id = 32379, condition = function()

return isExecutePhase and DpsHelper.SpellManager:IsSpellUsable("Shadow Word: Death")

end, priority = 5 },

{ name = "Mind Flay", id = 15407, condition = function()

return DpsHelper.SpellManager:IsSpellUsable("Mind Flay")

end, priority = 6 }

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
return queue

end
