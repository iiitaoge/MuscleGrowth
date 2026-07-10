-- 奖杯领奖台配置。奖励数值来自 StageTheta，当前文件只描述场景路径和倍率。

local function buildStageReturn(stageId)
	local trophyId = "TR" .. tostring(stageId)

	return {
		StageId = stageId,
		RootPathSpec = { RootKey = "Workspace", Path = { "TRTele", trophyId } },
		TravelDestinationId = "World2",

		FreeReturn = {
			Name = "FreeReturn",
			RewardMultiplier = 1,
			TextPathSpec = { RootKey = "ReturnNode", Path = { "Main", "Win", "BillboardGui", "Frame", "TextLabel" } },
		},

		VIPReturn = {
			Name = "VIPReturn",
			RewardMultiplier = 2,
			TextPathSpec = { RootKey = "ReturnNode", Path = { "Main", "Win", "BillboardGui", "Frame", "TextLabel" } },
		},
	}
end

local TrophyTheta = {
	StageReturns = {
		TR1 = buildStageReturn(1),
		TR2 = buildStageReturn(2),
		TR3 = buildStageReturn(3),
		TR4 = buildStageReturn(4),
		TR5 = buildStageReturn(5),
		TR6 = buildStageReturn(6),
		TR7 = buildStageReturn(7),
		TR8 = buildStageReturn(8),
		TR9 = buildStageReturn(9),
		TR10 = buildStageReturn(10),
	},
}

return TrophyTheta
