-- SceneQuery
-- 客户端场景查询工具，只封装本地 Workspace 查找和角色位置读取。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local SceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("SceneTheta"))

local SceneQuery = {}

-- 初始化场景查询工具。
function SceneQuery.Init(player)
	-- 获取 UseScene 根节点。
	local function getUseSceneRoot()
		return Workspace:WaitForChild(SceneTheta.WorkspaceRootName, 10)
	end

	-- 获取 UseScene 下的指定子节点。
	local function getSceneChild(childName)
		local useScene = getUseSceneRoot()
		return useScene and useScene:WaitForChild(childName, 10)
	end

	-- 读取 Model/BasePart/子 BasePart 的世界位置。
	local function getInstancePosition(instance)
		if not instance then
			return nil
		end

		if instance:IsA("Model") then
			return instance:GetPivot().Position
		end

		if instance:IsA("BasePart") then
			return instance.Position
		end

		local firstPart = instance:FindFirstChildWhichIsA("BasePart", true)
		return firstPart and firstPart.Position or nil
	end

	-- 判断触碰部件是否是本地玩家根部件。
	local function isLocalRootPart(hit)
		local character = player.Character
		return character ~= nil and hit == character:FindFirstChild("HumanoidRootPart")
	end

	-- 返回本地玩家 HumanoidRootPart。
	local function getPlayerRootPart()
		local character = player.Character
		return character and character:FindFirstChild("HumanoidRootPart")
	end

	return {
		GetUseSceneRoot = getUseSceneRoot,
		GetSceneChild = getSceneChild,
		GetInstancePosition = getInstancePosition,
		IsLocalRootPart = isLocalRootPart,
		GetPlayerRootPart = getPlayerRootPart,
	}
end

return SceneQuery
