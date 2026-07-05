-- PetInventory/DataAdapter
-- 把宠物快照和选择状态转换成宠物背包显示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetInventoryPanelTheta = require(theta:WaitForChild("PetInventoryPanelTheta"))
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))

local DataAdapter = {}

-- 将倍率数值格式化成宠物卡文本。
local function formatMultiplier(value)
	local numberValue = tonumber(value) or 1
	return "x" .. string.format("%.1f", numberValue)
end

-- 统计快照表里的条目数量。
function DataAdapter.GetSnapshotCount(snapshots)
	if type(snapshots) ~= "table" then
		return 0
	end

	local count = 0
	for _ in pairs(snapshots) do
		count += 1
	end

	return count
end

-- 读取当前最大装备宠物数量。
function DataAdapter.GetMaxEquippedPets()
	return math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
end

-- 生成背包宠物卡显示模型列表。
function DataAdapter.BuildOwnedPetModels(petSnapshots, selectedPetInstanceIds)
	local models = {}
	if type(petSnapshots) ~= "table" then
		return models
	end

	for index, petSnapshot in ipairs(petSnapshots) do
		local instanceId = tostring(petSnapshot.InstanceId or index)
		table.insert(models, {
			Name = "Pet_" .. instanceId,
			LayoutOrder = index,
			InstanceId = instanceId,
			Icon = petSnapshot.Image,
			MultiplierText = formatMultiplier(petSnapshot.Multiplier),
			IsSelected = selectedPetInstanceIds[instanceId] == true,
			Snapshot = petSnapshot,
		})
	end

	return models
end

-- 生成已装备宠物卡显示模型列表。
function DataAdapter.BuildEquippedPetModels(equippedSnapshots)
	local models = {}
	if type(equippedSnapshots) ~= "table" then
		return models
	end

	for index, petSnapshot in ipairs(equippedSnapshots) do
		if type(petSnapshot) == "table" and type(petSnapshot.PetTypeId) == "string" then
			local slotIndex = tonumber(petSnapshot.SlotIndex) or index
			table.insert(models, {
				Name = "Equipped_" .. tostring(slotIndex),
				LayoutOrder = slotIndex,
				SlotIndex = slotIndex,
				Icon = petSnapshot.Image,
				MultiplierText = formatMultiplier(petSnapshot.Multiplier),
				Snapshot = petSnapshot,
			})
		end
	end

	return models
end

-- 生成装备数量文本。
function DataAdapter.BuildEquippedText(equippedCount, maxEquippedPets)
	local format = PetInventoryPanelTheta.EquippedTextFormat or "Equipped ( %d/%d Pets)"
	return string.format(format, equippedCount, maxEquippedPets)
end

-- 根据拥有宠物快照生成实例 id 集合。
function DataAdapter.BuildOwnedInstanceIdSet(ownedSnapshots)
	local ownedInstanceIds = {} :: {[string]: boolean}
	if type(ownedSnapshots) ~= "table" then
		return ownedInstanceIds
	end

	for _, petSnapshot in ipairs(ownedSnapshots) do
		if type(petSnapshot) == "table" and petSnapshot.InstanceId ~= nil then
			ownedInstanceIds[tostring(petSnapshot.InstanceId)] = true
		end
	end

	return ownedInstanceIds
end

-- 将选中集合转换成稳定排序的实例 id 列表。
function DataAdapter.BuildSelectedInstanceIdList(selectedPetInstanceIds)
	local instanceIds = {}
	for instanceId in pairs(selectedPetInstanceIds) do
		table.insert(instanceIds, instanceId)
	end

	table.sort(instanceIds, function(left, right)
		return (tonumber(left) or math.huge) < (tonumber(right) or math.huge)
	end)

	return instanceIds
end

return DataAdapter
