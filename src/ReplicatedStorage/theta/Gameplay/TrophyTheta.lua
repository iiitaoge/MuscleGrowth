-- 奖杯领奖台配置。奖励数值来自 StageTheta，当前文件只描述场景路径和倍率。

local function buildStageReturn(stageId, travelDestinationId)
	local trophyId = "TR" .. tostring(stageId)

	return {
		StageId = stageId,
		RootPathSpec = { RootKey = "Workspace", Path = { "TRTele", trophyId } },
		TravelDestinationId = travelDestinationId or "World2",

		FreeReturn = {
			Name = "FreeReturn",
			RewardMultiplier = 1,
			TextPathSpec = { RootKey = "ReturnNode", Path = { "Main", "Win", "BillboardGui", "Frame", "TextLabel" } },
		},

		VIPReturn = {
			Name = "VIPReturn",
			RewardMultiplier = 2,
			TextPathSpec = { RootKey = "ReturnNode", Path = { "Main", "Win vip", "BillboardGui", "WIN", "TextLabel" } },
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
		TR11 = buildStageReturn(11, "World3"),
		TR12 = buildStageReturn(12, "World3"),
		TR13 = buildStageReturn(13, "World3"),
		TR14 = buildStageReturn(14, "World3"),
		TR15 = buildStageReturn(15, "World3"),
		TR16 = buildStageReturn(16, "World3"),
		TR17 = buildStageReturn(17, "World3"),
		TR18 = buildStageReturn(18, "World3"),
		TR19 = buildStageReturn(19, "World3"),
		TR20 = buildStageReturn(20, "World3"),
	},
}

return TrophyTheta
