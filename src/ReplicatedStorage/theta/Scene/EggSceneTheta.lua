-- EggSceneTheta
-- Eggs defines shared egg identity/source data. Instances defines exact Workspace placements.

local SceneTheta = require(script.Parent:WaitForChild("SceneTheta"))

local function sourcePath(path)
	return { RootKey = "ServerStorage", Path = path }
end

local function workspacePath(path)
	return { RootKey = "Workspace", Path = path }
end

local EggSceneTheta = {
	Eggs = {
		Egg1 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePath = sourcePath({ SceneTheta.ServerToUseSceneRootName, SceneTheta.EggSourceFolderName, "Egg1" }),
		},
		Egg2 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePath = sourcePath({ SceneTheta.ServerToUseSceneRootName, SceneTheta.EggSourceFolderName, "Egg2" }),
		},
		PEgg1 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePath = sourcePath({ SceneTheta.ServerToUseSceneRootName, SceneTheta.EggSourceFolderName, "PEgg1" }),
		},
		PEgg2 = {
			PromptPartName = SceneTheta.EggPromptPartName,
			InteractionDistance = SceneTheta.EggInteractionDistance,
			SourcePath = sourcePath({ SceneTheta.ServerToUseSceneRootName, SceneTheta.EggSourceFolderName, "PEgg2" }),
		},
	},

	-- 在这里填蛋的场景路径。HolderPath 是相对 Workspace 的精确路径。
	-- 复制新地图时只新增 Instance，不要复制 EggId 对应的价格/奖池配置。
	Instances = {
		UseSceneEgg1 = {
			EggId = "Egg1",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "Egg1" }),
		},
		UseSceneEgg2 = {
			EggId = "Egg2",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "Egg2" }),
		},
		UseScenePEgg1 = {
			EggId = "PEgg1",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "PEgg1" }),
		},
		UseScenePEgg2 = {
			EggId = "PEgg2",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "PEgg2" }),
		},

		World2Egg1 = {
			EggId = "Egg1",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "World2Egg1" }),
		},
		World2Egg2 = {
			EggId = "Egg2",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "World2Egg2" }),
		},
		World2PEgg1 = {
			EggId = "PEgg1",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "World2PEgg1" }),
		},
		World2PEgg2 = {
			EggId = "PEgg2",
			HolderPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneEggRootName, "World2PEgg2" }),
		},
		-- 新地图示例：
		-- World2Egg1 = {
		-- 	EggId = "Egg1",
		-- 	HolderPath = workspacePath({ "World2", "SceneEgg", "Egg1" }),
		-- },
	},
}

return EggSceneTheta
