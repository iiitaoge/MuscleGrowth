-- PetInventory/Controller
-- 编排宠物背包打开关闭、选择状态和装备/卸下/删除按钮事件。

local DataAdapter = require(script.Parent.DataAdapter)
local Renderer = require(script.Parent.Renderer)
local UIRefs = require(script.Parent.Parent.UIRefs)

local Controller = {}

-- 初始化宠物背包控制器。
function Controller.Init(player)
	local refs = UIRefs.ResolvePetInventory(player)

	local latestData = nil
	local actionHandlers = {} :: {[string]: any}
	local selectedPetInstanceIds = {} :: {[string]: boolean}
	local isDeleteMode = false
	local tipVersion = 0
	local petButton = nil
	local renderInventory = nil

	-- 判断背包面板是否打开。
	local function isOpen()
		return Renderer.IsOpen(refs)
	end

	local function showTemporaryTip(message)
		tipVersion += 1
		local currentTipVersion = tipVersion
		Renderer.SetTip(refs, true, message)

		task.delay(refs.TemporaryTipSeconds, function()
			if tipVersion ~= currentTipVersion then
				return
			end

			if isDeleteMode then
				Renderer.SetTip(refs, true, refs.Messages.DeletePrompt)
			else
				Renderer.SetTip(refs, false, "")
			end
		end)
	end

	local function setDeleteMode(nextIsDeleteMode)
		isDeleteMode = nextIsDeleteMode == true
		table.clear(selectedPetInstanceIds)
		tipVersion += 1

		Renderer.SetDeleteMode(refs, isDeleteMode)
		if isDeleteMode then
			Renderer.SetTip(refs, true, refs.Messages.DeletePrompt)
		else
			Renderer.SetTip(refs, false, "")
		end

		if latestData and renderInventory then
			renderInventory(latestData)
		end
	end

	-- 清理已经不存在或已经装备的删除选择。
	local function clearInvalidSelections(ownedSnapshots, equippedSnapshots)
		local ownedInstanceIds = DataAdapter.BuildOwnedInstanceIdSet(ownedSnapshots)
		local equippedInstanceIds = DataAdapter.BuildEquippedInstanceIdSet(equippedSnapshots)
		for instanceId in pairs(selectedPetInstanceIds) do
			if not ownedInstanceIds[instanceId] or equippedInstanceIds[instanceId] then
				selectedPetInstanceIds[instanceId] = nil
			end
		end
	end

	local function getEquipFailureMessage(result)
		if not result or result.Success ~= false then
			return nil
		end

		if result.ClientReason == "AlreadyEquipped" then
			return refs.Messages.AlreadyEquipped
		elseif result.ClientReason == "NoEmptySlot" then
			return refs.Messages.SlotFull
		end

		return result.Message
	end

	-- 普通模式装备宠物；删除模式切换未装备宠物的选择状态。
	local function handleOwnedPetActivated(petSnapshot, equippedInstanceIds)
		local instanceId = petSnapshot.InstanceId
		if isDeleteMode then
			if equippedInstanceIds[instanceId] then
				showTemporaryTip(refs.Messages.DeleteEquippedBlocked)
				return
			end

			if selectedPetInstanceIds[instanceId] then
				selectedPetInstanceIds[instanceId] = nil
			else
				selectedPetInstanceIds[instanceId] = true
			end
			renderInventory(latestData)
			return
		end

		local equipHandler = actionHandlers.Equip
		if equipHandler then
			local result = equipHandler(instanceId)
			local failureMessage = getEquipFailureMessage(result)
			if failureMessage then
				showTemporaryTip(failureMessage)
			end
		end
	end

	-- 请求卸下已装备宠物。
	local function handleEquippedPetActivated(slotIndex)
		local unequipHandler = actionHandlers.Unequip
		if unequipHandler then
			unequipHandler(slotIndex)
		end
	end

	-- 按快照渲染整个宠物背包。
	renderInventory = function(data)
		local ownedSnapshots = data.OwnedPetSnapshots
		local equippedSnapshots = data.EquippedPetSnapshots
		local maxEquippedPets = DataAdapter.GetMaxEquippedPets()
		local equippedInstanceIds = DataAdapter.BuildEquippedInstanceIdSet(equippedSnapshots)

		clearInvalidSelections(ownedSnapshots, equippedSnapshots)

		local ownedModels = DataAdapter.BuildOwnedPetModels(ownedSnapshots, selectedPetInstanceIds)
		local equippedModels = DataAdapter.BuildEquippedPetModels(equippedSnapshots)
		local ownedCards = Renderer.RenderOwnedPets(refs, ownedModels)
		local equippedCards = Renderer.RenderEquippedPets(refs, equippedModels)

		-- 普通模式点击装备；删除模式点击切换删除选择。
		for _, renderedCard in ipairs(ownedCards) do
			local petSnapshot = renderedCard.Model.Snapshot
			Renderer.ConnectActivated(renderedCard.Root, function()
				handleOwnedPetActivated(petSnapshot, equippedInstanceIds)
			end)
		end

		for _, renderedCard in ipairs(equippedCards) do
			local slotIndex = renderedCard.Model.SlotIndex
			-- 已装备宠物卡点击后请求卸下对应槽位。
			Renderer.ConnectActivated(renderedCard.Root, function()
				handleEquippedPetActivated(slotIndex)
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

	-- 打开或关闭宠物背包，只负责显示状态。
	local function setOpen(nextIsOpen)
		if nextIsOpen ~= true then
			setDeleteMode(false)
		end
		Renderer.SetOpen(refs, nextIsOpen == true)
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
	Renderer.SetDeleteMode(refs, false)
	Renderer.SetTip(refs, false, "")
	petButton = Renderer.GetActivatedTarget(refs.PetButton)

	-- 关闭按钮隐藏背包。
	Renderer.ConnectActivated(refs.CloseButton, function()
		setOpen(false)
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
	-- 第一次点击删除按钮只进入删除选择模式。
	Renderer.ConnectActivated(refs.DeleteButton, function()
		setDeleteMode(true)
	end)
	-- 全选所有未装备宠物。
	Renderer.ConnectActivated(refs.SelectAllButton, function()
		if not isDeleteMode or not latestData then
			return
		end

		table.clear(selectedPetInstanceIds)
		local equippedInstanceIds = DataAdapter.BuildEquippedInstanceIdSet(latestData.EquippedPetSnapshots)
		for _, petSnapshot in ipairs(latestData.OwnedPetSnapshots) do
			local instanceId = petSnapshot.InstanceId
			if not equippedInstanceIds[instanceId] then
				selectedPetInstanceIds[instanceId] = true
			end
		end

		if next(selectedPetInstanceIds) == nil then
			showTemporaryTip(refs.Messages.DeleteEquippedBlocked)
		end
		renderInventory(latestData)
	end)
	-- 取消删除并返回普通模式。
	Renderer.ConnectActivated(refs.CancelDeleteButton, function()
		setDeleteMode(false)
	end)
	-- 再次点击删除按钮，提交当前删除选择。
	Renderer.ConnectActivated(refs.ConfirmDeleteButton, function()
		if not isDeleteMode then
			return
		end

		local selectedInstanceIds = DataAdapter.BuildSelectedInstanceIdList(selectedPetInstanceIds)
		if #selectedInstanceIds == 0 then
			showTemporaryTip(refs.Messages.EmptyDeleteSelection)
			return
		end

		local handler = actionHandlers.DeletePets
		if not handler then
			showTemporaryTip(refs.Messages.DeleteFailed)
			return
		end

		local result = handler(selectedInstanceIds)
		if result and result.Success == true then
			setDeleteMode(false)
		else
			showTemporaryTip((result and result.Message) or refs.Messages.DeleteFailed)
		end
	end)

	-- 返回给客户端总线层，返回一个函数表
	return {
		Refresh = refresh,
		SetOpen = setOpen,
		SetActionHandlers = setActionHandlers,
		GetPetButton = getPetButton,
		IsOpen = isOpen,
	}
end

return Controller
