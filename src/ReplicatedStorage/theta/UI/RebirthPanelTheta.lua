-- RebirthPanelTheta
-- 重生面板的严格 UI 路径合同。路径根节点由调用者映射为真实 Instance。

local Paths = {
	PanelRoot = {
		RootKey = "ScreenGui",
		Path = { "Rebirth" },
	},
	CloseButton = {
		RootKey = "PanelRoot",
		Path = { "Main", "Title", "Close" },
	},
	RequestButton = {
		RootKey = "PanelRoot",
		Path = { "Main", "Buttons", "Rebirth" },
	},
	TitleText = {
		RootKey = "PanelRoot",
		Path = { "Main", "Title", "TextLabel" },
	},
	TipText = {
		RootKey = "PanelRoot",
		Path = { "Tip", "Value" },
	},
	RebirthCountTexts = {
		{
			RootKey = "PanelRoot",
			Path = { "Main", "Main", "1Left", "1" },
		},
		{
			RootKey = "PanelRoot",
			Path = { "Main", "Main", "3Right", "1" },
		},
	},
	PowerTexts = {
		{
			RootKey = "PanelRoot",
			Path = { "Main", "Main", "1Left", "2", "Title" },
		},
		{
			RootKey = "PanelRoot",
			Path = { "Main", "Main", "3Right", "2", "Title" },
		},
	},
	MaxLevelTexts = {
		{
			RootKey = "PanelRoot",
			Path = { "Main", "Main", "1Left", "3", "Title" },
		},
		{
			RootKey = "PanelRoot",
			Path = { "Main", "Main", "3Right", "3", "Title" },
		},
	},
	LevelProgressFill = {
		RootKey = "PanelRoot",
		Path = { "Main", "Bar", "Bar", "Bar" },
	},
	LevelProgressText = {
		RootKey = "PanelRoot",
		Path = { "Main", "Bar", "Bar", "Title" },
	},
	RequestButtonText = {
		RootKey = "PanelRoot",
		Path = { "Main", "Buttons", "Rebirth", "Text" },
	},
}

local RebirthPanelTheta = {
	ScreenGuiName = "Main",
	Paths = Paths,
	RenderBindings = {
		{
			Key = "TitleText",
			ModelKey = "TitleText",
			Operation = "SetText",
			TargetType = "TextObject",
			Path = Paths.TitleText,
		},
		{
			Key = "TipText",
			ModelKey = "TipText",
			Operation = "SetText",
			TargetType = "TextObject",
			Path = Paths.TipText,
		},
		{
			Key = "RebirthCountTexts",
			ModelKey = "RebirthTexts",
			Operation = "SetTextTargets",
			TargetType = "TextObject",
			TargetPaths = Paths.RebirthCountTexts,
		},
		{
			Key = "PowerTexts",
			ModelKey = "PowerTexts",
			Operation = "SetTextTargets",
			TargetType = "TextObject",
			TargetPaths = Paths.PowerTexts,
		},
		{
			Key = "MaxLevelTexts",
			ModelKey = "MaxLevelTexts",
			Operation = "SetTextTargets",
			TargetType = "TextObject",
			TargetPaths = Paths.MaxLevelTexts,
		},
		{
			Key = "LevelProgressFill",
			ModelKey = "LevelProgressRatio",
			Operation = "SetSizeXScale",
			TargetType = "GuiObject",
			Path = Paths.LevelProgressFill,
		},
		{
			Key = "LevelProgressText",
			ModelKey = "LevelProgressText",
			Operation = "SetText",
			TargetType = "TextObject",
			Path = Paths.LevelProgressText,
		},
		{
			Key = "RequestButtonText",
			ModelKey = "RequestText",
			Operation = "SetText",
			TargetType = "TextObject",
			Path = Paths.RequestButtonText,
		},
	},
}

return RebirthPanelTheta
