local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local LevelTheta = require(theta:WaitForChild("LevelTheta"))
local RebirthTheta = require(theta:WaitForChild("RebirthTheta"))

local RebirthRules = {}

local lastConfiguredRebirthCount = 0

for rebirthCount in pairs(RebirthTheta) do
	if type(rebirthCount) == "number" and rebirthCount > lastConfiguredRebirthCount then
		lastConfiguredRebirthCount = rebirthCount
	end
end

local function normalizeRebirthCount(rebirthCount)
	return math.max(0, math.floor(tonumber(rebirthCount) or 0))
end

local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

function RebirthRules.ResolveRebirthRule(rebirthCount)
	rebirthCount = normalizeRebirthCount(rebirthCount)

	local rule = RebirthTheta[rebirthCount]
	if rule then
		return rule
	end

	local lastRule = RebirthTheta[lastConfiguredRebirthCount]
	if not lastRule then
		return {
			Multiplier = 1,
			MaxLevel = LevelTheta.DefaultMaxLevel,
		}
	end

	local extraRebirths = rebirthCount - lastConfiguredRebirthCount
	return {
		Multiplier = lastRule.Multiplier * (2 ^ extraRebirths),
		MaxLevel = lastRule.MaxLevel + 20 * extraRebirths,
	}
end

function RebirthRules.GetRebirthMultiplier(rebirthCount)
	local rebirthRule = RebirthRules.ResolveRebirthRule(rebirthCount)
	return normalizeMultiplier(rebirthRule and rebirthRule.Multiplier or 1)
end

function RebirthRules.GetMaxLevel(rebirthCount)
	local rebirthRule = RebirthRules.ResolveRebirthRule(rebirthCount)
	if rebirthRule and rebirthRule.MaxLevel then
		return rebirthRule.MaxLevel
	end

	return LevelTheta.DefaultMaxLevel
end

return RebirthRules
