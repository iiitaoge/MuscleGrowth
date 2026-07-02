local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AutoAreaTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("AutoAreaTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.S.TrainingRuntimeState)
local TrainingAreaObservation = require(script.Parent.Parent.y.TrainingAreaObservation)
local ProgressionRules = require(script.Parent.ProgressionRules)

local TrainingTransition = {}

local function createInitialRuntimeState()
	return {
		IsMoving = false,
		AutoAreaContacts = {},
		GrowthLoopActive = false,
	}
end

local function normalizeRuntimeState(runtimeState)
	runtimeState = runtimeState or createInitialRuntimeState()
	runtimeState.IsMoving = runtimeState.IsMoving == true

	if type(runtimeState.AutoAreaContacts) ~= "table" then
		runtimeState.AutoAreaContacts = {}
	end

	runtimeState.GrowthLoopActive = runtimeState.GrowthLoopActive == true
	return runtimeState
end

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

local function getGrowthDecision(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, 1
	end

	local runtimeState = getRuntimeOrInit(player)
	pruneInvalidAutoAreaContacts(player, runtimeState)

	local bestAreaId, bestMultiplier = getBestAutoArea(progressState, runtimeState)
	local shouldGrow = runtimeState.IsMoving or bestAreaId ~= nil

	return shouldGrow, bestMultiplier
end

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
	nextProgressState.Exp = ProgressionRules.ClampExp(
		nextProgressState.Exp + (expGain or 0),
		nextProgressState.RebirthCount
	)

	PlayerProgressState.Set(player, nextProgressState)
end

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

			local strengthGain, expGain = ProgressionRules.CalculateTrainingGainValues(
				progressState,
				autoAreaMultiplier
			)
			applyTrainingGains(player, progressState, strengthGain, expGain)
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
	local shouldGrow = getGrowthDecision(player)
	if shouldGrow then
		startGrowthLoop(player)
	else
		TrainingTransition.StopGrowth(player)
	end
end

return TrainingTransition
