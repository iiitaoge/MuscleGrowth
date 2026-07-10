-- 传送的路径配置

local function hudPath(path)
	return { RootKey = "HUDScreenGui", Path = path }
end

local function screenGuiPath(path)
	return { RootKey = "ScreenGui", Path = path }
end

local TravelPanelTheta = {
	HudScreenGuiName = "HUD",
	ScreenGuiName = "Main",

	Paths = {
		OpenButton = hudPath({ "LeftButtons", "Button", "Teleport" }),	--打开按钮
		PanelRoot = screenGuiPath({ "Teleport" }),	--传送面板
		CloseButton = screenGuiPath({ "Teleport", "Info", "Title", "Close" }),	--关闭按钮
	},

	DestinationButtons = {
		World1 = { --传送世界一
			DestinationId = "World1",
			Path = screenGuiPath({ "Teleport", "Info", "Info", "List", "World1", "Button", "Teleport" }),
		},
		World2 = {	--传送世界二
			DestinationId = "World2",
			Path = screenGuiPath({ "Teleport", "Info", "Info", "List", "World2", "Button", "Teleport" }),
		},
	},
}

return TravelPanelTheta
