-- PushBallSceneTheta
-- 推球场景路径配置。球是交互实例，Stage 是墙和领奖台传送点。

local PushBallSceneTheta = {
	ForwardDirection = Vector3.new(0, 0, -1),
	LateralDirection = Vector3.new(1, 0, 0),

	Balls = {
		Ball1 = {
			StageId = 1,
			Path = { "Ballmod", "Ball1" },
		},
		Ball2 = {
			StageId = 2,
			Path = { "Ballmod", "Ball2" },
		},
		Ball3 = {
			StageId = 3,
			Path = { "Ballmod", "Ball3" },
		},
		Ball4 = {
			StageId = 4,
			Path = { "Ballmod", "Ball4" },
		},
		Ball5 = {
			StageId = 5,
			Path = { "Ballmod", "Ball5" },
		},
		Ball6 = {
			StageId = 6,
			Path = { "Ballmod", "Ball6" },
		},
		Ball7 = {
			StageId = 7,
			Path = { "Ballmod", "Ball7" },
		},
		Ball8 = {
			StageId = 8,
			Path = { "Ballmod", "Ball8" },
		},
		Ball9 = {
			StageId = 9,
			Path = { "Ballmod", "Ball9" },
		},
		Ball10 = {
			StageId = 10,
			Path = { "Ballmod", "Ball10" },
		},
	},

	Stages = {
		[1] = {
			StageId = 1,
			TrackPath = { "World2", "LeveLs", "L1" },
			WallPath = { "Hint", "LA1" },
			TeleportPath = { "TRTele", "TR1", "Teleport" },	-- 测试
		},
		[2] = {
			StageId = 2,
			TrackPath = { "World2", "LeveLs", "L2" },
			WallPath = { "Hint", "LA2" },
			TeleportPath = { "TRTele", "TR2", "Teleport" },
		},
		[3] = {
			StageId = 3,
			TrackPath = { "World2", "LeveLs", "L3" },
			WallPath = { "Hint", "LA3" },
			TeleportPath = { "TRTele", "TR3", "Teleport" },
		},
		[4] = {
			StageId = 4,
			TrackPath = { "World2", "LeveLs", "L4" },
			WallPath = { "Hint", "LA4" },
			TeleportPath = { "TRTele", "TR4", "Teleport" },
		},
		[5] = {
			StageId = 5,
			TrackPath = { "World2", "LeveLs", "L5" },
			WallPath = { "Hint", "LA5" },
			TeleportPath = { "TRTele", "TR5", "Teleport" },
		},
		[6] = {
			StageId = 6,
			TrackPath = { "World2", "LeveLs", "L6" },
			WallPath = { "Hint", "LA6" },
			TeleportPath = { "TRTele", "TR6", "Teleport" },	-- 测试修改
		},
		[7] = {
			StageId = 7,
			TrackPath = { "World2", "LeveLs", "L7" },
			WallPath = { "Hint", "LA7" },
			TeleportPath = { "TRTele", "TR7", "Teleport" },
		},
		[8] = {
			StageId = 8,
			TrackPath = { "World2", "LeveLs", "L8" },
			WallPath = { "Hint", "LA8" },
			TeleportPath = { "TRTele", "TR8", "Teleport" },
		},
		[9] = {
			StageId = 9,
			TrackPath = { "World2", "LeveLs", "L9" },
			WallPath = { "Hint", "LA9" },
			TeleportPath = { "TRTele", "TR9", "Teleport" },
		},
		[10] = {
			StageId = 10,
			TrackPath = { "World2", "LeveLs", "L10" },
			WallPath = { "Hint", "LA10" },
			TeleportPath = { "TRTele", "TR10", "Teleport" },
		},
	},
}

return PushBallSceneTheta
