-- RebirthPanelTheta
-- 重生面板的 UI 路径和语义节点合同。

local RebirthPanelTheta = {
	-- 重生面板所在 ScreenGui 名。
	ScreenGuiName = "Main",

	Paths = {
		-- 重生面板根节点。
		PanelRoot = { "Rebirth" },
	},

	Nodes = {
		-- 关闭按钮名。
		CloseButtonName = "Close",
		-- 重生请求按钮名。
		ActionButtonName = "Rebirth",
		-- 标题文本名。
		TitleTextName = "Title",
		-- 提示文本名。
		TipTextName = "Tip",
		-- 提示文本兜底节点名。
		FallbackTipTextName = "TextLabel",
	},

	RenderBindings = {
		-- 面板标题文本。
		{
			Key = "TitleText",
			ModelKey = "TitleText",
			Operation = "SetText",
			Ref = "TitleText",
		},
		-- 面板提示文本。
		{
			Key = "TipText",
			ModelKey = "TipText",
			Operation = "SetText",
			Ref = "TipText",
		},
		-- 当前和下一重生次数文本。
		{
			Key = "RebirthCountTexts",
			ModelKey = "RebirthTexts",
			Operation = "SetTextSequenceByMatch",
			RootPath = { "Main" },
			Match = {
				MatchType = "Pattern",
				Pattern = "^%{%d+%}$",
			},
		},
		-- 当前和下一力量倍率文本。
		{
			Key = "PowerTexts",
			ModelKey = "PowerTexts",
			Operation = "SetTextSequenceByMatch",
			RootPath = { "Main" },
			Match = {
				MatchType = "Contains",
				Contains = "Power",
			},
		},
		-- 当前和下一最大等级文本。
		{
			Key = "MaxLevelTexts",
			ModelKey = "MaxLevelTexts",
			Operation = "SetTextSequenceByMatch",
			RootPath = { "Main" },
			Match = {
				MatchType = "Contains",
				Contains = "Max Level",
			},
		},
		-- 当前等级进度条填充。
		{
			Key = "LevelProgressFill",
			ModelKey = "LevelProgressRatio",
			Operation = "SetSizeXScale",
			Path = { "Main", "Bar", "Bar", "Bar" },
		},
		-- 当前等级进度文本。
		{
			Key = "LevelProgressText",
			ModelKey = "LevelProgressText",
			Operation = "SetText",
			Path = { "Main", "Bar", "Bar","Title" },
			Optional = true,
		},
		-- 重生请求按钮文本。
		{
			Key = "RequestButtonText",
			ModelKey = "RequestText",
			Operation = "SetDescendantTexts",
			Ref = "RequestButton",
		},
	},
}

return RebirthPanelTheta
