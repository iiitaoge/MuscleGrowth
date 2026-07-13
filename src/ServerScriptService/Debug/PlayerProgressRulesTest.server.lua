local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

if not RunService:IsStudio() then
	return
end

local PlayerProgressRules = require(
	ServerScriptService
		:WaitForChild("T")
		:WaitForChild("Rules")
		:WaitForChild("PlayerProgressRules")
)

local initialState = PlayerProgressRules.CreateInitialState()
assert(type(initialState) == "table", "Initial player progress must be a table")
assert(initialState.Strength >= 0, "Initial Strength must be non-negative")
assert(initialState.Trophies >= 0, "Initial Trophies must be non-negative")
assert(initialState.RebirthCount >= 0, "Initial RebirthCount must be non-negative")

local missingFields = PlayerProgressRules.NormalizePersistedState({})
assert(missingFields.CurrentBarbellId == initialState.CurrentBarbellId, "Missing barbell must use the initial value")
assert(
	missingFields.NextPetInstanceId == initialState.NextPetInstanceId,
	"Missing next pet instance id must use the initial value"
)

local invalidState = PlayerProgressRules.NormalizePersistedState({
	Strength = 0 / 0,
	Trophies = math.huge,
	Exp = 1000000000,
	RebirthCount = -4.8,
	CurrentBarbellId = "MissingBarbell",
	OwnedPets = {
		["1"] = {
			InstanceId = "1",
			PetTypeId = "Pet1_1",
		},
		invalid = {
			InstanceId = "invalid",
			PetTypeId = "Pet1_1",
		},
	},
	EquippedPetInstanceIds = { "1", "1", "999" },
	NextPetInstanceId = 0 / 0,
	UnknownField = "must be dropped",
})

assert(invalidState.Strength == initialState.Strength, "NaN Strength must use the initial value")
assert(invalidState.Trophies == initialState.Trophies, "Infinite Trophies must use the initial value")
assert(invalidState.RebirthCount == 0, "RebirthCount must be a non-negative integer")
assert(invalidState.CurrentBarbellId == initialState.CurrentBarbellId, "Invalid barbell must use the initial value")
assert(invalidState.OwnedPets["1"] ~= nil, "Valid owned pet must be preserved")
assert(invalidState.OwnedPets.invalid == nil, "Invalid pet instance id must be removed")
assert(invalidState.EquippedPetInstanceIds[1] == "1", "Owned pet may remain equipped")
assert(invalidState.EquippedPetInstanceIds[2] == 0, "Duplicate equipped pet must be cleared")
assert(invalidState.EquippedPetInstanceIds[3] == 0, "Missing equipped pet must be cleared")
assert(invalidState.UnknownField == nil, "Unknown progress fields must be dropped")

print("[PlayerProgressRulesTest] passed")
