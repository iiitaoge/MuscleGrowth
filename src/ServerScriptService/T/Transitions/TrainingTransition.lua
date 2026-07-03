local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("AutoAreaTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.Parent.S.TrainingRuntimeState)
local TrainingAreaObservation = require(script.Parent.Parent.Parent.y.TrainingAreaObservation)
local LevelRules = require(script.Parent.Parent.Rules.LevelRules)
local TrainingGainRules = require(script.Parent.Parent.Rules.TrainingGainRules)

local TrainingTransition = {}

-- 创建运行时数据
local function createInitialRuntimeState()
	return {
		IsMoving = false,	-- 玩家是否正在移动
		AutoAreaContacts = {},	-- 玩家当前接触的自动区域（未来不会有重叠，可以变成一个自动区ID）
		GrowthLoopActive = false,	-- 玩家是否处于增长循环中
		LastPetRollTime = 0,	-- 玩家上次滚动宠物的时间戳（这个功能是干啥的？是防止玩家一直购买宠物吗？）
	}
end

local function normalizeRuntimeState(runtimeState)
	runtimeState = runtimeState or createInitialRuntimeState()
	runtimeState.IsMoving = runtimeState.IsMoving == true

	if type(runtimeState.AutoAreaContacts) ~= "table" then
		runtimeState.AutoAreaContacts = {}
	end

	runtimeState.GrowthLoopActive = runtimeState.GrowthLoopActive == true
	runtimeState.LastPetRollTime = math.max(0, tonumber(runtimeState.LastPetRollTime) or 0)
	return runtimeState
end

-- 获取玩家的运行时数据，如果没有则初始化
local function getRuntimeOrInit(player)
	local runtimeState = TrainingRuntimeState.Get(player)
	if runtimeState then
		return normalizeRuntimeState(runtimeState)
	end

	TrainingRuntimeState.Init(player, createInitialRuntimeState())
	return TrainingRuntimeState.Get(player)
end

local function isAutoAreaUnlocked(progressState, areaConfig)
	if not progressState or not areaConfig then
		return false
	end

	local requiredRebirth = areaConfig.RequiredRebirth or 0
	return progressState.RebirthCount >= requiredRebirth
end

-- 清理无效的自动区域接触（未来会被淘汰：从地图上确保不会重叠）
local function pruneInvalidAutoAreaContacts(player, runtimeState)
	local changed = false

	for areaId in pairs(runtimeState.AutoAreaContacts) do
		if not TrainingAreaObservation.IsPlayerInArea(player, areaId) then
			runtimeState.AutoAreaContacts[areaId] = nil
			changed = true
		end
	end

	if changed then
		TrainingRuntimeState.Set(player, runtimeState)
	end

	return runtimeState
end

local function getBestAutoArea(progressState, runtimeState)
	local bestAreaId = nil
	local bestMultiplier = 1

	for areaId in pairs(runtimeState.AutoAreaContacts) do
		local areaConfig = AutoAreaTheta[areaId]
		if isAutoAreaUnlocked(progressState, areaConfig) then
			local multiplier = tonumber(areaConfig.Multiplier) or 1
			if not bestAreaId or multiplier > bestMultiplier then
				bestAreaId = areaId
				bestMultiplier = multiplier
			end
		end
	end

	return bestAreaId, bestMultiplier
end

-- 检测是否需要增长
local function getGrowthDecision(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, 1
	end

	local runtimeState = getRuntimeOrInit(player)
	pruneInvalidAutoAreaContacts(player, runtimeState)	--清理无效自动区（未来会退役）

	local bestAreaId, bestMultiplier = getBestAutoArea(progressState, runtimeState)	--获取最佳自动区，未来会退役
	local shouldGrow = runtimeState.IsMoving or bestAreaId ~= nil	--检测是否正在移动-是否处于自动区

	return shouldGrow, bestMultiplier
end

-- 设置增长状态（激活，停止）
local function setGrowthLoopActive(player, isActive)
	local runtimeState = TrainingRuntimeState.Get(player)
	if not runtimeState then
		return
	end

	runtimeState.GrowthLoopActive = isActive == true
	TrainingRuntimeState.Set(player, runtimeState)
end

local function applyTrainingGains(player, progressState, strengthGain, expGain)
	local nextProgressState = table.clone(progressState)

	nextProgressState.Strength = math.max(0, nextProgressState.Strength + (strengthGain or 0))
	nextProgressState.Exp = LevelRules.ClampExp(
		nextProgressState.Exp + (expGain or 0),
		nextProgressState.RebirthCount
	)

	PlayerProgressState.Set(player, nextProgressState)
end

-- 设置增长状态为false
function TrainingTransition.StopGrowth(player)
	setGrowthLoopActive(player, false)
end

function TrainingTransition.InitRuntime(player)
	TrainingRuntimeState.Init(player, createInitialRuntimeState())
end

function TrainingTransition.RemoveRuntime(player)
	TrainingTransition.StopGrowth(player)
	TrainingRuntimeState.Remove(player)
end

-- 如果增长状态被激活，则开始执行增长循环
local function startGrowthLoop(player)
	local runtimeState = getRuntimeOrInit(player)
	if runtimeState.GrowthLoopActive then
		return
	end

	runtimeState.GrowthLoopActive = true
	TrainingRuntimeState.Set(player, runtimeState)

	task.spawn(function()
		while true do
			task.wait(1)

			local currentRuntimeState = TrainingRuntimeState.Get(player)
			if not currentRuntimeState or not currentRuntimeState.GrowthLoopActive then
				break
			end

			local shouldGrow, autoAreaMultiplier = getGrowthDecision(player)
			if not shouldGrow then
				TrainingTransition.StopGrowth(player)
				break
			end

			local progressState = PlayerProgressState.Get(player)
			if not progressState then
				TrainingTransition.StopGrowth(player)
				break
			end

			local strengthGain, expGain = TrainingGainRules.CalculateTrainingGainValues(
				progressState,
				autoAreaMultiplier
			)
			applyTrainingGains(player, progressState, strengthGain, expGain)
		end
	end)
end

-- 判断是否正在移动
function TrainingTransition.SetMoving(player, isMoving)
	local runtimeState = getRuntimeOrInit(player)
	runtimeState.IsMoving = isMoving == true
	TrainingRuntimeState.Set(player, runtimeState)
	TrainingTransition.RefreshGrowth(player)
end

-- 进入自动区域
function TrainingTransition.EnterAutoAreaClaim(player, areaId)
	if not TrainingAreaObservation.IsValidAreaId(areaId) then
		return false
	end

	if not TrainingAreaObservation.WaitForPlayerInArea(player, areaId) then
		return false
	end

	local runtimeState = getRuntimeOrInit(player)
	runtimeState.AutoAreaContacts[areaId] = true
	TrainingRuntimeState.Set(player, runtimeState)
	TrainingTransition.RefreshGrowth(player)

	return true
end

-- 离开自动区域
function TrainingTransition.LeaveAutoAreaClaim(player, areaId)
	if type(areaId) ~= "string" then
		return false
	end

	local runtimeState = getRuntimeOrInit(player)
	runtimeState.AutoAreaContacts[areaId] = nil
	TrainingRuntimeState.Set(player, runtimeState)
	TrainingTransition.RefreshGrowth(player)

	return true
end

-- 更新增长状态
function TrainingTransition.RefreshGrowth(player)
	local shouldGrow = getGrowthDecision(player)
	if shouldGrow then
		startGrowthLoop(player)
	else
		TrainingTransition.StopGrowth(player)
	end
end

return TrainingTransition
