-- EggRevealPanelTheta
-- 抽蛋开奖展示层的 UI 路径合同。

local EggRevealPanelTheta = {
	ScreenGuiName = "Main",

	Paths = {
		PanelRoot = { RootKey = "ScreenGui", Path = { "EggReveal" } },
		Background = { RootKey = "ScreenGui", Path = { "EggReveal", "Background" } },
		RewardSlots = {
			{ RootKey = "ScreenGui", Path = { "EggReveal", "RewardSlots", "RewardSlot1" } },
			{ RootKey = "ScreenGui", Path = { "EggReveal", "RewardSlots", "RewardSlot2" } },
			{ RootKey = "ScreenGui", Path = { "EggReveal", "RewardSlots", "RewardSlot3" } },
		},
		ContinueButton = { RootKey = "ScreenGui", Path = { "EggReveal", "TextButton" } },
		ContinueText = { RootKey = "ScreenGui", Path = { "EggReveal", "ContinueText" } },
		StopButton = { RootKey = "ScreenGui", Path = { "EggReveal", "StopButton" } },
	},

	RewardSlotFieldPathSpecs = {
		Icon = { RootKey = "RewardSlot", Path = { "Icon" } },
		NameText = { RootKey = "RewardSlot", Path = { "NameText" } },
		RarityText = { RootKey = "RewardSlot", Path = { "RarityText" } },
	},

	ContinuePromptText = "Click anywhere to continue",
}

return EggRevealPanelTheta
