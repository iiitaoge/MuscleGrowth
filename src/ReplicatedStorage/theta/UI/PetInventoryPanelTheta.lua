-- PetInventoryPanelTheta
-- 宠物背包的 UI 路径合同。
-- 路径只描述渲染/交互必须认识的语义节点；布局、颜色、描边、圆角等由 Studio UI 自己管理。

local PetInventoryPanelTheta = {
	-- 左侧入口按钮所在的 ScreenGui。
	HudScreenGuiName = "HUD",
	-- 宠物背包面板所在的 ScreenGui。
	ScreenGuiName = "Main",

	Paths = {
		-- 左侧宠物背包入口按钮。
		PetButton = { RootKey = "HUDScreenGui", Path = { "LeftButtons", "Button", "Pet" } },
		-- NewPet 屏幕根节点，用于显示/隐藏整个宠物背包界面。
		PanelRoot = { RootKey = "ScreenGui", Path = { "NewPet" } },
		-- 背包主面板根节点。
		BackPackRoot = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack" } },
		-- 关闭动作入口。
		CloseButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Title", "Close" } },
		-- 已拥有宠物列表容器。
		OwnedList = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame" } },
		-- 已拥有宠物卡模板。
		OwnedTemplate = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "Info", "Templates", "BackPackPet", "Template" } },
		-- 已装备宠物区域。
		EquippedList = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedPet" } },
		-- 已装备宠物卡模板。
		EquippedTemplate = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "Info", "Templates", "EquippedPet", "Template" } },
		-- 已装备数量文本。
		EquippedText = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedText" } },
		-- 背包为空提示。
		NoPet = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "Info", "NoPet" } },
		-- 背包操作提示根节点及文本。
		TipRoot = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Tip" } },
		TipText = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Tip", "Value" } },
		-- 装备最佳宠物动作入口。
		EquipBestButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "EquipBest" } },
		-- 全部卸下动作入口。
		UnequipAllButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "UnEquipAll" } },
		-- 删除选中宠物动作入口。
		DeleteButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "Delete" } },
		-- 删除模式按钮组及其动作入口。
		DeleteModeRoot = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "Deletes" } },
		SelectAllButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "Deletes", "Delete_Select" } },
		CancelDeleteButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "Deletes", "Delete_Cancel" } },
		ConfirmDeleteButton = { RootKey = "ScreenGui", Path = { "NewPet", "BackPack", "Main", "BottomButton", "Deletes", "Delete_ok" } },
	},

	-- 宠物卡内部固定字段路径。背包卡和装备卡共用。
	PetCardFieldPathSpecs = {
		Icon = { RootKey = "PetCard", Path = { "Icon" } },
		MultiplierText = { RootKey = "PetCard", Path = { "MultiplierText" } },
	},

	-- 装备数量文本格式。
	EquippedTextFormat = "Equipped ( %s/%s Pets)",

	Messages = {
		DeletePrompt = "Select Pets to Delete!",
		SlotFull = "Pet slots are full!",
		AlreadyEquipped = "Pet is already equipped.",
		DeleteEquippedBlocked = "Unequip this pet before deleting.",
		EmptyDeleteSelection = "Select at least one pet.",
		DeleteFailed = "Unable to delete pets.",
	},
	TemporaryTipSeconds = 1.5,
}

return PetInventoryPanelTheta
