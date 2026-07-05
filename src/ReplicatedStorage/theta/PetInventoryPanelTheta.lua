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
		PetButton = { "LeftButtons", "Button", "Pet" },
		-- NewPet 屏幕根节点，用于显示/隐藏整个宠物背包界面。
		PanelRoot = { "NewPet" },
		-- 背包主面板根节点。
		BackPackRoot = { "NewPet", "BackPack" },
		-- 关闭动作入口。
		CloseButton = { "NewPet", "BackPack", "Title", "Close" },
		-- 已拥有宠物列表容器。
		OwnedList = { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame" },
		-- 已拥有宠物卡模板。
		OwnedTemplate = { "NewPet", "BackPack", "Main", "Info", "ScrollingFrame", "BackPackPet" },
		-- 已装备宠物区域。
		EquippedList = { "NewPet", "BackPack", "Main", "Info", "PetEquipList" },
		-- 已装备宠物卡模板。
		EquippedTemplate = { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedPet" },
		-- 已装备数量文本。
		EquippedText = { "NewPet", "BackPack", "Main", "Info", "PetEquipList", "EquippedText" },
		-- 背包为空提示。
		NoPet = { "NewPet", "BackPack", "Main", "Info", "NoPet" },
		-- 装备最佳宠物动作入口。
		EquipBestButton = { "NewPet", "BackPack", "Main", "BottomButton", "EquipBest" },
		-- 全部卸下动作入口。
		UnequipAllButton = { "NewPet", "BackPack", "Main", "BottomButton", "UnEquipAll" },
		-- 删除选中宠物动作入口。
		DeleteButton = { "NewPet", "BackPack", "Main", "BottomButton", "Delete" },
	},

	-- 宠物卡内部字段。背包卡和装备卡共用。
	PetCardFields = {
		Icon = "Icon",
		MultiplierText = "MultiplierText",
	},

	-- 装备数量文本格式。
	EquippedTextFormat = "Equipped ( %d/%d Pets)",
}

return PetInventoryPanelTheta
