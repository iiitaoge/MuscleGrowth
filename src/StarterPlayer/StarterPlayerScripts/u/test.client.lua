local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

local sceneEgg = Workspace
	:WaitForChild("World1")
	:WaitForChild("SceneEgg")

-- 记录每个蛋当前是否正在被玩家触碰
local touchingEggs = {}

local function isLocalRootPart(hit)
	local character = player.Character
	if not character then
		return false
	end

	local rootPart = character:WaitForChild("HumanoidRootPart")
	return hit == rootPart
end

local function bindPromptPart(eggName, promptPart)
	print("绑定")
	if not promptPart:IsA("BasePart") then
		warn(eggName .. " 的 PromptPart 不是 BasePart，不能使用 Touched")
		return
	end
	print("绑定 " .. eggName .. " 的 PromptPart Touched 事件")

	promptPart.Touched:Connect(function(hit)
		if not isLocalRootPart(hit) then
			return
		end

		if touchingEggs[eggName] then
			return
		end

		touchingEggs[eggName] = true
		print("玩家碰到了 " .. eggName .. " 的 PromptPart")
	end)

	promptPart.TouchEnded:Connect(function(hit)
		if not isLocalRootPart(hit) then
			return
		end

		if not touchingEggs[eggName] then
			return
		end

		touchingEggs[eggName] = nil
		print("玩家离开了 " .. eggName .. " 的 PromptPart")
	end)
end


-- 绑定每个蛋的 PromptPart 事件
for _, eggModel in ipairs(sceneEgg:GetChildren()) do
	local promptPart = eggModel:WaitForChild("PromptPart")
	if promptPart then
		bindPromptPart(eggModel.Name, promptPart)
	end
end