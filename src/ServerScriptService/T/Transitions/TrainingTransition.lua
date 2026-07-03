local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("AutoAreaTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.Parent.S.TrainingRuntimeState)
local TrainingAreaObservation = require(script.Parent.Parent.Parent.y.TrainingAreaObservation)
local LevelRules = require(script.Parent.Parent.Rules.LevelRules)
local TrainingGainRules = require(script.Parent.Parent.Rules.TrainingGainRules)

local TrainingTransition = {}

local MOVE_ACTIVITY_MULTIPLIER = 1

local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

-- 创建运行时数据
local function createInitialRuntimeState()
	return {
		IsMoving = false,	-- 玩家是否正在移动
		CurrentAutoAreaId = nil,	-- 玩家当前服务端确认的单个自动区
		GrowthLoopActive = false,	-- 玩家是否处于增长循环中
		LastPetRollTime = 0,	-- 玩家上次抽宠的时间戳，用于服务端冷却
	}
end

local function normalizeRuntimeState(runtimeState)
	runtimeState = runtimeState or createInitialRuntimeState()
	runtimeState.IsMoving = runtimeState.IsMoving == true

	if not TrainingAreaObservation.IsValidAreaId(runtimeState.CurrentAutoAreaId) then
		runtimeState.CurrentAutoAreaId = nil
	end

	runtimeState.AutoAreaContacts = nil
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

	local rebirthCount = tonumber(progressState.RebirthCount) or 0
	local requiredRebirth = tonumber(areaConfig.RequiredRebirth) or 0
	return rebirthCount >= requiredRebirth
end

local function clearCurrentAutoArea(player, runtimeState)
	if runtimeState.CurrentAutoAreaId == nil then
		return runtimeState
	end

	runtimeState.CurrentAutoAreaId = nil
	TrainingRuntimeState.Set(player, runtimeState)
	return runtimeState
end

local function resolveCurrentAutoArea(player, progressState, runtimeState)
	local areaId = runtimeState.CurrentAutoAreaId
	if areaId == nil then
		return nil, nil
	end

	local areaConfig = AutoAreaTheta[areaId]
	if not areaConfig or not TrainingAreaObservation.IsPlayerInArea(player, areaId) then
		clearCurrentAutoArea(player, runtimeState)
		return nil, nil
	end

	if not isAutoAreaUnlocked(progressState, areaConfig) then
		return nil, nil
	end

	return areaId, normalizeMultiplier(areaConfig.Multiplier)
end

-- 检测是否需要增长
local function getGrowthDecision(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, 1
	end

	local runtimeState = getRuntimeOrInit(player)
	local autoAreaId, autoAreaMultiplier = resolveCurrentAutoArea(player, progressState, runtimeState)

	local shouldGrow = runtimeState.IsMoving or autoAreaId ~= nil
	local activityMultiplier = runtimeState.IsMoving and MOVE_ACTIVITY_MULTIPLIER or 1
	if autoAreaId ~= nil then
		if runtimeState.IsMoving then
			activityMultiplier = math.max(activityMultiplier, autoAreaMultiplier)
		else
			activityMultiplier = autoAreaMultiplier
		end
	end

	return shouldGrow, activityMultiplier
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

			local shouldGrow, activityMultiplier = getGrowthDecision(player)
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
				activityMultiplier
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
	runtimeState.CurrentAutoAreaId = areaId
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
	if runtimeState.CurrentAutoAreaId == areaId then
		runtimeState.CurrentAutoAreaId = nil
		TrainingRuntimeState.Set(player, runtimeState)
	end
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
