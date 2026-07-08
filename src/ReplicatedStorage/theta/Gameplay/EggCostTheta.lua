-- EggCostTheta
-- 蛋的消耗配置，只描述“抽这个蛋要花什么、花多少”。
-- 这里不决定玩家余额是否足够，也不写玩家状态；扣费仍然属于服务端 T。

local EggCostTheta = {
	-- 蛋系统允许消耗的资源白名单。
	-- CostResource 必须在这里出现，避免配置误写成 Strength、OwnedPets 等非抽蛋资源。
	AllowedCostResources = {
		Trophies = true,
	},

	-- 以稳定 EggID 为 key。新增蛋时，在这里补这个蛋的消耗配置。
	Costs = {
		Egg1 = {
			-- 玩家进度状态里的可消费资源类型。
			
			-- 单次抽奖消耗数量；多抽由调用方按次数计算总消耗。
			CostAmount = 25,
		},
		Egg2 = {
			CostResource = "Trophies",
			CostAmount = 1250,
		},
		PEgg1 = {
			CostResource = "Trophies",
			CostAmount = 59,
		},
		PEgg2 = {
			CostResource = "Trophies",
			CostAmount = 99,
		},
	},
}

return EggCostTheta
