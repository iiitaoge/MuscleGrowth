local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

if not RunService:IsStudio() then
	return
end

local DataAdapter = require(
	StarterPlayer:WaitForChild("StarterPlayerScripts")
		:WaitForChild("T")
		:WaitForChild("PetInventory")
		:WaitForChild("DataAdapter")
)
local TestHarness = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("Testing"):WaitForChild("TestHarness"))

local test = TestHarness.New("PetInventoryDataAdapter")

local snapshots = {
	{ InstanceId = "10", Multiplier = 2, Image = "" },
	{ InstanceId = "3", Multiplier = 5, Image = "" },
	{ InstanceId = "2", Multiplier = 5, Image = "" },
}
local models = DataAdapter.BuildOwnedPetModels(snapshots, { ["3"] = true })

test:Equal("highest multiplier first", models[1].InstanceId, "2")
test:Equal("same multiplier uses numeric instance id", models[2].InstanceId, "3")
test:Equal("lower multiplier last", models[3].InstanceId, "10")
test:Equal("source snapshot order is unchanged", snapshots[1].InstanceId, "10")
test:Check("selection follows instance after sorting", models[2].IsSelected == true)

local selectedIds = DataAdapter.BuildSelectedInstanceIdList({
	["10"] = true,
	["2"] = true,
	["3"] = false,
})
test:Equal("selected ids use numeric order first", selectedIds[1], "2")
test:Equal("selected ids use numeric order second", selectedIds[2], "10")
test:Equal("false selections are excluded", #selectedIds, 2)

local equippedIds = DataAdapter.BuildEquippedInstanceIdSet({
	{ SlotIndex = 1, InstanceId = "3", PetTypeId = "Pet1_1" },
	{ SlotIndex = 2, InstanceId = 0 },
})
test:Check("equipped pet is included", equippedIds["3"] == true)
test:Check("empty slot is excluded", equippedIds["0"] ~= true)

assert(test:Summary(), "PetInventoryDataAdapter tests failed.")
