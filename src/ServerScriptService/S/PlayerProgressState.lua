local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PlayerProgressInitialTheta = require(theta:WaitForChild("PlayerProgressInitialTheta"))

local PlayerProgressState = {}
local states = {}

local function nonNegativeNumber(value, fallback)
	local numberValue = tonumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(0, numberValue)
end

local function stringOrFallback(value, fallback)
	if type(value) == "string" then
		return value
	end

	return fallback
end

local function cloneProgressState(state)
	state = state or PlayerProgressInitialTheta

	return {
		Strength = nonNegativeNumber(state.Strength, PlayerProgressInitialTheta.Strength),
		Exp = nonNegativeNumber(state.Exp, PlayerProgressInitialTheta.Exp),
		RebirthCount = nonNegativeNumber(state.RebirthCount, PlayerProgressInitialTheta.RebirthCount),
		CurrentBarbellId = stringOrFallback(state.CurrentBarbellId, PlayerProgressInitialTheta.CurrentBarbellId),
		BodyQuality = stringOrFallback(state.BodyQuality, PlayerProgressInitialTheta.BodyQuality),
	}
end

function PlayerProgressState.Init(player)
	states[player] = cloneProgressState(PlayerProgressInitialTheta)
end

function PlayerProgressState.Remove(player)
	states[player] = nil
end

function PlayerProgressState.Get(player)
	local state = states[player]
	if not state then
		return nil
	end

	return cloneProgressState(state)
end

function PlayerProgressState.Set(player, nextState)
	if not nextState then
		states[player] = nil
		return
	end

	states[player] = cloneProgressState(nextState)
end

return PlayerProgressState
