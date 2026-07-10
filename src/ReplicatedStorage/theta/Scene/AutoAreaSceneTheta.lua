-- AutoAreaSceneTheta
-- AutoAreaTheta defines gameplay rules. This file defines exact Workspace Touch paths.

local AutoAreaSceneTheta = {
	-- 在这里填自动区 Touch 路径规格。TouchPathSpec 的 Path 相对 Workspace。
	-- 复制新地图时只新增 Instance，不要复制 AutoAreaTheta 里的倍率/解锁配置。
	Instances = {
		UseSceneR1 = {
			AreaId = "R1",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R1", "Touch" } },
		},
		UseSceneR2 = {
			AreaId = "R2",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R2", "Touch" } },
		},
		UseSceneR3 = {
			AreaId = "R3",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R3", "Touch" } },
		},
		UseSceneR4 = {
			AreaId = "R4",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R4", "Touch" } },
		},
		UseSceneR5 = {
			AreaId = "R5",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R5", "Touch" } },
		},
		UseSceneR6 = {
			AreaId = "R6",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R6", "Touch" } },
		},
		UseSceneR7 = {
			AreaId = "R7",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R7", "Touch" } },
		},
		UseSceneR8 = {
			AreaId = "R8",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "R8", "Touch" } },
		},

		-- 新地图示例：
		-- World2R1 = {
		-- 	AreaId = "R1",
		-- 	TouchPathSpec = { RootKey = "Workspace", Path = { "World2", "SceneTrainAreas", "R1", "Touch" } },
		-- },

		World2R1 = {
			AreaId = "R1",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R1", "Touch" } },
		},
		World2R2 = {
			AreaId = "R2",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R2", "Touch" } },
		},
		World2R3 = {
			AreaId = "R3",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R3", "Touch" } },
		},
		World2R4 = {
			AreaId = "R4",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R4", "Touch" } },
		},
		World2R5 = {
			AreaId = "R5",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R5", "Touch" } },
		},
		World2R6 = {
			AreaId = "R6",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R6", "Touch" } },
		},
		World2R7 = {
			AreaId = "R7",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R7", "Touch" } },
		},
		World2R8 = {
			AreaId = "R8",
			TouchPathSpec = { RootKey = "Workspace", Path = { "UseScene", "SceneTrainAreas", "World2R8", "Touch" } },
		},
	},
}

return AutoAreaSceneTheta
