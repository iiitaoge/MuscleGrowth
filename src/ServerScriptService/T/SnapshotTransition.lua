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
	snapshot.Trophies = progressState.Trophies or 0
	snapshot.Level = ProgressionRules.CalculateLevel(progressState.Exp, rebirthCount)
	snapshot.MaxLevel = ProgressionRules.GetMaxLevel(rebirthCount)
	snapshot.MaxExp = ProgressionRules.GetMaxExp(rebirthCount)
	snapshot.CanRebirth = ProgressionRules.CanRebirth(progressState)
	snapshot.RebirthMultiplier = ProgressionRules.GetRebirthMultiplier(rebirthCount)
	snapshot.BarbellMultiplier = ProgressionRules.GetBarbellMultiplier(progressState.CurrentBarbellId)
	snapshot.BarbellRequiredTrophies = ProgressionRules.GetBarbellRequiredTrophies(progressState.CurrentBarbellId)
	snapshot.PetMultiplier = ProgressionRules.GetPetMultiplier(progressState.CurrentPetId)
	snapshot.PetRequiredTrophies = ProgressionRules.GetPetRequiredTrophies(progressState.CurrentPetId)

	return snapshot
end

return SnapshotTransition
