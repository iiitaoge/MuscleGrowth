local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("BarbellTheta"))
local BodyQualityTheta = require(theta:WaitForChild("BodyQualityTheta"))
local LevelTheta = require(theta:WaitForChild("LevelTheta"))
local RebirthTheta = require(theta:WaitForChild("RebirthTheta"))

local ProgressionRules = {}

local requiredExpByLevel = {}
local maxConfiguredLevel = 1
local lastConfiguredRebirthCount = 0

for _, levelInfo in ipairs(LevelTheta.RequiredExp or {}) do
	local level = tonumber(levelInfo.Level)
	local requiredExp = tonumber(levelInfo.Exp)

	if level and requiredExp then
		requiredExpByLevel[level] = requiredExp

		if level > maxConfiguredLevel then
			maxConfiguredLevel = level
		end
	end
end

for rebirthCount in pairs(RebirthTheta) do
	if type(rebirthCount) == "number" and rebirthCount > lastConfiguredRebirthCount then
		lastConfiguredRebirthCount = rebirthCount
	end
end

local function normalizeRebirthCount(rebirthCount)
	return math.max(0, math.floor(tonumber(rebirthCount) or 0))
end

local function normalizeLevel(level)
	return math.max(1, math.floor(tonumber(level) or 1))
end

local function getAutoAreaMultiplier(growthContext)
	local multiplier = growthContext and tonumber(growthContext.AutoAreaMultiplier) or 1
	if multiplier == nil then
		return 1
	end

	return math.max(multiplier, 0)
end

function ProgressionRules.ResolveRebirthRule(rebirthCount)
	rebirthCount = normalizeRebirthCount(rebirthCount)

	local rule = RebirthTheta[rebirthCount]
	if rule then
		return rule
	end

	local lastRule = RebirthTheta[lastConfiguredRebirthCount]
	if not lastRule then
		return {
			StrengthMultiplier = 1,
			ExpMultiplier = 1,
			MaxLevel = LevelTheta.DefaultMaxLevel,
		}
	end

	local extraRebirths = rebirthCount - lastConfiguredRebirthCount
	return {
		StrengthMultiplier = lastRule.StrengthMultiplier * (2 ^ extraRebirths),
		ExpMultiplier = lastRule.ExpMultiplier * (1.5 ^ extraRebirths),
		MaxLevel = lastRule.MaxLevel + 20 * extraRebirths,
	}
end

function ProgressionRules.GetRequiredExp(level)
	level = normalizeLevel(level)

	local configuredExp = requiredExpByLevel[level]
	if configuredExp then
		return configuredExp
	end

	local lastConfiguredExp = requiredExpByLevel[maxConfiguredLevel] or 0
	local extraLevels = level - maxConfiguredLevel

	return lastConfiguredExp + extraLevels * extraLevels * 1000
end

function ProgressionRules.GetMaxLevel(rebirthCount)
	local rebirthRule = ProgressionRules.ResolveRebirthRule(rebirthCount)
	if rebirthRule and rebirthRule.MaxLevel then
		return rebirthRule.MaxLevel
	end

	return LevelTheta.DefaultMaxLevel
end

function ProgressionRules.GetMaxExp(rebirthCount)
	return ProgressionRules.GetRequiredExp(ProgressionRules.GetMaxLevel(rebirthCount))
end

function ProgressionRules.CalculateLevel(exp, rebirthCount)
	exp = math.max(0, tonumber(exp) or 0)

	local maxLevel = ProgressionRules.GetMaxLevel(rebirthCount)
	local level = 1

	for currentLevel = 1, maxLevel do
		if exp >= ProgressionRules.GetRequiredExp(currentLevel) then
			level = currentLevel
		else
			break
		end
	end

	return level
end

function ProgressionRules.ClampExp(exp, rebirthCount)
	local maxExp = ProgressionRules.GetMaxExp(rebirthCount)
	return math.max(0, math.min(tonumber(exp) or 0, maxExp))
end

function ProgressionRules.CanRebirth(progressState)
	if not progressState then
		return false
	end

	return ProgressionRules.CalculateLevel(progressState.Exp, progressState.RebirthCount)
		>= ProgressionRules.GetMaxLevel(progressState.RebirthCount)
end

function ProgressionRules.CalculateTrainingGains(progressState, growthContext)
	local rebirthRule = ProgressionRules.ResolveRebirthRule(progressState and progressState.RebirthCount or 0)
	local barbell = progressState and BarbellTheta[progressState.CurrentBarbellId]
	local bodyQuality = progressState and BodyQualityTheta[progressState.BodyQuality]

	local barbellMult = barbell and barbell.StrengthMultiplier or 1
	local bodyMult = bodyQuality and bodyQuality.ExpMultiplier or 1
	local rebirthStrengthMult = rebirthRule and rebirthRule.StrengthMultiplier or 1
	local rebirthExpMult = rebirthRule and rebirthRule.ExpMultiplier or 1
	local testExpMult = 50
	local autoAreaMult = getAutoAreaMultiplier(growthContext)

	return {
		StrengthGain = barbellMult * rebirthStrengthMult * autoAreaMult,
		ExpGain = bodyMult * rebirthExpMult * testExpMult * autoAreaMult,
	}
end

return ProgressionRules
