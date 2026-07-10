-- AutoAreaSceneTheta
-- AutoAreaTheta defines gameplay rules. This file defines exact Workspace Touch paths.

local SceneTheta = require(script.Parent:WaitForChild("SceneTheta"))

local function workspacePath(path)
	return { RootKey = "Workspace", Path = path }
end

local AutoAreaSceneTheta = {
	-- 在这里填自动区 Touch 路径。TouchPath 是相对 Workspace 的精确路径。
	-- 复制新地图时只新增 Instance，不要复制 AutoAreaTheta 里的倍率/解锁配置。
	Instances = {
		UseSceneR1 = {
			AreaId = "R1",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R1", "Touch" }),
		},
		UseSceneR2 = {
			AreaId = "R2",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R2", "Touch" }),
		},
		UseSceneR3 = {
			AreaId = "R3",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R3", "Touch" }),
		},
		UseSceneR4 = {
			AreaId = "R4",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R4", "Touch" }),
		},
		UseSceneR5 = {
			AreaId = "R5",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R5", "Touch" }),
		},
		UseSceneR6 = {
			AreaId = "R6",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R6", "Touch" }),
		},
		UseSceneR7 = {
			AreaId = "R7",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R7", "Touch" }),
		},
		UseSceneR8 = {
			AreaId = "R8",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "R8", "Touch" }),
		},

		-- 新地图示例：
		-- World2R1 = {
		-- 	AreaId = "R1",
		-- 	TouchPath = workspacePath({ "World2", "SceneTrainAreas", "R1", "Touch" }),
		-- },

		World2R1 = {
			AreaId = "R1",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R1", "Touch" }),
		},
		World2R2 = {
			AreaId = "R2",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R2", "Touch" }),
		},
		World2R3 = {
			AreaId = "R3",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R3", "Touch" }),
		},
		World2R4 = {
			AreaId = "R4",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R4", "Touch" }),
		},
		World2R5 = {
			AreaId = "R5",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R5", "Touch" }),
		},
		World2R6 = {
			AreaId = "R6",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R6", "Touch" }),
		},
		World2R7 = {
			AreaId = "R7",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R7", "Touch" }),
		},
		World2R8 = {
			AreaId = "R8",
			TouchPath = workspacePath({ SceneTheta.WorkspaceRootName, SceneTheta.SceneTrainAreaRootName, "World2R8", "Touch" }),
		},
	},
}

return AutoAreaSceneTheta
