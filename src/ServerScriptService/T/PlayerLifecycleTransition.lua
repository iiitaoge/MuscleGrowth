-- PlayerLifecycleTransition.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProgressInitialTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PlayerProgressInitialTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingTransition = require(script.Parent.TrainingTransition)

local PlayerLifecycleTransition = {}

--下面两个函数都是为了将传入值规范化

-- 把传进来的值尽可能转换成非负数，如果失败则保持默认
local function nonNegativeNumber(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(0, numberValue)
end

-- 把传进来的值尽可能转换成规范字符串，如果失败则保持默认
local function stringOrFallback(value, fallback)
	if type(value) == "string" then
		return value
	end

	return fallback
end

-- 创建初始的玩家进度状态，确保所有字段都符合预期的类型和范围
local function createInitialProgressState()
	return {
		Strength = nonNegativeNumber(PlayerProgressInitialTheta.Strength, 0),
		Trophies = nonNegativeNumber(PlayerProgressInitialTheta.Trophies, 0),
		Exp = nonNegativeNumber(PlayerProgressInitialTheta.Exp, 0),
		RebirthCount = nonNegativeNumber(PlayerProgressInitialTheta.RebirthCount, 0),
		CurrentBarbellId = stringOrFallback(PlayerProgressInitialTheta.CurrentBarbellId, "T1"),
		CurrentPetId = stringOrFallback(PlayerProgressInitialTheta.CurrentPetId, "P1"),
		BodyQuality = stringOrFallback(PlayerProgressInitialTheta.BodyQuality, "Normal"),
	}
end

-- 初始化玩家进度状态和训练状态
function PlayerLifecycleTransition.Init(player)
	PlayerProgressState.Init(player, createInitialProgressState())		--进度状态
	TrainingTransition.InitRuntime(player)		--训练状态
end
-- 移除玩家进度状态和训练状态
function PlayerLifecycleTransition.Remove(player)
	TrainingTransition.RemoveRuntime(player)
	PlayerProgressState.Remove(player)
end

return PlayerLifecycleTransition
