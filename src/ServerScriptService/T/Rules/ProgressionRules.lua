local BarbellRules = require(script.Parent.BarbellRules)
local LevelRules = require(script.Parent.LevelRules)
local PetMultiplierRules = require(script.Parent.Pet.PetMultiplierRules)
local RebirthRules = require(script.Parent.RebirthRules)
local TrainingGainRules = require(script.Parent.TrainingGainRules)

local ProgressionRules = {}

ProgressionRules.ResolveRebirthRule = RebirthRules.ResolveRebirthRule
ProgressionRules.GetRebirthMultiplier = RebirthRules.GetRebirthMultiplier
ProgressionRules.GetBarbellMultiplier = BarbellRules.GetBarbellMultiplier
ProgressionRules.GetBarbellRequiredTrophies = BarbellRules.GetBarbellRequiredTrophies
ProgressionRules.GetPetTypeMultiplier = PetMultiplierRules.GetPetTypeMultiplier
ProgressionRules.GetEquippedPetMultiplier = PetMultiplierRules.GetEquippedPetMultiplier
ProgressionRules.GetRequiredExp = LevelRules.GetRequiredExp
ProgressionRules.GetMaxLevel = LevelRules.GetMaxLevel
ProgressionRules.GetMaxExp = LevelRules.GetMaxExp
ProgressionRules.CalculateLevel = LevelRules.CalculateLevel
ProgressionRules.ClampExp = LevelRules.ClampExp
ProgressionRules.CanRebirth = LevelRules.CanRebirth
ProgressionRules.CalculateTrainingGainValues = TrainingGainRules.CalculateTrainingGainValues

return ProgressionRules
