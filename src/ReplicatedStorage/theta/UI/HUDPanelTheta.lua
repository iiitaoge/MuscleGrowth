-- HUDPanelTheta
-- HUD 主界面的 UI 路径合同，只记录程序必须认识的语义节点。

local function screenGuiPath(path)
	return { RootKey = "ScreenGui", Path = path }
end

local HUDPanelTheta = {
	-- HUD 所在 ScreenGui 名。
	ScreenGuiName = "HUD",

	Paths = {
		-- 力量数值文本。
		StrengthText = screenGuiPath({ "Friend", "Power", "Text" }),
		-- 奖杯数值文本。
		TrophiesText = screenGuiPath({ "Friend", "trophy", "Text" }),
		-- 重生倍率文本。
		RebirthMultiplierText = screenGuiPath({ "Bottom", "Bottom", "Rebirth", "Level" }),
		-- 杠铃倍率文本。
		BarbellMultiplierText = screenGuiPath({ "Bottom", "Bottom", "Dumbbell", "Level" }),
		-- 宠物倍率文本。
		PetMultiplierText = screenGuiPath({ "Bottom", "Bottom", "Pet", "Level" }),
		-- 经验条填充节点。
		ExpBar = screenGuiPath({ "Bottom", "Progress", "Bar" }),
		-- 等级文本。
		LevelText = screenGuiPath({ "Bottom", "Progress", "Level" }),
		-- 经验进度文本。
		ExpText = screenGuiPath({ "Bottom", "Progress", "Progress" }),
		-- 重生入口按钮。
		RebirthButton = screenGuiPath({ "LeftButtons", "Button", "Rebirth" }),
	},
}

return HUDPanelTheta
