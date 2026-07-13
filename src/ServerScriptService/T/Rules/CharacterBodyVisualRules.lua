local LevelRules = require(script.Parent.LevelRules)

local CharacterBodyVisualRules = {}

local RIG_TIER_COUNT = 5

function CharacterBodyVisualRules.ResolveRigIndex(progressState)
	progressState = progressState or {}

	local rebirthCount = math.max(0, math.floor(tonumber(progressState.RebirthCount) or 0))
	local level = LevelRules.CalculateLevel(progressState.Exp, rebirthCount)
	local maxLevel = math.max(1, LevelRules.GetMaxLevel(rebirthCount))
	local rigIndex = math.ceil(level / maxLevel * RIG_TIER_COUNT)

	return math.clamp(rigIndex, 1, RIG_TIER_COUNT)
end

return CharacterBodyVisualRules
