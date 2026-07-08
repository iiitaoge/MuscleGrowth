-- Travel panel UI path contract.

local TravelPanelTheta = {
	HudScreenGuiName = "HUD",
	ScreenGuiName = "Main",

	Paths = {
		OpenButton = { "LeftButtons", "Button", "Teleport" },	--打开按钮
		PanelRoot = { "Teleport" },	--传送面板
		CloseButton = { "Teleport", "Info", "Title", "Close" },	--关闭按钮
	},

	DestinationButtons = {
		World1 = { --传送世界一
			DestinationId = "World1",
			Path = { "Teleport", "Info", "Info", "List", "World1", "Button", "Teleport" },
		},
		World2 = {	--传送世界二
			DestinationId = "World2",
			Path = { "Teleport", "Info", "Info", "List", "World2", "Button", "Teleport" },
		},
	},
}

return TravelPanelTheta
