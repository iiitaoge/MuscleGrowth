-- PushBallSceneTheta
-- 推球场景路径配置。TeleportPath 先预留，后续填 Workspace 下的传送点路径。

local PushBallSceneTheta = {
	BallPath = { "Ballmod", "BM1", "ball" },
	ForwardDirection = Vector3.new(0, 0, -1),
	LateralDirection = Vector3.new(1, 0, 0),

	Stages = {
		[1] = {
			StageId = 1,
			WallPath = { "Hint", "LA1" },
			TeleportPath = {"TR1", "Teleport"},
		},
		[2] = {
			StageId = 2,
			WallPath = { "Hint", "LA2" },
			TeleportPath = {"TR2", "Teleport"},
		},
		[3] = {
			StageId = 3,
			WallPath = { "Hint", "LA3" },
			TeleportPath = {"TR3", "Teleport"},
		},
		[4] = {
			StageId = 4,
			WallPath = { "Hint", "LA4" },
			TeleportPath = {"TR4", "Teleport"},
		},
		[5] = {
			StageId = 5,
			WallPath = { "Hint", "LA5" },
			TeleportPath = {"TR5", "Teleport"},
		},
		[6] = {
			StageId = 6,
			WallPath = { "Hint", "LA6" },
			TeleportPath = {"TR6", "Teleport"},
		},
		[7] = {
			StageId = 7,
			WallPath = { "Hint", "LA7" },
			TeleportPath = {"TR7", "Teleport"},
		},
		[8] = {
			StageId = 8,
			WallPath = { "Hint", "LA8" },
			TeleportPath = {"TR8", "Teleport"},
		},
		[9] = {
			StageId = 9,
			WallPath = { "Hint", "LA9" },
			TeleportPath = {"TR9", "Teleport"},
		},
		[10] = {
			StageId = 10,
			WallPath = { "Hint", "LA10" },
			TeleportPath = {"TR10", "Teleport"},
		},
	},
}

return PushBallSceneTheta
