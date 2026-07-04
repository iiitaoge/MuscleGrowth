local PlayerProgressState = require(script.Parent.Parent.Parent.S.PlayerProgressState)

local BarbellRules = require(script.Parent.Parent.Rules.BarbellRules)
local LevelRules = require(script.Parent.Parent.Rules.LevelRules)
local PetMultiplierRules = require(script.Parent.Parent.Rules.Pet.PetMultiplierRules)
local PetSnapshotBuilder = require(script.Parent.PetSnapshotBuilder)
local RebirthRules = require(script.Parent.Parent.Rules.RebirthRules)

local PlayerSnapshotBuilder = {}

function PlayerSnapshotBuilder.GetPlayerSnapshot(player)
	local progressState = PlayerProgressState.Get(player)
	if not progressState then
		return nil
	end

	local rebirthCount = progressState.RebirthCount
	local nextRebirthCount = (tonumber(rebirthCount) or 0) + 1
	local snapshot = table.clone(progressState)
	snapshot.Trophies = progressState.Trophies or 0
	snapshot.Level = LevelRules.CalculateLevel(progressState.Exp, rebirthCount)
	snapshot.MaxLevel = LevelRules.GetMaxLevel(rebirthCount)
	snapshot.MaxExp = LevelRules.GetMaxExp(rebirthCount)
	snapshot.NextRebirthCount = nextRebirthCount
	snapshot.NextMaxLevel = LevelRules.GetMaxLevel(nextRebirthCount)
	snapshot.NextMaxExp = LevelRules.GetMaxExp(nextRebirthCount)
	snapshot.CanRebirth = LevelRules.CanRebirth(progressState)
	snapshot.RebirthMultiplier = RebirthRules.GetRebirthMultiplier(rebirthCount)
	snapshot.NextRebirthMultiplier = RebirthRules.GetRebirthMultiplier(nextRebirthCount)
	snapshot.BarbellMultiplier = BarbellRules.GetBarbellMultiplier(progressState.CurrentBarbellId)
	snapshot.BarbellRequiredTrophies = BarbellRules.GetBarbellRequiredTrophies(progressState.CurrentBarbellId)
	snapshot.PetMultiplier = PetMultiplierRules.GetEquippedPetMultiplier(progressState)
	snapshot.OwnedPetSnapshots = PetSnapshotBuilder.GetOwnedPetSnapshots(progressState)
	snapshot.EquippedPetSnapshots = PetSnapshotBuilder.GetEquippedPetSnapshots(progressState)

	return snapshot
end

return PlayerSnapshotBuilder
