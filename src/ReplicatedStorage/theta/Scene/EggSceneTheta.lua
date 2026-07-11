-- EggSceneTheta
-- Eggs defines shared egg identity/source data. Instances defines exact Workspace placements.

local SceneTheta = require(script.Parent:WaitForChild("SceneTheta"))

local EggSceneTheta = {
	Eggs = {
		Egg1 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePathSpec = { RootKey = "ServerStorage", Path = { "ToUseScene", "Egg", "Egg1" } },
		},
		Egg2 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePathSpec = { RootKey = "ServerStorage", Path = { "ToUseScene", "Egg", "Egg2" } },
		},
		PEgg1 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePathSpec = { RootKey = "ServerStorage", Path = { "ToUseScene", "Egg", "PEgg1" } },
		},
		PEgg2 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePathSpec = { RootKey = "ServerStorage", Path = { "ToUseScene", "Egg", "PEgg2" } },
		},
	},

	-- 在这里填蛋的场景路径规格。HolderPathSpec 的 Path 相对 Workspace。
	-- 复制新地图时只新增 Instance，不要复制 EggId 对应的价格/奖池配置。
	Instances = {
		UseSceneEgg1 = {
			EggId = "Egg1",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "Egg1" } },
		},
		UseSceneEgg2 = {
			EggId = "Egg2",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "Egg2" } },
		},
		UseScenePEgg1 = {
			EggId = "PEgg1",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "PEgg1" } },
		},
		UseScenePEgg2 = {
			EggId = "PEgg2",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "PEgg2" } },
		},

		World2Egg1 = {
			EggId = "Egg1",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World2Egg1" } },
		},
		World2Egg2 = {
			EggId = "Egg2",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World2Egg2" } },
		},
		World2PEgg1 = {
			EggId = "PEgg1",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World2PEgg1" } },
		},
		World2PEgg2 = {
			EggId = "PEgg2",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World2PEgg2" } },
		},
		World3Egg1 = {
			EggId = "Egg1",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World3Egg1" } },
		},
		World3Egg2 = {
			EggId = "Egg2",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World3Egg2" } },
		},
		World3PEgg1 = {
			EggId = "PEgg1",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World3PEgg1" } },
		},
		World3PEgg2 = {
			EggId = "PEgg2",
			HolderPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneEgg", "World3PEgg2" } },
		},
		-- 新地图示例：
		-- World2Egg1 = {
		-- 	EggId = "Egg1",
		-- 	HolderPathSpec = { RootKey = "Workspace", Path = { "World2", "SceneEgg", "Egg1" } },
		-- },
	},
}

return EggSceneTheta
