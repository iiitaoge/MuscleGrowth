-- EggRevealPanelTheta
-- 抽蛋开奖展示层的 UI 路径合同。

local function screenGuiPath(path)
	return { RootKey = "ScreenGui", Path = path }
end

local EggRevealPanelTheta = {
	ScreenGuiName = "Main",

	Paths = {
		PanelRoot = screenGuiPath({ "EggReveal" }),
		Background = screenGuiPath({ "EggReveal", "Background" }),
		RewardSlots = {
			screenGuiPath({ "EggReveal", "RewardSlots", "RewardSlot1" }),
			screenGuiPath({ "EggReveal", "RewardSlots", "RewardSlot2" }),
			screenGuiPath({ "EggReveal", "RewardSlots", "RewardSlot3" }),
		},
		ContinueButton = screenGuiPath({ "EggReveal", "TextButton" }),
		ContinueText = screenGuiPath({ "EggReveal", "ContinueText" }),
		StopButton = screenGuiPath({ "EggReveal", "StopButton" }),
	},

	RewardSlotFields = {
		Icon = "Icon",
		NameText = "NameText",
		RarityText = "RarityText",
	},

	ContinuePromptText = "Click anywhere to continue",
}

return EggRevealPanelTheta
