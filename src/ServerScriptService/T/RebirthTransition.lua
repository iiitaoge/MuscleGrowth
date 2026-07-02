local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local ProgressionRules = require(script.Parent.ProgressionRules)
local SnapshotTransition = require(script.Parent.SnapshotTransition)

local RebirthTransition = {}

function RebirthTransition.TryApply(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	if not ProgressionRules.CanRebirth(progressState) then
		return false, "Current max level has not been reached"
	end

	local nextProgressState = table.clone(progressState)
	nextProgressState.RebirthCount += 1
	nextProgressState.Strength = 0
	nextProgressState.Exp = 0

	PlayerProgressState.Set(player, nextProgressState)

	return true, "Rebirth succeeded"
end

function RebirthTransition.Request(player)
	local success, message = RebirthTransition.TryApply(player)

	return {
		Success = success,
		Message = message,
		Data = SnapshotTransition.GetPlayerSnapshot(player),
	}
end

return RebirthTransition
