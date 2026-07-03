local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BodyQualityTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("BodyQualityTheta"))

local BarbellRules = require(script.Parent.BarbellRules)
local PetMultiplierRules = require(script.Parent.Pet.PetMultiplierRules)
local RebirthRules = require(script.Parent.RebirthRules)

local TrainingGainRules = {}

local BASE_STRENGTH_GAIN = 1
local BASE_EXP_GAIN = 50

local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

local function normalizeBaseGain(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(numberValue, 0)
end

local function resolveBarbellMultipliers(progressState)
	return BarbellRules.GetBarbellMultiplier(progressState and progressState.CurrentBarbellId), 1
end

local function resolveBodyQualityMultipliers(progressState)
	local bodyQuality = progressState and BodyQualityTheta[progressState.BodyQuality]
	return 1, bodyQuality and bodyQuality.ExpMultiplier or 1
end

local function resolvePetMultipliers(progressState)
	local multiplier = PetMultiplierRules.GetEquippedPetMultiplier(progressState)
	return multiplier, multiplier
end

local function resolveRebirthMultipliers(progressState)
	local multiplier = RebirthRules.GetRebirthMultiplier(progressState and progressState.RebirthCount or 0)
	return multiplier, multiplier
end

local function resolveAutoAreaMultipliers(autoAreaMultiplier)
	local multiplier = normalizeMultiplier(autoAreaMultiplier)
	return multiplier, multiplier
end

local function applyTrainingMultiplier(totalStrengthMultiplier, totalExpMultiplier, strengthMultiplier, expMultiplier)
	return totalStrengthMultiplier * normalizeMultiplier(strengthMultiplier),
		totalExpMultiplier * normalizeMultiplier(expMultiplier)
end

local function resolveTrainingMultipliers(progressState, autoAreaMultiplier)
	local strengthMultiplier = 1
	local expMultiplier = 1

	local function apply(strengthSourceMultiplier, expSourceMultiplier)
		strengthMultiplier, expMultiplier = applyTrainingMultiplier(
			strengthMultiplier,
			expMultiplier,
			strengthSourceMultiplier,
			expSourceMultiplier
		)
	end

	apply(resolveBarbellMultipliers(progressState))
	apply(resolveBodyQualityMultipliers(progressState))
	apply(resolvePetMultipliers(progressState))
	apply(resolveRebirthMultipliers(progressState))
	apply(resolveAutoAreaMultipliers(autoAreaMultiplier))

	return strengthMultiplier, expMultiplier
end

function TrainingGainRules.CalculateTrainingGainValues(progressState, autoAreaMultiplier)
	local baseStrengthGain = normalizeBaseGain(BASE_STRENGTH_GAIN, 1)
	local baseExpGain = normalizeBaseGain(BASE_EXP_GAIN, 50)
	local strengthMultiplier, expMultiplier = resolveTrainingMultipliers(progressState, autoAreaMultiplier)

	return baseStrengthGain * strengthMultiplier,
		baseExpGain * expMultiplier
end

return TrainingGainRules
