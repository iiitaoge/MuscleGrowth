local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PetTheta = require(ReplicatedStorage:WaitForChild("theta"):WaitForChild("PetTheta"))

local PetMultiplierRules = require(script.Parent.Parent.Rules.Pet.PetMultiplierRules)
local PetSystemRules = require(script.Parent.Parent.Rules.Pet.PetSystemRules)

local PetSnapshotBuilder = {}

local function getPetInstance(progressState, petInstanceId)
	if not progressState or type(progressState.OwnedPets) ~= "table" then
		return nil
	end

	return progressState.OwnedPets[tostring(petInstanceId)]
end

function PetSnapshotBuilder.GetPetTypeSnapshot(petTypeId)
	local petConfig = PetTheta[petTypeId]
	if type(petConfig) ~= "table" then
		return nil
	end

	return {
		PetTypeId = petTypeId,
		DisplayName = petConfig.DisplayName or petTypeId,
		Rarity = petConfig.Rarity or "Common",
		Multiplier = PetMultiplierRules.GetPetTypeMultiplier(petTypeId),
		ModelName = petConfig.ModelName,
		Image = petConfig.Image,
		RollWeight = math.max(0, tonumber(petConfig.RollWeight) or 0),
	}
end

function PetSnapshotBuilder.GetOwnedPetSnapshots(progressState)
	local ownedPetSnapshots = {}
	local ownedPets = progressState and progressState.OwnedPets
	if type(ownedPets) ~= "table" then
		return ownedPetSnapshots
	end

	for instanceId, petInstance in pairs(ownedPets) do
		if type(petInstance) == "table" and type(petInstance.PetTypeId) == "string" then
			local petSnapshot = PetSnapshotBuilder.GetPetTypeSnapshot(petInstance.PetTypeId)
			if petSnapshot then
				petSnapshot.InstanceId = tostring(petInstance.InstanceId or instanceId)
				table.insert(ownedPetSnapshots, petSnapshot)
			end
		end
	end

	table.sort(ownedPetSnapshots, function(left, right)
		return (tonumber(left.InstanceId) or math.huge) < (tonumber(right.InstanceId) or math.huge)
	end)

	return ownedPetSnapshots
end

function PetSnapshotBuilder.GetEquippedPetSnapshots(progressState)
	local equippedPetSnapshots = {}
	local equippedSlots = progressState and progressState.EquippedPetInstanceIds
	local emptySlot = PetSystemRules.GetEmptyPetSlot()
	local seenInstanceIds = {}

	for slotIndex = 1, PetSystemRules.GetMaxEquippedPets() do
		local petInstanceId = type(equippedSlots) == "table" and equippedSlots[slotIndex] or emptySlot
		local petSnapshot = {
			SlotIndex = slotIndex,
			InstanceId = emptySlot,
		}

		if not PetSystemRules.IsEmptyPetSlot(petInstanceId) then
			local normalizedInstanceId = tostring(petInstanceId)
			local petInstance = getPetInstance(progressState, normalizedInstanceId)
			local typeSnapshot = petInstance
				and not seenInstanceIds[normalizedInstanceId]
				and PetSnapshotBuilder.GetPetTypeSnapshot(petInstance.PetTypeId)

			if typeSnapshot then
				seenInstanceIds[normalizedInstanceId] = true
				typeSnapshot.SlotIndex = slotIndex
				typeSnapshot.InstanceId = normalizedInstanceId
				petSnapshot = typeSnapshot
			end
		end

		table.insert(equippedPetSnapshots, petSnapshot)
	end

	return equippedPetSnapshots
end

return PetSnapshotBuilder
