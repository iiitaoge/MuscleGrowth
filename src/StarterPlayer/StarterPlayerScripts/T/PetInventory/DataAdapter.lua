-- PetInventory/DataAdapter
-- 把宠物快照和选择状态转换成宠物背包显示模型。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PetSystemTheta"))
local NumberFormatter = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("NumberFormatter"))
local UIContract = require(script.Parent.Parent.UIContract)

local DataAdapter = {}

-- 将倍率数值格式化成宠物卡文本。
local function formatMultiplier(value)
	return "x" .. NumberFormatter.Format(value, 1)
end

-- 统计快照表里的条目数量。
function DataAdapter.GetSnapshotCount(snapshots)
	local count = 0
	for _ in pairs(snapshots) do
		count += 1
	end

	return count
end

-- 读取当前最大装备宠物数量。
function DataAdapter.GetMaxEquippedPets()
	return PetSystemTheta.MaxEquippedPets
end

-- 生成背包宠物卡显示模型列表。
function DataAdapter.BuildOwnedPetModels(petSnapshots, selectedPetInstanceIds)
	local models = {}

	for index, petSnapshot in ipairs(petSnapshots) do
		local instanceId = petSnapshot.InstanceId
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

	for _, petSnapshot in ipairs(equippedSnapshots) do
		if petSnapshot.PetTypeId ~= nil then
			local slotIndex = petSnapshot.SlotIndex
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
	local format = UIContract.GetConfig("PetInventory").EquippedTextFormat
	return string.format(
		format,
		NumberFormatter.Format(equippedCount),
		NumberFormatter.Format(maxEquippedPets)
	)
end

-- 根据拥有宠物快照生成实例 id 集合。
function DataAdapter.BuildOwnedInstanceIdSet(ownedSnapshots)
	local ownedInstanceIds = {} :: {[string]: boolean}

	for _, petSnapshot in ipairs(ownedSnapshots) do
		ownedInstanceIds[petSnapshot.InstanceId] = true
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
		return left < right
	end)

	return instanceIds
end

return DataAdapter
