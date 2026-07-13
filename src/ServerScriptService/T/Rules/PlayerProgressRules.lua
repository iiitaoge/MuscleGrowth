local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("BarbellTheta"))
local PlayerProgressInitialTheta = require(
	theta:WaitForChild("Gameplay"):WaitForChild("PlayerProgressInitialTheta")
)

local LevelRules = require(script.Parent.LevelRules)
local PetStateNormalizer = require(script.Parent.Pet.PetStateNormalizer)
local PetSystemRules = require(script.Parent.Pet.PetSystemRules)

local PlayerProgressRules = {}

local DEFAULT_BARBELL_ID = "T1"

local function finiteNumber(value)
	local numberValue = tonumber(value)
	if numberValue == nil or numberValue ~= numberValue or numberValue == math.huge or numberValue == -math.huge then
		return nil
	end

	return numberValue
end

local function nonNegativeNumber(value, fallback)
	local numberValue = finiteNumber(value)
	if numberValue == nil then
		return fallback
	end

	return math.max(0, numberValue)
end

local function nonNegativeInteger(value, fallback)
	return math.floor(nonNegativeNumber(value, fallback))
end

local function positiveInteger(value, fallback)
	return math.max(1, nonNegativeInteger(value, fallback))
end

local function validBarbellId(value, fallback)
	if type(value) == "string" and BarbellTheta[value] then
		return value
	end

	if type(fallback) == "string" and BarbellTheta[fallback] then
		return fallback
	end

	return DEFAULT_BARBELL_ID
end

local function normalizeOwnedPets(ownedPets)
	local normalizedPets = PetStateNormalizer.NormalizeOwnedPets(ownedPets)
	local safePets = {}

	for instanceId, petInstance in pairs(normalizedPets) do
		local instanceNumber = finiteNumber(instanceId)
		if instanceNumber and instanceNumber >= 1 and instanceNumber == math.floor(instanceNumber) then
			local normalizedInstanceId = tostring(math.floor(instanceNumber))
			safePets[normalizedInstanceId] = {
				InstanceId = normalizedInstanceId,
				PetTypeId = petInstance.PetTypeId,
			}
		end
	end

	return safePets
end

local function normalizeEquippedPets(equippedPets, ownedPets)
	local normalizedSlots = PetStateNormalizer.NormalizeSlots(equippedPets)
	local emptySlot = PetSystemRules.GetEmptyPetSlot()
	local seenInstanceIds = {}

	for slotIndex = 1, PetSystemRules.GetMaxEquippedPets() do
		local slotValue = normalizedSlots[slotIndex]
		local instanceId = tostring(slotValue)
		if PetSystemRules.IsEmptyPetSlot(slotValue)
			or not ownedPets[instanceId]
			or seenInstanceIds[instanceId]
		then
			normalizedSlots[slotIndex] = emptySlot
		else
			seenInstanceIds[instanceId] = true
		end
	end

	return normalizedSlots
end

local function normalizeState(source, fallback)
	local rebirthCount = nonNegativeInteger(source.RebirthCount, fallback.RebirthCount)
	local ownedPetsSource = type(source.OwnedPets) == "table" and source.OwnedPets or fallback.OwnedPets
	local equippedPetsSource = type(source.EquippedPetInstanceIds) == "table"
		and source.EquippedPetInstanceIds
		or fallback.EquippedPetInstanceIds
	local ownedPets = normalizeOwnedPets(ownedPetsSource)
	local nextPetInstanceId = PetStateNormalizer.GetNextPetInstanceId(
		ownedPets,
		positiveInteger(source.NextPetInstanceId, fallback.NextPetInstanceId)
	)

	return {
		Strength = nonNegativeNumber(source.Strength, fallback.Strength),
		Trophies = nonNegativeNumber(source.Trophies, fallback.Trophies),
		Exp = LevelRules.ClampExp(nonNegativeNumber(source.Exp, fallback.Exp), rebirthCount),
		RebirthCount = rebirthCount,
		CurrentBarbellId = validBarbellId(source.CurrentBarbellId, fallback.CurrentBarbellId),
		OwnedPets = ownedPets,
		EquippedPetInstanceIds = normalizeEquippedPets(equippedPetsSource, ownedPets),
		NextPetInstanceId = nextPetInstanceId,
	}
end

function PlayerProgressRules.CreateInitialState()
	local emptyFallback = {
		Strength = 0,
		Trophies = 0,
		Exp = 0,
		RebirthCount = 0,
		CurrentBarbellId = DEFAULT_BARBELL_ID,
		OwnedPets = {},
		EquippedPetInstanceIds = {},
		NextPetInstanceId = 1,
	}

	return normalizeState(PlayerProgressInitialTheta, emptyFallback)
end

function PlayerProgressRules.NormalizePersistedState(state)
	if type(state) ~= "table" then
		return nil
	end

	return normalizeState(state, PlayerProgressRules.CreateInitialState())
end

return PlayerProgressRules
