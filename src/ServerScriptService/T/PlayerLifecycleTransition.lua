local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local TrainingRuntimeState = require(script.Parent.Parent.S.TrainingRuntimeState)
local TrainingTransition = require(script.Parent.TrainingTransition)

local PlayerLifecycleTransition = {}

function PlayerLifecycleTransition.Init(player)
	PlayerProgressState.Init(player)
	TrainingRuntimeState.Init(player)
end

function PlayerLifecycleTransition.Remove(player)
	TrainingTransition.StopGrowth(player)
	TrainingRuntimeState.Remove(player)
	PlayerProgressState.Remove(player)
end

return PlayerLifecycleTransition
