-- EggTheta.lua
-- 蛋的配置文件

local EggTheta = {
	StarterEgg = {
		DisplayName = "Starter Egg",	-- 初始蛋
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 100,
		InteractionDistance = 12,
		PetTypeIds = {
			"P1",
			"P2",
			"P3",
		},
	},
	PowerEgg = {
		DisplayName = "Power Egg",	-- 强力蛋
		SceneRootName = "SceneEgg",
		CostResource = "Trophies",
		CostAmount = 1000,
		InteractionDistance = 12,
		PetTypeIds = {
			"P2",
			"P3",
			"P4",
			"P5",
		},
	},
}

return EggTheta
