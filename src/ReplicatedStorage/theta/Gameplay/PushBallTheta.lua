-- PushBallTheta
-- 推球玩法参数。场景路径放在 PushBallSceneTheta，关卡奖励/需求放在 StageTheta。

local PushBallTheta = {
	PushSpeed = 10,
	LateralSpeed = 14,
	LaneHalfWidth = 10,
	PlayerBehindBallDistance = 9,	-- 人和球的距离
	StartAlignmentDuration = 0.35,	-- 开始推球时，人物平滑移动到球后方站位所需时间
	BallRadius = 3,
	FinishWallBuffer = 2,
	PreserveSourceBallHeight = true,	-- 以场景中源球相对地面的高度作为推球高度，避免开始时上下跳变
	BallGroundOffsetY = 2,	-- 球和赛道的Y距离
	PlayerGroundOffsetY = 3.5,	-- 人和赛道的Y距离
	PlayerForwardOffset = 0,
	PlayerLateralOffset = 0,
	TrackRaycastHeight = 80,
	TrackRaycastDepth = 160,
	TrackGroundProbeDistance = 2, -- 跨越起步地面和赛道零件之间的小接缝
	InteractionDistance = 14,
	TeleportOffsetY = 5,
	-- 每条赛道拥有独立的一轮关卡进度；关卡编号在全局保持唯一。
	Tracks = {
		World2 = {
			FirstStageId = 1,
			LastStageId = 10,
			TravelDestinationId = "World2",
		},
		World3 = {
			FirstStageId = 11,
			LastStageId = 20,
			TravelDestinationId = "World3",
		},
	},
	PromptActionText = "Push",
	PromptObjectText = "Ball",
	DebugPushBall = false,
}

return PushBallTheta
