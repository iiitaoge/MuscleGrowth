-- EggRevealPanelTheta
-- 抽蛋开奖展示层的 UI 路径合同。

local EggRevealPanelTheta = {
	ScreenGuiName = "Main",

	Paths = {
		PanelRoot = { "EggReveal" },
		Background = { "EggReveal", "Background" },
		RewardSlots = {
			{ "EggReveal", "RewardSlots", "RewardSlot1" },
			{ "EggReveal", "RewardSlots", "RewardSlot2" },
			{ "EggReveal", "RewardSlots", "RewardSlot3" },
		},
		ContinueButton = { "EggReveal", "TextButton" },
		ContinueText = { "EggReveal", "ContinueText" },
		StopButton = { "EggReveal", "StopButton" },
	},

	RewardSlotFields = {
		Icon = "Icon",
		NameText = "NameText",
		RarityText = "RarityText",
	},

	ContinuePromptText = "Click anywhere to continue",
}

return EggRevealPanelTheta
