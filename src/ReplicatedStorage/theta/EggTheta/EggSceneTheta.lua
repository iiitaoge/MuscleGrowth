-- EggSceneTheta
-- 蛋的场景、交互、源模型映射配置。
-- 这里把稳定 EggID 和 Workspace holder、交互节点、资源库源模型解耦。
-- y 层用它验证玩家是否靠近蛋，WorldSync 用它替换场景白模。

local SceneTheta = require(script.Parent.Parent:WaitForChild("SceneTheta"))

local EggSceneTheta = {
	-- 以稳定 EggID 为 key。SceneNodeName/SourceNodeName 可以和 EggID 不同。
	Egg1 = {
		-- WorkspaceRootName 下的蛋场景总目录。
		SceneRootName = SceneTheta.SceneEggRootName,
		-- 这个蛋在场景目录里的具体 holder 名。
		SceneNodeName = "Egg1",
		-- holder 内用于 Prompt/距离检测的交互节点名。
		PromptPartName = SceneTheta.EggPromptPartName,
		-- 服务端交互合法距离，不是 UI 展示距离。
		InteractionDistance = SceneTheta.EggInteractionDistance,
		-- ServerStorage/ReplicatedStorage 的 ToUseScene 下，蛋源模型所在目录。
		SourceRootName = SceneTheta.EggSourceFolderName,
		-- 资源目录里的具体源模型名。
		SourceNodeName = "Egg1",
	},
	Egg2 = {
		SceneRootName = SceneTheta.SceneEggRootName,
		SceneNodeName = "Egg2",
		PromptPartName = SceneTheta.EggPromptPartName,
		InteractionDistance = SceneTheta.EggInteractionDistance,
		SourceRootName = SceneTheta.EggSourceFolderName,
		SourceNodeName = "Egg2",
	},
	PEgg1 = {
		SceneRootName = SceneTheta.SceneEggRootName,
		SceneNodeName = "PEgg1",
		PromptPartName = SceneTheta.EggPromptPartName,
		InteractionDistance = SceneTheta.EggInteractionDistance,
		SourceRootName = SceneTheta.EggSourceFolderName,
		SourceNodeName = "PEgg1",
	},
	PEgg2 = {
		SceneRootName = SceneTheta.SceneEggRootName,
		SceneNodeName = "PEgg2",
		PromptPartName = SceneTheta.EggPromptPartName,
		InteractionDistance = SceneTheta.EggInteractionDistance,
		SourceRootName = SceneTheta.EggSourceFolderName,
		SourceNodeName = "PEgg2",
	},
}

return EggSceneTheta
