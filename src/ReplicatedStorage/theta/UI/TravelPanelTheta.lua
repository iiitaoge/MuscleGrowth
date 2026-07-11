-- 传送的路径配置

local TravelPanelTheta = {
	HudScreenGuiName = "HUD",
	ScreenGuiName = "Main",

	Paths = {
		OpenButton = { RootKey = "HUDScreenGui", Path = { "LeftButtons", "Button", "Teleport" } },	--打开按钮
		PanelRoot = { RootKey = "ScreenGui", Path = { "Teleport" } },	--传送面板
		CloseButton = { RootKey = "ScreenGui", Path = { "Teleport", "Info", "Title", "Close" } },	--关闭按钮
	},

	DestinationButtons = {
		World1 = { --传送世界一
			DestinationId = "World1",
			PathSpec = { RootKey = "ScreenGui", Path = { "Teleport", "Info", "Info", "List", "World1", "Button", "Teleport" } },
		},
		World2 = {	--传送世界二
			DestinationId = "World2",
			PathSpec = { RootKey = "ScreenGui", Path = { "Teleport", "Info", "Info", "List", "World2", "Button", "Teleport" } },
		},
		World3 = {	--传送世界三
			DestinationId = "World3",
			PathSpec = { RootKey = "ScreenGui", Path = { "Teleport", "Info", "Info", "List", "World2", "Button", "Teleport" } },
		},
	},
}

return TravelPanelTheta
