local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("AutoAreaTheta"))

local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.Parent.S.TrainingRuntimeState)
local MovementObservation = require(script.Parent.Parent.Parent.y.MovementObservation)
local TrainingAreaObservation = require(script.Parent.Parent.Parent.y.TrainingAreaObservation)
local LevelRules = require(script.Parent.Parent.Rules.LevelRules)
local TrainingGainRules = require(script.Parent.Parent.Rules.TrainingGainRules)
local PlayerVisualStateSync = require(script.Parent.Parent.WorldSync.PlayerVisualStateSync)

local TrainingTransition = {}

local MOVE_ACTIVITY_MULTIPLIER = 1
local MAX_UNCONFIRMED_MOVE_CHECKS = 3

local function normalizeMultiplier(multiplier)
	multiplier = tonumber(multiplier) or 1
	return math.max(multiplier, 0)
end

-- 创建运行时数据
local function createInitialRuntimeState()
	return {
		MoveRequested = false,	-- 客户端是否请求开始移动训练检测
		IsMoving = false,	-- 服务端确认玩家是否正在移动
		LastMovementPosition = nil,
		LastMovementObservedAt = 0,
		UnconfirmedMoveChecks = 0,
		CurrentAutoAreaId = nil,	-- 玩家当前服务端确认的单个自动区
		GrowthLoopActive = false,	-- 玩家是否处于增长循环中
		LastPetRollTime = 0,	-- 玩家上次抽宠的时间戳，用于服务端冷却
	}
end

local function normalizeRuntimeState(runtimeState)
	runtimeState = runtimeState or createInitialRuntimeState()
	runtimeState.MoveRequested = runtimeState.MoveRequested == true
	runtimeState.IsMoving = runtimeState.IsMoving == true
	if typeof(runtimeState.LastMovementPosition) ~= "Vector3" then
		runtimeState.LastMovementPosition = nil
	end
	runtimeState.LastMovementObservedAt = math.max(0, tonumber(runtimeState.LastMovementObservedAt) or 0)
	runtimeState.UnconfirmedMoveChecks = math.max(0, math.floor(tonumber(runtimeState.UnconfirmedMoveChecks) or 0))

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

local function observeRequestedMovement(player, runtimeState, autoAreaId)
	if runtimeState.MoveRequested then
		local isMoving
		isMoving, runtimeState = MovementObservation.Observe(player, runtimeState)

		if not isMoving
			and autoAreaId == nil
			and runtimeState.UnconfirmedMoveChecks >= MAX_UNCONFIRMED_MOVE_CHECKS
		then
			runtimeState.MoveRequested = false
			runtimeState.IsMoving = false
			MovementObservation.Reset(runtimeState)
		end

		return isMoving, runtimeState
	end

	runtimeState.IsMoving = false
	MovementObservation.Reset(runtimeState)
	return false, runtimeState
end

-- 检测是否需要增长
local function getGrowthDecision(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, 1, false
	end

	local runtimeState = getRuntimeOrInit(player)
	local autoAreaId, autoAreaMultiplier = resolveCurrentAutoArea(player, progressState, runtimeState)
	local isMoving
	isMoving, runtimeState = observeRequestedMovement(player, runtimeState, autoAreaId)
	TrainingRuntimeState.Set(player, runtimeState)

	local shouldGrow = isMoving or autoAreaId ~= nil
	local shouldKeepLoopActive = runtimeState.MoveRequested or autoAreaId ~= nil
	local activityMultiplier = isMoving and MOVE_ACTIVITY_MULTIPLIER or 1
	if autoAreaId ~= nil then
		if isMoving then
			activityMultiplier = math.max(activityMultiplier, autoAreaMultiplier)
		else
			activityMultiplier = autoAreaMultiplier
		end
	end

	return shouldGrow, activityMultiplier, shouldKeepLoopActive
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
	PlayerVisualStateSync.SetTrainingActive(player, false)
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

			-- 玩家可能不符合增长循环了（停止移动 不在自动区）
			local currentRuntimeState = TrainingRuntimeState.Get(player)
			if not currentRuntimeState or not currentRuntimeState.GrowthLoopActive then
				break
			end
			
			-- 玩家需要被停止增长，更改增长状态为停止
			local shouldGrow, activityMultiplier, shouldKeepLoopActive = getGrowthDecision(player)
			PlayerVisualStateSync.SetTrainingActive(player, shouldGrow)
			if not shouldKeepLoopActive then
				TrainingTransition.StopGrowth(player)
				break
			end

			if shouldGrow then
				--玩家可能在增长循环中直接退出游戏
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
		end
	end)
end

-- 判断是否正在移动
function TrainingTransition.SetMoving(player, isMoving)
	local runtimeState = getRuntimeOrInit(player)
	local moveRequested = isMoving == true
	if runtimeState.MoveRequested == moveRequested then
		return true
	end

	runtimeState.MoveRequested = moveRequested
	if not moveRequested then
		runtimeState.IsMoving = false
		MovementObservation.Reset(runtimeState)
	end

	TrainingRuntimeState.Set(player, runtimeState)
	TrainingTransition.RefreshGrowth(player)

	return true
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
	local shouldGrow, _, shouldKeepLoopActive = getGrowthDecision(player)
	PlayerVisualStateSync.SetTrainingActive(player, shouldGrow)
	if shouldKeepLoopActive then
		startGrowthLoop(player)
	else
		TrainingTransition.StopGrowth(player)
	end
end

return TrainingTransition
