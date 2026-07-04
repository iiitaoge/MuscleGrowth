
-- 蛋配置文件：名字 在目录中的名字（需要解耦） 花费资源的类型：奖杯 花费的数目 

local EggTheta = {
	Egg1 = {
		DisplayName = "Egg1",	--名字
		SceneRootName = "SceneEgg",		--在目录中的名字
		CostResource = "Trophies",		-- 花费资源的类型
		CostAmount = 25,		--花费的数目
		InteractionDistance = 12,	--互动距离
		ModelIcon = "rbxassetid://118155185854767",  --贴图
		Rewards = {									--里面存着的宠物和倍率
			{ PetTypeId = "Pet1_1", Chance = 40, RollWeight = 4000 },
			{ PetTypeId = "Pet1_2", Chance = 30, RollWeight = 3000 },
			{ PetTypeId = "Pet1_3", Chance = 15, RollWeight = 1500 },
			{ PetTypeId = "Pet1_4", Chance = 10, RollWeight = 1000 },
			{ PetTypeId = "Pet1_5", Chance = 5, RollWeight = 500 },
		},
	},
	Egg2 = {
		DisplayName = "Egg2",
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 1250,
		InteractionDistance = 12,
		ModelIcon = "rbxassetid://106440868789112",
		Rewards = {
			{ PetTypeId = "Pet2_1", Chance = 40, RollWeight = 4000 },
			{ PetTypeId = "Pet2_2", Chance = 30, RollWeight = 3000 },
			{ PetTypeId = "Pet2_3", Chance = 15, RollWeight = 1500 },
			{ PetTypeId = "Pet2_4", Chance = 10, RollWeight = 1000 },
			{ PetTypeId = "Pet2_5", Chance = 5, RollWeight = 500 },
		},
	},
	PEgg1 = {
		DisplayName = "PEgg1",
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 59,
		InteractionDistance = 12,
		ModelIcon = "rbxassetid://124769272116110",
		Rewards = {
			{ PetTypeId = "PEgg1_1", Chance = 30, RollWeight = 3000 },
		},
	},
	PEgg2 = {
		DisplayName = "PEgg2",
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 99,
		InteractionDistance = 12,
		ModelIcon = "rbxassetid://94227745241287",
		Rewards = {
			{ PetTypeId = "PEgg1_2", Chance = 30, RollWeight = 3000 },
		},
	},
}

-- 配置转化
for _, eggConfig in pairs(EggTheta) do
	eggConfig.PetTypeIds = {}
	for _, reward in ipairs(eggConfig.Rewards) do
		table.insert(eggConfig.PetTypeIds, reward.PetTypeId)
	end
end

return EggTheta
