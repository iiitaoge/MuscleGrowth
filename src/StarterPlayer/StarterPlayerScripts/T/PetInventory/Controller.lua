-- PetInventory/Controller
-- 编排宠物背包打开关闭、选择状态和装备/卸下/删除按钮事件。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)

local Controller = {}

-- 空视图里使用的无操作函数。
local function noop() end

-- 空视图里使用的 nil 返回函数。
local function returnNil()
	return nil
end

-- 空视图里使用的空数组返回函数。
local function returnEmptyList()
	return {}
end

-- 空视图里使用的 false 返回函数。
local function returnFalse()
	return false
end

-- 构造 UI 不可用时的空视图。
local function createNoopView()
	return {
		Refresh = noop,
		SetOpen = noop,
		SetActionHandlers = noop,
		GetPetButton = returnNil,
		GetSelectedPetInstanceIds = returnEmptyList,
		IsOpen = returnFalse,
	}
end

-- 初始化宠物背包控制器。
function Controller.Init(player)
	local refs = Renderer.Resolve(player)
	if not refs then
		return createNoopView()
	end

	local latestData = nil
	local actionHandlers = {} :: {[string]: any}
	local selectedPetInstanceIds = {} :: {[string]: boolean}
	local petButton = nil

	-- 判断背包面板是否打开。
	local function isOpen()
		return Renderer.IsOpen(refs)
	end

	-- 清理已经不存在的选中宠物实例。
	local function clearMissingSelections(ownedSnapshots)
		local ownedInstanceIds = DataAdapter.BuildOwnedInstanceIdSet(ownedSnapshots)
		for instanceId in pairs(selectedPetInstanceIds) do
			if not ownedInstanceIds[instanceId] then
				selectedPetInstanceIds[instanceId] = nil
			end
		end
	end

	-- 切换背包宠物选中状态。
	local function handleOwnedPetActivated(petSnapshot)
		if type(petSnapshot) ~= "table" or type(petSnapshot.InstanceId) ~= "string" then
			return
		end

		local instanceId = tostring(petSnapshot.InstanceId)
		selectedPetInstanceIds[instanceId] = selectedPetInstanceIds[instanceId] ~= true
	end

	-- 请求卸下已装备宠物。
	local function handleEquippedPetActivated(slotIndex, petSnapshot)
		if type(petSnapshot) ~= "table" or type(petSnapshot.PetTypeId) ~= "string" then
			return
		end

		local unequipHandler = actionHandlers.Unequip
		if unequipHandler then
			unequipHandler(slotIndex)
		end
	end

	-- 返回当前选中的宠物实例 id 列表。
	local function getSelectedPetInstanceIds()
		return DataAdapter.BuildSelectedInstanceIdList(selectedPetInstanceIds)
	end

	-- 按快照渲染整个宠物背包。
	local function renderInventory(data)
		local ownedSnapshots = data and data.OwnedPetSnapshots
		local equippedSnapshots = data and data.EquippedPetSnapshots
		local maxEquippedPets = DataAdapter.GetMaxEquippedPets()

		clearMissingSelections(ownedSnapshots)

		local ownedModels = DataAdapter.BuildOwnedPetModels(ownedSnapshots, selectedPetInstanceIds)
		local equippedModels = DataAdapter.BuildEquippedPetModels(equippedSnapshots)
		local ownedCards = Renderer.RenderOwnedPets(refs, ownedModels)
		local equippedCards = Renderer.RenderEquippedPets(refs, equippedModels)

		for _, renderedCard in ipairs(ownedCards) do
			local petSnapshot = renderedCard.Model.Snapshot
			-- 背包宠物卡点击后切换删除选择状态。
			Renderer.ConnectActivated(renderedCard.Root, function()
				handleOwnedPetActivated(petSnapshot)
				renderInventory(latestData)
			end)
		end

		for _, renderedCard in ipairs(equippedCards) do
			local slotIndex = renderedCard.Model.SlotIndex
			local petSnapshot = renderedCard.Model.Snapshot
			-- 已装备宠物卡点击后请求卸下对应槽位。
			Renderer.ConnectActivated(renderedCard.Root, function()
				handleEquippedPetActivated(slotIndex, petSnapshot)
			end)
		end

		Renderer.SetEquippedText(refs, DataAdapter.BuildEquippedText(#equippedModels, maxEquippedPets))
		Renderer.SetNoPetVisible(refs, DataAdapter.GetSnapshotCount(ownedSnapshots) == 0)
	end

	-- 刷新宠物背包数据。
	local function refresh(data)
		latestData = data
		renderInventory(data)
	end

	-- 打开或关闭宠物背包。
	local function setOpen(nextIsOpen)
		Renderer.SetOpen(refs, nextIsOpen == true)
		if isOpen() then
			refresh(latestData)
		end
	end

	-- 设置外部宠物操作处理器。
	local function setActionHandlers(nextActionHandlers)
		actionHandlers = type(nextActionHandlers) == "table" and nextActionHandlers or {}
	end

	-- 返回左侧宠物入口按钮。
	local function getPetButton()
		return petButton
	end

	Renderer.SetOpen(refs, false)

	-- 关闭按钮隐藏背包。
	Renderer.ConnectActivated(refs.CloseButton, function()
		setOpen(false)
	end)
	-- 入口按钮打开背包。
	petButton = Renderer.ConnectActivated(refs.PetButton, function()
		-- print("宠物入口按钮回调触发")

		-- print("PanelRoot =", refs.PanelRoot)
		-- print("PanelRoot FullName =", refs.PanelRoot and refs.PanelRoot:GetFullName())
		-- print("PanelRoot ClassName =", refs.PanelRoot and refs.PanelRoot.ClassName)
		-- print("打开前 Visible =", refs.PanelRoot and refs.PanelRoot.Visible)

		setOpen(true)

		-- print("打开后 Visible =", refs.PanelRoot and refs.PanelRoot.Visible)
	end)
	-- 装备最佳按钮委托给外部处理器。
	Renderer.ConnectActivated(refs.EquipBestButton, function()
		local handler = actionHandlers.EquipBest
		if handler then
			handler()
		end
	end)
	-- 全部卸下按钮委托给外部处理器。
	Renderer.ConnectActivated(refs.UnequipAllButton, function()
		local handler = actionHandlers.UnequipAll
		if handler then
			handler()
		end
	end)
	-- 删除按钮提交当前选中的宠物实例。
	Renderer.ConnectActivated(refs.DeleteButton, function()
		local handler = actionHandlers.DeleteSelected
		if handler then
			handler(getSelectedPetInstanceIds())
		end
	end)

	return {
		Refresh = refresh,
		SetOpen = setOpen,
		SetActionHandlers = setActionHandlers,
		GetPetButton = getPetButton,
		GetSelectedPetInstanceIds = getSelectedPetInstanceIds,
		IsOpen = isOpen,
	}
end

return Controller
