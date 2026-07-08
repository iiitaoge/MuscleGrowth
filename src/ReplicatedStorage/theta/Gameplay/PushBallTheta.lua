-- PushBallTheta
-- 推球玩法参数。场景路径放在 PushBallSceneTheta，关卡奖励/需求放在 StageTheta。

local PushBallTheta = {
	PushSpeed = 10,
	LateralSpeed = 14,
	LaneHalfWidth = 10,
	PlayerBehindBallDistance = 5,
	BallRadius = 3,
	InteractionDistance = 14,
	TeleportOffsetY = 5,
	FirstStageId = 1,
	LastStageId = 10,
	PromptActionText = "Push",
	PromptObjectText = "Ball",
}

return PushBallTheta
