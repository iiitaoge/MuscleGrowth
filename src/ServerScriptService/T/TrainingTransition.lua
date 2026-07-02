local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("AutoAreaTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.S.TrainingRuntimeState)
local TrainingAreaObservation = require(script.Parent.Parent.y.TrainingAreaObservation)
local ProgressionRules = require(script.Parent.ProgressionRules)

local TrainingTransition = {}

local function getRuntimeOrInit(player)
	local runtimeState = TrainingRuntimeState.Get(player)
	if runtimeState then
		return runtimeState
	end

	TrainingRuntimeState.Init(player)
	return TrainingRuntimeState.Get(player)
end

local function isAutoAreaUnlocked(progressState, areaConfig)
	if not progressState or not areaConfig then
		return false
	end

	local requiredRebirth = areaConfig.RequiredRebirth or 0
	return progressState.RebirthCount >= requiredRebirth
end

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
	local bestAreaConfig = nil
	local bestMultiplier = 1

	for areaId in pairs(runtimeState.AutoAreaContacts) do
		local areaConfig = AutoAreaTheta[areaId]
		if isAutoAreaUnlocked(progressState, areaConfig) then
			local multiplier = tonumber(areaConfig.Multiplier) or 1
			if not bestAreaConfig or multiplier > bestMultiplier then
				bestAreaId = areaId
				bestAreaConfig = areaConfig
				bestMultiplier = multiplier
			end
		end
	end

	return bestAreaId, bestAreaConfig, bestMultiplier
end

local function getGrowthContext(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return nil
	end

	local runtimeState = getRuntimeOrInit(player)
	pruneInvalidAutoAreaContacts(player, runtimeState)

	local bestAreaId, bestAreaConfig, bestMultiplier = getBestAutoArea(progressState, runtimeState)

	return {
		IsMoving = runtimeState.IsMoving,
		AutoAreaId = bestAreaId,
		AutoAreaName = bestAreaConfig and bestAreaConfig.Name or nil,
		AutoAreaMultiplier = bestMultiplier,
		ShouldGrow = runtimeState.IsMoving or bestAreaId ~= nil,
	}
end

local function setGrowthLoopActive(player, isActive)
	local runtimeState = TrainingRuntimeState.Get(player)
	if not runtimeState then
		return
	end

	runtimeState.GrowthLoopActive = isActive == true
	TrainingRuntimeState.Set(player, runtimeState)
end

local function applyTrainingGains(player, progressState, gains)
	local nextProgressState = table.clone(progressState)
	local strengthGain = gains and gains.StrengthGain or 0
	local expGain = gains and gains.ExpGain or 0

	nextProgressState.Strength = math.max(0, nextProgressState.Strength + strengthGain)
	nextProgressState.Exp = ProgressionRules.ClampExp(
		nextProgressState.Exp + expGain,
		nextProgressState.RebirthCount
	)

	PlayerProgressState.Set(player, nextProgressState)
end

function TrainingTransition.StopGrowth(player)
	setGrowthLoopActive(player, false)
end

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

			local context = getGrowthContext(player)
			if not context or not context.ShouldGrow then
				TrainingTransition.StopGrowth(player)
				break
			end

			local progressState = PlayerProgressState.Get(player)
			if not progressState then
				TrainingTransition.StopGrowth(player)
				break
			end

			local gains = ProgressionRules.CalculateTrainingGains(progressState, context)
			applyTrainingGains(player, progressState, gains)
		end
	end)
end

function TrainingTransition.SetMoving(player, isMoving)
	local runtimeState = getRuntimeOrInit(player)
	runtimeState.IsMoving = isMoving == true
	TrainingRuntimeState.Set(player, runtimeState)
	TrainingTransition.RefreshGrowth(player)
end

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

function TrainingTransition.RefreshGrowth(player)
	local context = getGrowthContext(player)
	if context and context.ShouldGrow then
		startGrowthLoop(player)
	else
		TrainingTransition.StopGrowth(player)
	end
end

return TrainingTransition
