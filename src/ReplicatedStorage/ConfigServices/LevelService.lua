local LevelConfig = require(script.Parent.Parent.Configs.LevelConfig)

local LevelService = {}

local requiredExpByLevel = {}
local maxConfiguredLevel = 1

for _, levelInfo in ipairs(LevelConfig.RequiredExp) do
	local level = levelInfo.Level
	local requiredExp = tonumber(levelInfo.Exp)

	if level and requiredExp then
		requiredExpByLevel[level] = requiredExp

		if level > maxConfiguredLevel then
			maxConfiguredLevel = level
		end
	end
end

function LevelService.GetRequiredExp(level)
	local configuredExp = requiredExpByLevel[level]
	if configuredExp then
		return configuredExp
	end

	local lastConfiguredExp = requiredExpByLevel[maxConfiguredLevel] or 0
	local extraLevels = level - maxConfiguredLevel

	return lastConfiguredExp + extraLevels * extraLevels * 1000
end

function LevelService.CalculateLevel(exp, maxLevel)
	local level = 1

	for currentLevel = 1, maxLevel do
		if exp >= LevelService.GetRequiredExp(currentLevel) then
			level = currentLevel
		else
			break
		end
	end

	return level
end

function LevelService.GetMaxLevelRequiredExp(maxLevel)
	return LevelService.GetRequiredExp(maxLevel)
end

function LevelService.AddExp(playerData, expGain)
	local maxExp = LevelService.GetMaxLevelRequiredExp(playerData.MaxLevel)

	if playerData.Level >= playerData.MaxLevel then
		playerData.Exp = maxExp
		return
	end

	playerData.Exp = math.min(playerData.Exp + expGain, maxExp)
	playerData.Level = LevelService.CalculateLevel(playerData.Exp, playerData.MaxLevel)
end

return LevelService
