-- PetActionController
-- 客户端宠物背包动作层，负责装备、卸下、删除和入口刷新。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PetSystemTheta"))

local PetActionController = {}

-- 初始化宠物动作控制器。
function PetActionController.Init(remoteClient, snapshotController, petInventoryView)
	local isOpeningInventory = false

	-- 用给定快照刷新宠物背包。
	local function refreshPetInventoryFromData(data)
		if data then
			petInventoryView.Refresh(data)
		end
	end

	-- 打开背包时主动向服务端拿一次完整快照。
	local function refreshPetInventoryFromServer()
		return snapshotController.RefreshFromServer()
	end

	-- 统一处理宠物动作 Remote 结果，并按需刷新宠物背包。
	local function applyPetActionResult(success, result, shouldRefreshInventory)
		local appliedResult = snapshotController.ApplyRemoteResult(success, result)
		if shouldRefreshInventory and appliedResult and appliedResult.Data then
			refreshPetInventoryFromData(appliedResult.Data)
		end

		return appliedResult
	end

	-- 调用宠物 Remote，并统一处理结果。
	local function invokePetRemote(remoteId, shouldRefreshInventory, ...)
		local success, result = remoteClient.SafeInvoke(remoteId, ...)
		return applyPetActionResult(success, result, shouldRefreshInventory)
	end

	-- 按倍率和实例 id 排序宠物快照。
	local function comparePetsByMultiplier(left, right)
		local leftMultiplier = tonumber(left.Multiplier) or 0
		local rightMultiplier = tonumber(right.Multiplier) or 0
		if leftMultiplier == rightMultiplier then
			return (tonumber(left.InstanceId) or math.huge) < (tonumber(right.InstanceId) or math.huge)
		end

		return leftMultiplier > rightMultiplier
	end

	-- 调用宠物装备 Remote。
	local function requestPetEquip(petInstanceId, slotIndex, shouldRefreshInventory)
		return invokePetRemote("RequestPetEquip", shouldRefreshInventory, petInstanceId, slotIndex)
	end

	-- 调用宠物卸下 Remote。
	local function requestPetUnequip(slotIndex, shouldRefreshInventory)
		return invokePetRemote("RequestPetUnequip", shouldRefreshInventory, slotIndex)
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
			latestPetResult = requestPetUnequip(slotIndex, false) or latestPetResult
		end

		for slotIndex = 1, math.min(maxEquippedPets, #ownedPets) do
			latestPetResult = requestPetEquip(ownedPets[slotIndex].InstanceId, slotIndex, false) or latestPetResult
		end

		if latestPetResult and latestPetResult.Data then
			refreshPetInventoryFromData(latestPetResult.Data)
		end
	end

	-- 卸下所有装备槽。
	local function unequipAll()
		local maxEquippedPets = math.max(1, math.floor(tonumber(PetSystemTheta.MaxEquippedPets) or 3))
		local latestPetResult = nil

		for slotIndex = 1, maxEquippedPets do
			latestPetResult = requestPetUnequip(slotIndex, false) or latestPetResult
		end

		if latestPetResult and latestPetResult.Data then
			refreshPetInventoryFromData(latestPetResult.Data)
		end
	end

	-- 删除背包里当前选中的宠物实例。
	local function deleteSelected(petInstanceIds)
		-- 确保类型为 表 确保表长度 > 0
		if type(petInstanceIds) ~= "table" or #petInstanceIds <= 0 then
			warn("No pets selected")
			return
		end

		invokePetRemote("RequestPetDelete", true, petInstanceIds)
	end

	-- 装备单只宠物并刷新背包。
	local function equipPet(petInstanceId, slotIndex)
		return requestPetEquip(petInstanceId, slotIndex, true)
	end

	-- 卸下单个装备槽并刷新背包。
	local function unequipPet(slotIndex)
		return requestPetUnequip(slotIndex, true)
	end

	-- 打开宠物背包：先拿数据并渲染，再显示面板。
	local function openInventory()
		if petInventoryView.IsOpen() or isOpeningInventory then
			return
		end

		isOpeningInventory = true
		local data = refreshPetInventoryFromServer()
		isOpeningInventory = false

		if data then
			refreshPetInventoryFromData(data)
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
		DeleteSelected = deleteSelected,
	})
	bindPetButton()

	return {}
end

return PetActionController
