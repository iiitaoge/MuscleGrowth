-- EggInteractionController
-- 客户端蛋交互输入层，负责 Prompt 绑定和本地距离体验判断。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local EggSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("EggSceneTheta"))
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local EggInteractionController = {}

-- 初始化蛋交互控制器。
function EggInteractionController.Init(sceneQuery, eggPanelView, snapshotController)
	-- 取得蛋的交互节点。
	local function getEggInteractionNode(eggId)
		local eggSceneConfig = EggSceneTheta[eggId]
		if type(eggSceneConfig) ~= "table" then
			return nil
		end

		local sceneEgg = sceneQuery.GetSceneChild(eggSceneConfig.SceneRootName or SceneTheta.SceneEggRootName)
		local sceneNodeName = eggSceneConfig.SceneNodeName or eggId
		local promptPartName = eggSceneConfig.PromptPartName or SceneTheta.EggPromptPartName
		local eggHolder = sceneEgg and sceneEgg:FindFirstChild(sceneNodeName)
		return eggHolder and (eggHolder:FindFirstChild(promptPartName) or eggHolder)
	end

	-- 判断本地玩家是否仍在蛋交互距离内。
	local function isPlayerNearEgg(eggId)
		local eggSceneConfig = EggSceneTheta[eggId]
		local root = sceneQuery.GetPlayerRootPart()
		local interactionPosition = sceneQuery.GetInstancePosition(getEggInteractionNode(eggId))
		if not eggSceneConfig or not root or not interactionPosition then
			return false
		end

		local interactionDistance = tonumber(eggSceneConfig.InteractionDistance) or SceneTheta.EggInteractionDistance
		return (root.Position - interactionPosition).Magnitude <= interactionDistance + 2
	end

	-- 绑定单个蛋的 ProximityPrompt。
	local function bindEggPrompt(eggId)
		local eggSceneConfig = EggSceneTheta[eggId]
		if type(eggSceneConfig) ~= "table" then
			warn("Missing egg scene config: " .. tostring(eggId))
			return
		end

		local sceneEgg = sceneQuery.GetSceneChild(eggSceneConfig.SceneRootName or SceneTheta.SceneEggRootName)
		local sceneNodeName = eggSceneConfig.SceneNodeName or eggId
		local eggHolder = sceneEgg and sceneEgg:WaitForChild(sceneNodeName, 10)
		if not eggHolder then
			warn("Missing egg holder: " .. tostring(sceneNodeName))
			return
		end

		local prompt = eggHolder:FindFirstChildWhichIsA("ProximityPrompt", true)
		if not prompt then
			warn("Missing egg prompt: " .. eggId)
			return
		end

		-- Prompt 触发后打开对应蛋面板并刷新快照。
		local function handlePromptTriggered()
			eggPanelView.Open(eggId, snapshotController.GetLatestData())
			snapshotController.RefreshFromServer()
		end

		prompt.Triggered:Connect(handlePromptTriggered)
	end

	-- 绑定配置里的所有蛋 Prompt。
	local function bindAll()
		for eggId, eggSceneConfig in pairs(EggSceneTheta) do
			if type(eggId) == "string" and type(eggSceneConfig) == "table" then
				bindEggPrompt(eggId)
			end
		end
	end

	return {
		BindAll = bindAll,
		IsPlayerNearEgg = isPlayerNearEgg,
	}
end

return EggInteractionController
