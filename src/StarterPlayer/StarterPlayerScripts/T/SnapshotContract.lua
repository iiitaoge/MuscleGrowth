-- SnapshotContract
-- 客户端服务器快照合同检查。服务端数据错了就在入口暴露，不让 UI 层吞掉。

local SnapshotContract = {}

local REQUIRED_NUMBER_FIELDS = {
	"Strength",
	"Trophies",
	"Exp",
	"Level",
	"MaxLevel",
	"MaxExp",
	"RebirthCount",
	"NextRebirthCount",
	"NextMaxLevel",
	"RebirthMultiplier",
	"NextRebirthMultiplier",
	"BarbellMultiplier",
	"PetMultiplier",
}

local function requireTable(value, context)
	assert(type(value) == "table", context .. " must be a table.")
	return value
end

local function requireNumber(value, context)
	assert(type(value) == "number", context .. " must be a number.")
	return value
end

local function requirePositiveNumber(value, context)
	requireNumber(value, context)
	assert(value > 0, context .. " must be greater than 0.")
	return value
end

local function requireString(value, context)
	assert(type(value) == "string", context .. " must be a string.")
	return value
end

local function requireBoolean(value, context)
	assert(type(value) == "boolean", context .. " must be a boolean.")
	return value
end

local function validatePetDisplaySnapshot(snapshot, context)
	requireString(snapshot.InstanceId, context .. ".InstanceId")
	requireString(snapshot.PetTypeId, context .. ".PetTypeId")
	requireNumber(snapshot.Multiplier, context .. ".Multiplier")
	requireString(snapshot.Image, context .. ".Image")
end

local function validateOwnedPetSnapshot(snapshot, index)
	local context = "Player snapshot.OwnedPetSnapshots[" .. tostring(index) .. "]"
	requireTable(snapshot, context)
	validatePetDisplaySnapshot(snapshot, context)
end

local function validateEquippedPetSnapshot(snapshot, index)
	local context = "Player snapshot.EquippedPetSnapshots[" .. tostring(index) .. "]"
	requireTable(snapshot, context)
	requireNumber(snapshot.SlotIndex, context .. ".SlotIndex")

	if snapshot.PetTypeId ~= nil then
		validatePetDisplaySnapshot(snapshot, context)
	end
end

function SnapshotContract.Validate(data)
	requireTable(data, "Player snapshot")

	for _, fieldName in ipairs(REQUIRED_NUMBER_FIELDS) do
		requireNumber(data[fieldName], "Player snapshot." .. fieldName)
	end

	requirePositiveNumber(data.MaxLevel, "Player snapshot.MaxLevel")
	requirePositiveNumber(data.MaxExp, "Player snapshot.MaxExp")
	requirePositiveNumber(data.NextMaxLevel, "Player snapshot.NextMaxLevel")
	requireString(data.CurrentBarbellId, "Player snapshot.CurrentBarbellId")
	requireBoolean(data.CanRebirth, "Player snapshot.CanRebirth")

	requireTable(data.OwnedPetSnapshots, "Player snapshot.OwnedPetSnapshots")
	requireTable(data.EquippedPetSnapshots, "Player snapshot.EquippedPetSnapshots")

	for index, snapshot in ipairs(data.OwnedPetSnapshots) do
		validateOwnedPetSnapshot(snapshot, index)
	end

	for index, snapshot in ipairs(data.EquippedPetSnapshots) do
		validateEquippedPetSnapshot(snapshot, index)
	end

	return data
end

return SnapshotContract
