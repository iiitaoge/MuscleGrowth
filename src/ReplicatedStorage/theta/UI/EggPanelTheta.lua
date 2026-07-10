-- EggPanelTheta
-- 蛋面板的全局 UI 路径合同。
-- 这些路径描述“语义节点在哪里”，不是某个蛋的数据；所有蛋共用这套面板合同。
-- 后续如果改成 Attribute/Role 合同，可以在这里替换掉路径合同。

local EggPanelTheta = {
	-- 蛋面板所在的 ScreenGui 名。
	ScreenGuiName = "Main",

	Paths = {
		-- 面板根节点，用于显示/隐藏整个蛋面板。
		PanelRoot = { RootKey = "ScreenGui", Path = { "Egg" } },
		-- 标题区域，当前用来写入蛋展示名。
		TitleRoot = { RootKey = "ScreenGui", Path = { "Egg", "Title" } },
		-- 关闭动作入口。
		CloseButton = { RootKey = "ScreenGui", Path = { "Egg", "Title", "Close" } },
		-- 奖池固定槽位。布局由 Studio 决定，渲染层只填内容。
		RewardSlots = {
			{ RootKey = "ScreenGui", Path = { "Egg", "Main", "RewardTopRow", "RewardSlot1" } },
			{ RootKey = "ScreenGui", Path = { "Egg", "Main", "RewardTopRow", "RewardSlot2" } },
			{ RootKey = "ScreenGui", Path = { "Egg", "Main", "RewardTopRow", "RewardSlot3" } },
			{ RootKey = "ScreenGui", Path = { "Egg", "Main", "RewardLowRow", "RewardSlot4" } },
			{ RootKey = "ScreenGui", Path = { "Egg", "Main", "RewardLowRow", "RewardSlot5" } },
		},
		-- 抽奖结果单模板。当前只展示一个结果，后续三槽结果再扩展合同。
		ResultTemplate = { RootKey = "ScreenGui", Path = { "Egg", "EggPetElement" } },
		-- 抽奖按钮分组根节点。
		ButtonRoot = { RootKey = "ScreenGui", Path = { "Egg", "Button" } },
		-- 单抽动作入口。
		SingleRollButton = { RootKey = "ScreenGui", Path = { "Egg", "Button", "E" } },
		-- 三连抽动作入口。
		TripleRollButton = { RootKey = "ScreenGui", Path = { "Egg", "Button", "R" } },
		-- 自动抽开始/停止动作入口。
		AutoRollButton = { RootKey = "ScreenGui", Path = { "Egg", "Button", "T" } },
	},

	-- 奖池槽内部固定字段路径，相对当前 RewardSlot。
	RewardSlotFieldPathSpecs = {
		Icon = { RootKey = "RewardSlot", Path = { "Icon" } },
		ChanceText = { RootKey = "RewardSlot", Path = { "ChanceText" } },
		MultiplierText = { RootKey = "RewardSlot", Path = { "MultiplierText" } },
	},

	-- 抽奖结果模板内部固定字段路径，相对当前 ResultTemplate。
	ResultTemplateFieldPathSpecs = {
		Icon = { RootKey = "ResultTemplate", Path = { "Icon" } },
		NameText = { RootKey = "ResultTemplate", Path = { "NameText" } },
		RarityText = { RootKey = "ResultTemplate", Path = { "RarityText" } },
	},

	-- 按钮上显示的操作提示；不决定服务端允许的 rollCount。
	RollButtonText = {
		Single = "E",
		Triple = "H",
		Auto = "A",
		AutoStop = "STOP",
	},
}

return EggPanelTheta
