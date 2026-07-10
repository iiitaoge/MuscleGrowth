-- PushBallSceneTheta
-- 推球场景路径配置。球是交互实例，Stage 是墙和领奖台传送点。

local PushBallSceneTheta = {
	ForwardDirection = Vector3.new(0, 0, -1),
	LateralDirection = Vector3.new(1, 0, 0),

	Balls = {
		Ball1 = {
			StageId = 1,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball1" } },
		},
		Ball2 = {
			StageId = 2,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball2" } },
		},
		Ball3 = {
			StageId = 3,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball3" } },
		},
		Ball4 = {
			StageId = 4,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball4" } },
		},
		Ball5 = {
			StageId = 5,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball5" } },
		},
		Ball6 = {
			StageId = 6,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball6" } },
		},
		Ball7 = {
			StageId = 7,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball7" } },
		},
		Ball8 = {
			StageId = 8,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball8" } },
		},
		Ball9 = {
			StageId = 9,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball9" } },
		},
		Ball10 = {
			StageId = 10,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball10" } },
		},
	},

	Stages = {
		[1] = {
			StageId = 1,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L1" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA1" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR1", "Teleport" } },
		},
		[2] = {
			StageId = 2,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L2" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA2" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR2", "Teleport" } },
		},
		[3] = {
			StageId = 3,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L3" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA3" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR3", "Teleport" } },
		},
		[4] = {
			StageId = 4,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L4" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA4" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR4", "Teleport" } },
		},
		[5] = {
			StageId = 5,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L5" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA5" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR5", "Teleport" } },
		},
		[6] = {
			StageId = 6,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L6" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA6" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR6", "Teleport" } },
		},
		[7] = {
			StageId = 7,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L7" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA7" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR7", "Teleport" } },
		},
		[8] = {
			StageId = 8,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L8" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA8" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR8", "Teleport" } },
		},
		[9] = {
			StageId = 9,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L9" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA9" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR9", "Teleport" } },
		},
		[10] = {
			StageId = 10,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World2", "LeveLs", "L10" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA10" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR10", "Teleport" } },
		},
	},
}

return PushBallSceneTheta
