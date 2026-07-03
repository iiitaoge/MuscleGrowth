local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)
local LevelRules = require(script.Parent.Parent.Rules.LevelRules)
local PlayerSnapshotBuilder = require(script.Parent.Parent.Snapshots.PlayerSnapshotBuilder)

local RebirthTransition = {}

function RebirthTransition.TryApply(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return false, "Player data does not exist"
	end

	if not LevelRules.CanRebirth(progressState) then
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
		Data = PlayerSnapshotBuilder.GetPlayerSnapshot(player),
	}
end

return RebirthTransition
