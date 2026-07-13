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
		Ball11 = {
			StageId = 11,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball11" } },
		},
		Ball12 = {
			StageId = 12,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball12" } },
		},
		Ball13 = {
			StageId = 13,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball13" } },
		},
		Ball14 = {
			StageId = 14,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball14" } },
		},
		Ball15 = {
			StageId = 15,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball15" } },
		},
		Ball16 = {
			StageId = 16,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball16" } },
		},
		Ball17 = {
			StageId = 17,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball17" } },
		},
		Ball18 = {
			StageId = 18,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball18" } },
		},
		Ball19 = {
			StageId = 19,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball19" } },
		},
		Ball20 = {
			StageId = 20,
			PathSpec = { RootKey = "Workspace", Path = { "Ballmod", "Ball20" } },
		},
	},

	Stages = {
		[1] = {
			StageId = 1,
			-- Base 下存在多个同名 Part；允许整个 Base，避免路径只解析到第一个同名子物体。
			StartSurfacePathSpec = { RootKey = "Workspace", Path = { "World2", "Base" } },
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
		[11] = {
			StageId = 11,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L11" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA11" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR11", "Teleport" } },
		},
		[12] = {
			StageId = 12,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L12" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA12" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR12", "Teleport" } },
		},
		[13] = {
			StageId = 13,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L13" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA13" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR13", "Teleport" } },
		},
		[14] = {
			StageId = 14,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L14" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA14" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR14", "Teleport" } },
		},
		[15] = {
			StageId = 15,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L15" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA15" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR15", "Teleport" } },
		},
		[16] = {
			StageId = 16,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L16" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA16" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR16", "Teleport" } },
		},
		[17] = {
			StageId = 17,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L17" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA17" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR17", "Teleport" } },
		},
		[18] = {
			StageId = 18,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L18" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA18" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR18", "Teleport" } },
		},
		[19] = {
			StageId = 19,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L19" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA19" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR19", "Teleport" } },
		},
		[20] = {
			StageId = 20,
			TrackPathSpec = { RootKey = "Workspace", Path = { "World3", "LeveLs", "L20" } },
			WallPathSpec = { RootKey = "Workspace", Path = { "Hint", "LA20" } },
			TeleportPathSpec = { RootKey = "Workspace", Path = { "TRTele", "TR20", "Teleport" } },
		},
	},
}

return PushBallSceneTheta
