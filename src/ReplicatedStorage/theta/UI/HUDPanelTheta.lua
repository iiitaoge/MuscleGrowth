-- HUDPanelTheta
-- HUD 主界面的 UI 路径合同，只记录程序必须认识的语义节点。

local HUDPanelTheta = {
	-- HUD 所在 ScreenGui 名。
	ScreenGuiName = "HUD",

	Paths = {
		-- 力量数值文本。
		StrengthText = { RootKey = "ScreenGui", Path = { "Friend", "Power", "Text" } },
		-- 力量增长飘字的归拢目标。
		StrengthIconGlow = { RootKey = "ScreenGui", Path = { "Friend", "Power", "IconGlow" } },
		-- 奖杯数值文本。
		TrophiesText = { RootKey = "ScreenGui", Path = { "Friend", "trophy", "Text" } },
		-- 重生倍率文本。
		RebirthMultiplierText = { RootKey = "ScreenGui", Path = { "Bottom", "Bottom", "Rebirth", "Level" } },
		-- 杠铃倍率文本。
		BarbellMultiplierText = { RootKey = "ScreenGui", Path = { "Bottom", "Bottom", "Dumbbell", "Level" } },
		-- 宠物倍率文本。
		PetMultiplierText = { RootKey = "ScreenGui", Path = { "Bottom", "Bottom", "Pet", "Level" } },
		-- 经验条填充节点。
		ExpBar = { RootKey = "ScreenGui", Path = { "Bottom", "Progress", "Bar" } },
		-- 等级文本。
		LevelText = { RootKey = "ScreenGui", Path = { "Bottom", "Progress", "Level" } },
		-- 经验进度文本。
		ExpText = { RootKey = "ScreenGui", Path = { "Bottom", "Progress", "Progress" } },
		-- 重生入口按钮。
		RebirthButton = { RootKey = "ScreenGui", Path = { "LeftButtons", "Button", "Rebirth" } },
	},
}

return HUDPanelTheta
