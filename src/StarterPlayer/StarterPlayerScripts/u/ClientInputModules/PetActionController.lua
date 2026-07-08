-- PetActionController
-- 客户端宠物背包动作层，负责装备、卸下、删除和入口刷新。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PetSystemTheta"))

local PetActionController = {}

-- 初始化宠物动作控制器。
function PetActionController.Init(snapshotController, petInventoryView)
	local isOpeningInventory = false

	-- 按倍率和实例 id 排序宠物快照。
	local function comparePetsByMultiplier(left, right)
		local leftMultiplier = tonumber(left.Multiplier) or 0
		local rightMultiplier = tonumber(right.Multiplier) or 0
		if leftMultiplier == rightMultiplier then
			return (tonumber(left.InstanceId) or math.huge) < (tonumber(right.InstanceId) or math.huge)
		end

		return leftMultiplier > rightMultiplier
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
		local latestPetResult = nil

		for slotIndex = 1, maxEquippedPets do
			latestPetResult = snapshotController.InvokeAction("RequestPetUnequip", slotIndex) or latestPetResult
		end

		for slotIndex = 1, math.min(maxEquippedPets, #ownedPets) do
			latestPetResult = snapshotController.InvokeAction(
				"RequestPetEquip",
				ownedPets[slotIndex].InstanceId,
				slotIndex
			) or latestPetResult
		end

		if latestPetResult and latestPetResult.Data then
			petInventoryView.Refresh(latestPetResult.Data)
		end
	end

	-- 卸下所有装备槽。
	local function unequipAll()
		local maxEquippedPets = math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
		local latestPetResult = nil

		for slotIndex = 1, maxEquippedPets do
			latestPetResult = snapshotController.InvokeAction("RequestPetUnequip", slotIndex) or latestPetResult
		end

		if latestPetResult and latestPetResult.Data then
			petInventoryView.Refresh(latestPetResult.Data)
		end
	end

	-- 删除给定宠物实例列表。
	local function deletePets(petInstanceIds)
		-- 确保类型为 表 确保表长度 > 0
		if type(petInstanceIds) ~= "table" or #petInstanceIds <= 0 then
			warn("No pets to delete")
			return
		end

		local result = snapshotController.InvokeAction("RequestPetDelete", petInstanceIds)
		if result and result.Data then
			petInventoryView.Refresh(result.Data)
		end

		return result
	end

	-- 装备单只宠物并刷新背包。
	local function equipPet(petInstanceId, slotIndex)
		local result = snapshotController.InvokeAction("RequestPetEquip", petInstanceId, slotIndex)
		if result and result.Data then
			petInventoryView.Refresh(result.Data)
		end

		return result
	end

	-- 卸下单个装备槽并刷新背包。
	local function unequipPet(slotIndex)
		local result = snapshotController.InvokeAction("RequestPetUnequip", slotIndex)
		if result and result.Data then
			petInventoryView.Refresh(result.Data)
		end

		return result
	end

	-- 打开宠物背包：先拿数据并渲染，再显示面板。
	local function openInventory()
		if petInventoryView.IsOpen() or isOpeningInventory then
			return
		end

		isOpeningInventory = true
		local data = snapshotController.RefreshFromServer()
		isOpeningInventory = false

		if data then
			petInventoryView.Refresh(data)
			petInventoryView.SetOpen(true)
		end
	end

	-- 点击左侧宠物入口时打开面板并刷新快照。
	local function bindPetButton()
		local petButton = petInventoryView.GetPetButton()
		if not petButton then
			return
		end

		-- 打开宠物背包并刷新最新快照。
		local function handlePetButtonActivated()
			openInventory()
		end

		petButton.Activated:Connect(handlePetButtonActivated)
	end

	-- 这个东西会传给 Petinventory 里面的 Controller，相当于给了个引用
	petInventoryView.SetActionHandlers({
		Equip = equipPet,
		Unequip = unequipPet,
		EquipBest = equipBest,
		UnequipAll = unequipAll,
		DeletePets = deletePets,
	})
	bindPetButton()

	return {}
end

return PetActionController
