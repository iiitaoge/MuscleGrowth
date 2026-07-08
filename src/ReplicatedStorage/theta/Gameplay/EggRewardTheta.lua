-- EggRewardTheta
-- 蛋的奖池配置，只描述“这个蛋可能产出什么、权重是多少”。
-- 宠物名字、倍率、图片等展示信息从 PetTheta 通过 PetTypeId 派生，不在这里重复。

local EggRewardTheta = {
	-- 以稳定 EggID 为 key。新增蛋时，在这里补这个蛋的奖池。
	Egg1 = {
		-- RollWeight 是抽奖唯一概率真相；UI 概率应从权重派生。
		-- 不再保存旧 Chance 字段，避免 Chance 和 RollWeight 不一致。
		Rewards = {
			{ PetTypeId = "Pet1_1", RollWeight = 4000 },
			{ PetTypeId = "Pet1_2", RollWeight = 3000 },
			{ PetTypeId = "Pet1_3", RollWeight = 1500 },
			{ PetTypeId = "Pet1_4", RollWeight = 1000 },
			{ PetTypeId = "Pet1_5", RollWeight = 500 },
		},
	},
	Egg2 = {
		Rewards = {
			{ PetTypeId = "Pet2_1", RollWeight = 4000 },
			{ PetTypeId = "Pet2_2", RollWeight = 3000 },
			{ PetTypeId = "Pet2_3", RollWeight = 1500 },
			{ PetTypeId = "Pet2_4", RollWeight = 1000 },
			{ PetTypeId = "Pet2_5", RollWeight = 500 },
		},
	},
	PEgg1 = {
		Rewards = {
			{ PetTypeId = "PEgg1_1", RollWeight = 3000 },
		},
	},
	PEgg2 = {
		Rewards = {
			{ PetTypeId = "PEgg1_2", RollWeight = 3000 },
		},
	},
}

return EggRewardTheta
