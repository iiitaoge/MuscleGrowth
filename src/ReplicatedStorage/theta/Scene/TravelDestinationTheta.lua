-- 传送目的地的信息 Part
local function workspacePath(path)
	return { RootKey = "Workspace", Path = path }
end

local TravelDestinationTheta = {
	Destinations = {
		World1 = {
			Path = workspacePath({ "World1", "World1Spawn" }),
			OffsetY = 5,
		},

		World2 = {
			Path = workspacePath({ "World2", "World2Spawn" }),
			OffsetY = 5,
		},
	},
}

return TravelDestinationTheta
