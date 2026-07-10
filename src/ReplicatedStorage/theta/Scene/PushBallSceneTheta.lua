-- PushBallSceneTheta
-- 推球场景路径配置。球是交互实例，Stage 是墙和领奖台传送点。

local function workspacePath(path)
	return { RootKey = "Workspace", Path = path }
end

local PushBallSceneTheta = {
	ForwardDirection = Vector3.new(0, 0, -1),
	LateralDirection = Vector3.new(1, 0, 0),

	Balls = {
		Ball1 = {
			StageId = 1,
			Path = workspacePath({ "Ballmod", "Ball1" }),
		},
		Ball2 = {
			StageId = 2,
			Path = workspacePath({ "Ballmod", "Ball2" }),
		},
		Ball3 = {
			StageId = 3,
			Path = workspacePath({ "Ballmod", "Ball3" }),
		},
		Ball4 = {
			StageId = 4,
			Path = workspacePath({ "Ballmod", "Ball4" }),
		},
		Ball5 = {
			StageId = 5,
			Path = workspacePath({ "Ballmod", "Ball5" }),
		},
		Ball6 = {
			StageId = 6,
			Path = workspacePath({ "Ballmod", "Ball6" }),
		},
		Ball7 = {
			StageId = 7,
			Path = workspacePath({ "Ballmod", "Ball7" }),
		},
		Ball8 = {
			StageId = 8,
			Path = workspacePath({ "Ballmod", "Ball8" }),
		},
		Ball9 = {
			StageId = 9,
			Path = workspacePath({ "Ballmod", "Ball9" }),
		},
		Ball10 = {
			StageId = 10,
			Path = workspacePath({ "Ballmod", "Ball10" }),
		},
	},

	Stages = {
		[1] = {
			StageId = 1,
			TrackPath = workspacePath({ "World2", "LeveLs", "L1" }),
			WallPath = workspacePath({ "Hint", "LA1" }),
			TeleportPath = workspacePath({ "TRTele", "TR1", "Teleport" }),
		},
		[2] = {
			StageId = 2,
			TrackPath = workspacePath({ "World2", "LeveLs", "L2" }),
			WallPath = workspacePath({ "Hint", "LA2" }),
			TeleportPath = workspacePath({ "TRTele", "TR2", "Teleport" }),
		},
		[3] = {
			StageId = 3,
			TrackPath = workspacePath({ "World2", "LeveLs", "L3" }),
			WallPath = workspacePath({ "Hint", "LA3" }),
			TeleportPath = workspacePath({ "TRTele", "TR3", "Teleport" }),
		},
		[4] = {
			StageId = 4,
			TrackPath = workspacePath({ "World2", "LeveLs", "L4" }),
			WallPath = workspacePath({ "Hint", "LA4" }),
			TeleportPath = workspacePath({ "TRTele", "TR4", "Teleport" }),
		},
		[5] = {
			StageId = 5,
			TrackPath = workspacePath({ "World2", "LeveLs", "L5" }),
			WallPath = workspacePath({ "Hint", "LA5" }),
			TeleportPath = workspacePath({ "TRTele", "TR5", "Teleport" }),
		},
		[6] = {
			StageId = 6,
			TrackPath = workspacePath({ "World2", "LeveLs", "L6" }),
			WallPath = workspacePath({ "Hint", "LA6" }),
			TeleportPath = workspacePath({ "TRTele", "TR6", "Teleport" }),
		},
		[7] = {
			StageId = 7,
			TrackPath = workspacePath({ "World2", "LeveLs", "L7" }),
			WallPath = workspacePath({ "Hint", "LA7" }),
			TeleportPath = workspacePath({ "TRTele", "TR7", "Teleport" }),
		},
		[8] = {
			StageId = 8,
			TrackPath = workspacePath({ "World2", "LeveLs", "L8" }),
			WallPath = workspacePath({ "Hint", "LA8" }),
			TeleportPath = workspacePath({ "TRTele", "TR8", "Teleport" }),
		},
		[9] = {
			StageId = 9,
			TrackPath = workspacePath({ "World2", "LeveLs", "L9" }),
			WallPath = workspacePath({ "Hint", "LA9" }),
			TeleportPath = workspacePath({ "TRTele", "TR9", "Teleport" }),
		},
		[10] = {
			StageId = 10,
			TrackPath = workspacePath({ "World2", "LeveLs", "L10" }),
			WallPath = workspacePath({ "Hint", "LA10" }),
			TeleportPath = workspacePath({ "TRTele", "TR10", "Teleport" }),
		},
	},
}

return PushBallSceneTheta
