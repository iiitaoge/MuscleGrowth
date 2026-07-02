local PlayerProgressState = require(script.Parent.Parent.S.PlayerProgressState)
local ProgressionRules = require(script.Parent.ProgressionRules)

local SnapshotTransition = {}

function SnapshotTransition.GetPlayerSnapshot(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return nil
	end

	local rebirthCount = progressState.RebirthCount
	local snapshot = table.clone(progressState)
	snapshot.Level = ProgressionRules.CalculateLevel(progressState.Exp, rebirthCount)
	snapshot.MaxLevel = ProgressionRules.GetMaxLevel(rebirthCount)
	snapshot.MaxExp = ProgressionRules.GetMaxExp(rebirthCount)
	snapshot.CanRebirth = ProgressionRules.CanRebirth(progressState)

	return snapshot
end

return SnapshotTransition
