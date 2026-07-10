-- EggPanelTheta
-- 蛋面板的全局 UI 路径合同。
-- 这些路径描述“语义节点在哪里”，不是某个蛋的数据；所有蛋共用这套面板合同。
-- 后续如果改成 Attribute/Role 合同，可以在这里替换掉路径合同。

local function screenGuiPath(path)
	return { RootKey = "ScreenGui", Path = path }
end

local EggPanelTheta = {
	-- 蛋面板所在的 ScreenGui 名。
	ScreenGuiName = "Main",

	Paths = {
		-- 面板根节点，用于显示/隐藏整个蛋面板。
		PanelRoot = screenGuiPath({ "Egg" }),
		-- 标题区域，当前用来写入蛋展示名。
		TitleRoot = screenGuiPath({ "Egg", "Title" }),
		-- 关闭动作入口。
		CloseButton = screenGuiPath({ "Egg", "Title", "Close" }),
		-- 奖池固定槽位。布局由 Studio 决定，渲染层只填内容。
		RewardSlots = {
			screenGuiPath({ "Egg", "Main", "RewardTopRow", "RewardSlot1" }),
			screenGuiPath({ "Egg", "Main", "RewardTopRow", "RewardSlot2" }),
			screenGuiPath({ "Egg", "Main", "RewardTopRow", "RewardSlot3" }),
			screenGuiPath({ "Egg", "Main", "RewardLowRow", "RewardSlot4" }),
			screenGuiPath({ "Egg", "Main", "RewardLowRow", "RewardSlot5" }),
		},
		-- 抽奖结果单模板。当前只展示一个结果，后续三槽结果再扩展合同。
		ResultTemplate = screenGuiPath({ "Egg", "EggPetElement" }),
		-- 抽奖按钮分组根节点。
		ButtonRoot = screenGuiPath({ "Egg", "Button" }),
		-- 单抽动作入口。
		SingleRollButton = screenGuiPath({ "Egg", "Button", "E" }),
		-- 三连抽动作入口。
		TripleRollButton = screenGuiPath({ "Egg", "Button", "R" }),
		-- 自动抽开始/停止动作入口。
		AutoRollButton = screenGuiPath({ "Egg", "Button", "T" }),
	},

	-- 奖池槽内部字段名。必须是槽位子孙节点，不包含布局或装饰节点。
	RewardSlotFields = {
		Icon = "Icon",
		ChanceText = "ChanceText",
		MultiplierText = "MultiplierText",
	},

	-- 抽奖结果模板内部字段名。
	ResultTemplateFields = {
		Icon = "Icon",
		NameText = "NameText",
		RarityText = "RarityText",
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
