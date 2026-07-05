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
}

return RebirthPanelTheta
