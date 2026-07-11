-- PushBallTheta
-- 推球玩法参数。场景路径放在 PushBallSceneTheta，关卡奖励/需求放在 StageTheta。

local PushBallTheta = {
	PushSpeed = 10,
	LateralSpeed = 14,
	LaneHalfWidth = 10,
	PlayerBehindBallDistance = 7,	-- 人和球的距离
	BallRadius = 3,
	FinishWallBuffer = 2,
	BallGroundOffsetY = 2,	-- 球和赛道的Y距离
	PlayerGroundOffsetY = 3.5,	-- 人和赛道的Y距离
	PlayerForwardOffset = 0,
	PlayerLateralOffset = 0,
	TrackRaycastHeight = 80,
	TrackRaycastDepth = 160,
	InteractionDistance = 14,
	TeleportOffsetY = 5,
	FirstStageId = 1,
	LastStageId = 20,
	PromptActionText = "Push",
	PromptObjectText = "Ball",
	DebugPushBall = false,
}

return PushBallTheta
