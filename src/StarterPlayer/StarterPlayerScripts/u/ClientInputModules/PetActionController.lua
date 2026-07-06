-- PetActionController
-- 客户端宠物背包动作层，负责装备、卸下、删除和入口刷新。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))

local PetActionController = {}

-- 初始化宠物动作控制器。
function PetActionController.Init(remoteClient, snapshotController, petInventoryView)
	-- 按倍率和实例 id 排序宠物快照。
	local function comparePetsByMultiplier(left, right)
		local leftMultiplier = tonumber(left.Multiplier) or 0
		local rightMultiplier = tonumber(right.Multiplier) or 0
		if leftMultiplier == rightMultiplier then
			return (tonumber(left.InstanceId) or math.huge) < (tonumber(right.InstanceId) or math.huge)
		end

		return leftMultiplier > rightMultiplier
	end

	-- 调用宠物装备 Remote 并刷新快照。
	local function invokePetEquip(petInstanceId, slotIndex)
		return snapshotController.ApplyRemoteResult(remoteClient.SafeInvoke("RequestPetEquip", petInstanceId, slotIndex))
	end

	-- 调用宠物卸下 Remote 并刷新快照。
	local function invokePetUnequip(slotIndex)
		return snapshotController.ApplyRemoteResult(remoteClient.SafeInvoke("RequestPetUnequip", slotIndex))
	end

	-- 读取当前背包并按倍率排序。
	local function getOwnedPetsByBestMultiplier()
		local latestData = snapshotController.GetLatestData()
		local ownedPets = {}
		if type(latestData and latestData.OwnedPetSnapshots) == "table" then
			for _, petSnapshot in ipairs(latestData.OwnedPetSnapshots) do
				if type(petSnapshot) == "table" and type(petSnapshot.InstanceId) == "string" then
					table.insert(ownedPets, petSnapshot)
				end
			end
		end

		table.sort(ownedPets, comparePetsByMultiplier)

		return ownedPets
	end

	-- 装备当前背包中倍率最高的宠物。
	local function equipBest()
		local maxEquippedPets = math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
		local ownedPets = getOwnedPetsByBestMultiplier()

		for slotIndex = 1, maxEquippedPets do
			invokePetUnequip(slotIndex)
		end

		for slotIndex = 1, math.min(maxEquippedPets, #ownedPets) do
			invokePetEquip(ownedPets[slotIndex].InstanceId, slotIndex)
		end
	end

	-- 卸下所有装备槽。
	local function unequipAll()
		local maxEquippedPets = math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
		for slotIndex = 1, maxEquippedPets do
			invokePetUnequip(slotIndex)
		end
	end

	-- 删除背包里当前选中的宠物实例。
	local function deleteSelected(petInstanceIds)
		-- 确保类型为 表 确保表长度 > 0
		if type(petInstanceIds) ~= "table" or #petInstanceIds <= 0 then
			warn("No pets selected")
			return
		end

		snapshotController.ApplyRemoteResult(remoteClient.SafeInvoke("RequestPetDelete", petInstanceIds))
	end

	-- 点击左侧宠物入口时打开面板并刷新快照。
	local function bindPetButton()
		local petButton = petInventoryView.GetPetButton()
		if not petButton then
			return
		end

		-- 打开宠物背包并刷新最新快照。
		local function handlePetButtonActivated()
			petInventoryView.SetOpen(true)
			snapshotController.RefreshFromServer()
		end

		petButton.Activated:Connect(handlePetButtonActivated)
	end

	-- 这个东西会传给 Petinventory 里面的 Controller，相当于给了个引用
	petInventoryView.SetActionHandlers({
		Equip = invokePetEquip,
		Unequip = invokePetUnequip,
		EquipBest = equipBest,
		UnequipAll = unequipAll,
		DeleteSelected = deleteSelected,
	})
	bindPetButton()

	return {}
end

return PetActionController
