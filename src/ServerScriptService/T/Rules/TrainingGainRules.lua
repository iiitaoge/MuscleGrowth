local BarbellRules = require(script.Parent.BarbellRules)
local PetMultiplierRules = require(script.Parent.Pet.PetMultiplierRules)
local RebirthRules = require(script.Parent.RebirthRules)

local TrainingGainRules = {}

local BASE_TRAINING_GAIN = 1

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

local function applyTrainingMultiplier(totalMultiplier, sourceMultiplier)
	return totalMultiplier * normalizeMultiplier(sourceMultiplier)
end

local function resolveTrainingMultiplier(progressState, activityMultiplier)
	local multiplier = 1

	multiplier = applyTrainingMultiplier(
		multiplier,
		BarbellRules.GetBarbellMultiplier(progressState and progressState.CurrentBarbellId)
	)
	multiplier = applyTrainingMultiplier(
		multiplier,
		RebirthRules.GetRebirthMultiplier(progressState and progressState.RebirthCount or 0)
	)
	multiplier = applyTrainingMultiplier(
		multiplier,
		PetMultiplierRules.GetEquippedPetMultiplier(progressState)
	)
	multiplier = applyTrainingMultiplier(multiplier, activityMultiplier)

	return multiplier
end

-- 计算收益：力量和经验使用同一个训练值，经验上限在写回进度时处理。
function TrainingGainRules.CalculateTrainingGainValues(progressState, activityMultiplier)
	local baseTrainingGain = normalizeBaseGain(BASE_TRAINING_GAIN, 1)
	local trainingGain = baseTrainingGain * resolveTrainingMultiplier(progressState, activityMultiplier)

	return trainingGain, trainingGain
end

return TrainingGainRules
