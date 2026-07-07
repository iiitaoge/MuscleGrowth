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
local GROWTH_INTERVAL_SECONDS = 1

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
		GrowthLoopActive = false,	-- 玩家是否已有增长调度循环
		NextGrowthAt = nil,	-- 当前训练会话下一次允许增长的时间戳
		GrowthLoopToken = 0,	-- 增长循环版本号，用于让旧循环自动失效
		LastPetRollTime = 0,	-- 玩家上次抽宠的时间戳，用于服务端冷却
	}
end

-- 运行时状态规范化
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
	local nextGrowthAt = tonumber(runtimeState.NextGrowthAt)
	if nextGrowthAt and nextGrowthAt >= 0 then
		runtimeState.NextGrowthAt = nextGrowthAt
	else
		runtimeState.NextGrowthAt = nil
	end
	runtimeState.GrowthLoopToken = math.max(0, math.floor(tonumber(runtimeState.GrowthLoopToken) or 0))
	runtimeState.LastPetRollTime = math.max(0, tonumber(runtimeState.LastPetRollTime) or 0)
	return runtimeState
end

local function isTrainingVisualActive(runtimeState)
	return runtimeState.MoveRequested == true or runtimeState.CurrentAutoAreaId ~= nil
end

local function setRuntimeState(player, runtimeState)
	runtimeState = normalizeRuntimeState(runtimeState)
	TrainingRuntimeState.Set(player, runtimeState)
	PlayerVisualStateSync.SetTrainingActive(player, isTrainingVisualActive(runtimeState))

	return runtimeState
end

-- 获取玩家的运行时数据，如果没有则初始化
local function getRuntimeOrInit(player)
	local runtimeState = TrainingRuntimeState.Get(player)
	if runtimeState then
		return normalizeRuntimeState(runtimeState)
	end

	setRuntimeState(player, createInitialRuntimeState())
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

local function clearCurrentAutoArea(runtimeState)
	if runtimeState.CurrentAutoAreaId == nil then
		return runtimeState
	end

	runtimeState.CurrentAutoAreaId = nil
	return runtimeState
end

local function resolveCurrentAutoArea(player, progressState, runtimeState)
	local areaId = runtimeState.CurrentAutoAreaId
	if areaId == nil then
		return nil, nil
	end

	local areaConfig = AutoAreaTheta[areaId]
	if not areaConfig or not TrainingAreaObservation.IsPlayerInArea(player, areaId) then
		clearCurrentAutoArea(runtimeState)
		return nil, nil
	end

	if not isAutoAreaUnlocked(progressState, areaConfig) then
		return nil, nil
	end

	return areaId, normalizeMultiplier(areaConfig.Multiplier)
end

-- 观察玩家真实移动状态
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

local function writeGrowthDecisionRuntime(player, runtimeState, initialMoveRequested, initialAutoAreaId)
	local latestRuntimeState = TrainingRuntimeState.Get(player)
	if not latestRuntimeState then
		return nil, true
	end

	latestRuntimeState = normalizeRuntimeState(latestRuntimeState)
	local hasExternalRuntimeChange = latestRuntimeState.MoveRequested ~= initialMoveRequested
		or latestRuntimeState.CurrentAutoAreaId ~= initialAutoAreaId

	runtimeState.GrowthLoopActive = latestRuntimeState.GrowthLoopActive
	runtimeState.NextGrowthAt = latestRuntimeState.NextGrowthAt
	runtimeState.GrowthLoopToken = latestRuntimeState.GrowthLoopToken
	runtimeState.LastPetRollTime = latestRuntimeState.LastPetRollTime

	if latestRuntimeState.MoveRequested ~= initialMoveRequested then
		runtimeState.MoveRequested = latestRuntimeState.MoveRequested
		runtimeState.IsMoving = latestRuntimeState.IsMoving
		runtimeState.LastMovementPosition = latestRuntimeState.LastMovementPosition
		runtimeState.LastMovementObservedAt = latestRuntimeState.LastMovementObservedAt
		runtimeState.UnconfirmedMoveChecks = latestRuntimeState.UnconfirmedMoveChecks
	end

	if latestRuntimeState.CurrentAutoAreaId ~= initialAutoAreaId then
		runtimeState.CurrentAutoAreaId = latestRuntimeState.CurrentAutoAreaId
	end

	setRuntimeState(player, runtimeState)
	return runtimeState, hasExternalRuntimeChange
end

-- 检测是否需要增长
local function getGrowthDecision(player)
	-- 读S_r
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, 1, false
	end

	-- 读或者写S_r
	local runtimeState = getRuntimeOrInit(player)
	local initialMoveRequested = runtimeState.MoveRequested
	local initialAutoAreaId = runtimeState.CurrentAutoAreaId
	local autoAreaId, autoAreaMultiplier = resolveCurrentAutoArea(player, progressState, runtimeState)
	local isMoving
	isMoving, runtimeState = observeRequestedMovement(player, runtimeState, autoAreaId)
	local hasExternalRuntimeChange
	runtimeState, hasExternalRuntimeChange = writeGrowthDecisionRuntime(
		player,
		runtimeState,
		initialMoveRequested,
		initialAutoAreaId
	)
	if not runtimeState then
		return false, 1, false
	end
	if hasExternalRuntimeChange then
		return false, 1, runtimeState.MoveRequested or runtimeState.CurrentAutoAreaId ~= nil
	end

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

local function applyTrainingGains(player, progressState, strengthGain, expGain)
	local nextProgressState = table.clone(progressState)

	nextProgressState.Strength = math.max(0, nextProgressState.Strength + (strengthGain or 0))
	nextProgressState.Exp = LevelRules.ClampExp(
		nextProgressState.Exp + (expGain or 0),
		nextProgressState.RebirthCount
	)

	PlayerProgressState.Set(player, nextProgressState)
end

local function isCurrentGrowthLoop(runtimeState, loopToken)
	return runtimeState
		and runtimeState.GrowthLoopActive == true
		and runtimeState.GrowthLoopToken == loopToken
		and runtimeState.NextGrowthAt ~= nil
end

local function clearGrowthLoopState(runtimeState)
	runtimeState.GrowthLoopActive = false
	runtimeState.NextGrowthAt = nil
	runtimeState.GrowthLoopToken = runtimeState.GrowthLoopToken + 1

	return runtimeState
end

local function stopGrowthLoop(player)
	local runtimeState = TrainingRuntimeState.Get(player)
	if not runtimeState then
		return
	end

	runtimeState = normalizeRuntimeState(runtimeState)
	clearGrowthLoopState(runtimeState)
	setRuntimeState(player, runtimeState)
end

local function stopGrowthLoopIfCurrent(player, loopToken)
	local runtimeState = TrainingRuntimeState.Get(player)
	if not runtimeState then
		return false
	end

	runtimeState = normalizeRuntimeState(runtimeState)
	if runtimeState.GrowthLoopToken ~= loopToken then
		return false
	end

	clearGrowthLoopState(runtimeState)
	setRuntimeState(player, runtimeState)
	return true
end

local function scheduleNextGrowthIfCurrent(player, loopToken)
	local runtimeState = TrainingRuntimeState.Get(player)
	if not runtimeState then
		return false
	end

	runtimeState = normalizeRuntimeState(runtimeState)
	if not isCurrentGrowthLoop(runtimeState, loopToken) then
		return false
	end

	runtimeState.NextGrowthAt = os.clock() + GROWTH_INTERVAL_SECONDS
	setRuntimeState(player, runtimeState)
	return true
end

local function runGrowthLoop(player, loopToken)
	while true do
		local runtimeState = TrainingRuntimeState.Get(player)
		if not runtimeState then
			break
		end

		runtimeState = normalizeRuntimeState(runtimeState)
		if not isCurrentGrowthLoop(runtimeState, loopToken) then
			break
		end

		local waitTime = math.max(runtimeState.NextGrowthAt - os.clock(), 0)
		if waitTime > 0 then
			task.wait(waitTime)
		end

		runtimeState = TrainingRuntimeState.Get(player)
		if not runtimeState then
			break
		end

		runtimeState = normalizeRuntimeState(runtimeState)
		if not isCurrentGrowthLoop(runtimeState, loopToken) then
			break
		end

		if os.clock() >= runtimeState.NextGrowthAt then
			local shouldGrow, activityMultiplier, shouldKeepLoopActive = getGrowthDecision(player)

			runtimeState = TrainingRuntimeState.Get(player)
			if not runtimeState then
				break
			end

			runtimeState = normalizeRuntimeState(runtimeState)
			if not isCurrentGrowthLoop(runtimeState, loopToken) then
				break
			end

			if not shouldKeepLoopActive then
				stopGrowthLoopIfCurrent(player, loopToken)
				break
			end

			if shouldGrow then
				local progressState = PlayerProgressState.Get(player)
				if not progressState then
					stopGrowthLoopIfCurrent(player, loopToken)
					break
				end

				local strengthGain, expGain = TrainingGainRules.CalculateTrainingGainValues(
					progressState,
					activityMultiplier
				)
				applyTrainingGains(player, progressState, strengthGain, expGain)
				PlayerVisualStateSync.PublishTrainingGain(player, strengthGain)
			end

			if not scheduleNextGrowthIfCurrent(player, loopToken) then
				break
			end
		end
	end
end

-- 设置增长状态为false
function TrainingTransition.StopGrowth(player)
	stopGrowthLoop(player)
end

function TrainingTransition.InitRuntime(player)
	setRuntimeState(player, createInitialRuntimeState())
end

function TrainingTransition.RemoveRuntime(player)
	TrainingTransition.StopGrowth(player)
	TrainingRuntimeState.Remove(player)
	PlayerVisualStateSync.SetTrainingActive(player, false)
end

-- 如果增长状态被激活，则开始执行增长循环
local function startGrowthLoop(player)
	local runtimeState = getRuntimeOrInit(player)
	if runtimeState.NextGrowthAt == nil then
		runtimeState.NextGrowthAt = os.clock() + GROWTH_INTERVAL_SECONDS
	end

	if runtimeState.GrowthLoopActive then
		setRuntimeState(player, runtimeState)
		return
	end

	runtimeState.GrowthLoopActive = true
	runtimeState.GrowthLoopToken = runtimeState.GrowthLoopToken + 1
	local loopToken = runtimeState.GrowthLoopToken
	setRuntimeState(player, runtimeState)

	task.spawn(function()
		runGrowthLoop(player, loopToken)
	end)
end

-- 判断是否可以移动
function TrainingTransition.SetMoving(player, isMoving)
	local runtimeState = getRuntimeOrInit(player) --获取运行时状态
	local moveRequested = isMoving == true	--获取客户端的移动状态

	--如果客户端事件发送状态和服务端维护的玩家状态一致，无需更改，直接返回
	if runtimeState.MoveRequested == moveRequested then
		return true
	end

	-- 将目前的玩家状态改成事件请求的状态（这里没有防作弊）
	runtimeState.MoveRequested = moveRequested
	-- 如果请求停止移动，就停止移动
	if not moveRequested then
		runtimeState.IsMoving = false
		MovementObservation.Reset(runtimeState)
	end

	-- 设置为开始移动
	setRuntimeState(player, runtimeState)
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
	setRuntimeState(player, runtimeState)
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
		setRuntimeState(player, runtimeState)
	end
	TrainingTransition.RefreshGrowth(player)

	return true
end

-- 更新增长状态
function TrainingTransition.RefreshGrowth(player)
	local _, _, shouldKeepLoopActive = getGrowthDecision(player)
	if shouldKeepLoopActive then
		startGrowthLoop(player)
	else
		TrainingTransition.StopGrowth(player)
	end
end

return TrainingTransition
