local EggTheta = {
	Egg1 = {
		DisplayName = "Egg1",
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 25,
		InteractionDistance = 12,
		ModelIcon = "rbxassetid://118155185854767",
		Rewards = {
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
	Egg3 = {
		DisplayName = "Egg3",
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 35000,
		InteractionDistance = 12,
		ModelIcon = "rbxassetid://89955313489403",
		Rewards = {
			{ PetTypeId = "Pet3_1", Chance = 48, RollWeight = 4800 },
			{ PetTypeId = "Pet3_2", Chance = 30, RollWeight = 3000 },
			{ PetTypeId = "Pet3_3", Chance = 15, RollWeight = 1500 },
			{ PetTypeId = "Pet3_4", Chance = 5, RollWeight = 500 },
			{ PetTypeId = "Pet3_5", Chance = 2, RollWeight = 200 },
		},
	},
	Egg4 = {
		DisplayName = "Egg4",
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 150000,
		InteractionDistance = 12,
		ModelIcon = "rbxassetid://126307068721195",
		Rewards = {
			{ PetTypeId = "Pet4_1", Chance = 48, RollWeight = 4800 },
			{ PetTypeId = "Pet4_2", Chance = 30, RollWeight = 3000 },
			{ PetTypeId = "Pet4_3", Chance = 15, RollWeight = 1500 },
			{ PetTypeId = "Pet4_4", Chance = 5, RollWeight = 500 },
			{ PetTypeId = "Pet4_5", Chance = 2, RollWeight = 200 },
		},
	},
	PEgg1 = {
		DisplayName = "PEgg1",
		SceneRootName = "SceneEgg",
		CostResource = "Robux",
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
		CostResource = "Robux",
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
