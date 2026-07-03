local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LevelTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("LevelTheta"))
local RebirthRules = require(script.Parent.RebirthRules)

local LevelRules = {}

local requiredExpByLevel = {}
local maxConfiguredLevel = 1

-- 初始化 requiredExpByLevel 表格，存储每个等级所需的经验值
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

-- 规范化等级值，确保等级不低于1
local function normalizeLevel(level)
	return math.max(1, math.floor(tonumber(level) or 1))
end

-- 获取指定等级所需的经验值，如果等级超过配置的最大等级，则使用线性增长公式计算
function LevelRules.GetRequiredExp(level)
	level = normalizeLevel(level)

	local configuredExp = requiredExpByLevel[level]
	if configuredExp then
		return configuredExp
	end

	local lastConfiguredExp = requiredExpByLevel[maxConfiguredLevel] or 0
	local extraLevels = level - maxConfiguredLevel
	return lastConfiguredExp + extraLevels * extraLevels * 1000
end

-- 获取指定重生次数下的最大等级
function LevelRules.GetMaxLevel(rebirthCount)
	return RebirthRules.GetMaxLevel(rebirthCount)
end

-- 获取指定重生次数下的最大经验值
function LevelRules.GetMaxExp(rebirthCount)
	return LevelRules.GetRequiredExp(LevelRules.GetMaxLevel(rebirthCount))
end

-- 计算玩家的等级，根据经验值和重生次数进行计算
function LevelRules.CalculateLevel(exp, rebirthCount)
	exp = math.max(0, tonumber(exp) or 0)

	local maxLevel = LevelRules.GetMaxLevel(rebirthCount)
	local level = 1

	for currentLevel = 1, maxLevel do
		if exp >= LevelRules.GetRequiredExp(currentLevel) then
			level = currentLevel
		else
			break
		end
	end

	return level
end

-- 规范化经验值，确保经验值不低于0且不超过当前重生次数下的最大经验值
function LevelRules.ClampExp(exp, rebirthCount)
	local maxExp = LevelRules.GetMaxExp(rebirthCount)
	return math.max(0, math.min(tonumber(exp) or 0, maxExp))
end

-- 检查玩家是否可以进行重生，条件是当前等级达到最大等级
function LevelRules.CanRebirth(progressState)
	if not progressState then
		return false
	end

	return LevelRules.CalculateLevel(progressState.Exp, progressState.RebirthCount)
		>= LevelRules.GetMaxLevel(progressState.RebirthCount)
end

return LevelRules
