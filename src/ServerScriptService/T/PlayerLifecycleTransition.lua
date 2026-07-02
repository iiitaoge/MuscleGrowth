-- PlayerLifecycleTransition.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerProgressInitialTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PlayerProgressInitialTheta"))

local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingTransition = require(script.Parent.TrainingTransition)

local PlayerLifecycleTransition = {}

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

local function createInitialProgressState()
	return {
		Strength = nonNegativeNumber(PlayerProgressInitialTheta.Strength, 0),
		Exp = nonNegativeNumber(PlayerProgressInitialTheta.Exp, 0),
		RebirthCount = nonNegativeNumber(PlayerProgressInitialTheta.RebirthCount, 0),
		CurrentBarbellId = stringOrFallback(PlayerProgressInitialTheta.CurrentBarbellId, "WoodBarbell"),
		BodyQuality = stringOrFallback(PlayerProgressInitialTheta.BodyQuality, "Normal"),
	}
end

function PlayerLifecycleTransition.Init(player)
	PlayerProgressState.Init(player, createInitialProgressState())
	TrainingTransition.InitRuntime(player)
end

function PlayerLifecycleTransition.Remove(player)
	TrainingTransition.RemoveRuntime(player)
	PlayerProgressState.Remove(player)
end

return PlayerLifecycleTransition
