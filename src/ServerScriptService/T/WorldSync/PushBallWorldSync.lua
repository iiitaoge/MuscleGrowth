local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InstancePath = require(ReplicatedStorage:WaitForChild("T"):WaitForChild("InstancePath"))

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))
local PushBallSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("PushBallSceneTheta"))

local PushBallWorldSync = {}

local PATH_WAIT_SECONDS = 10
local PROMPT_BOUND_ATTRIBUTE = "MuscleGrowthPushBallPromptBound"

local function debugLog(message)
	if PushBallTheta.DebugPushBall == true then
		print("[PushBallWorldSync] " .. message)
	end
end

local function getFirstBasePart(instance)
	if not instance then
		return nil
	end

	if instance:IsA("BasePart") then
		return instance
	end

	return instance:FindFirstChildWhichIsA("BasePart", true)
end

local function configurePrompt(prompt)
	local maxDistance = math.max(0, tonumber(PushBallTheta.InteractionDistance) or 14)

	prompt.Enabled = true
	prompt.ActionText = PushBallTheta.PromptActionText or "Push"
	prompt.ObjectText = PushBallTheta.PromptObjectText or "Ball"
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.MaxActivationDistance = maxDistance
	prompt.MaxIndicatorDistance = maxDistance
	prompt.RequiresLineOfSight = false
end

local function ensurePrompt(ball)
	local prompt = ball:FindFirstChildWhichIsA("ProximityPrompt", true)
	if prompt then
		configurePrompt(prompt)
		debugLog("Configured existing prompt: " .. prompt:GetFullName())
		return prompt
	end

	local promptParent = getFirstBasePart(ball)
	if not promptParent then
		return nil
	end

	prompt = Instance.new("ProximityPrompt")
	configurePrompt(prompt)
	prompt.Parent = promptParent
	debugLog("Created prompt: " .. prompt:GetFullName())

	return prompt
end

local function bindBallPrompt(ballInstanceId, ballConfig, onPromptTriggered)
	debugLog(("Binding %s at %s"):format(tostring(ballInstanceId), InstancePath.Format(ballConfig.Path)))

	local ball = InstancePath.WaitSpec({ Workspace = Workspace }, ballConfig.Path, PATH_WAIT_SECONDS)
	if not ball then
		warn("Missing push ball source: " .. tostring(ballInstanceId))
		return
	end
	debugLog("Found ball: " .. ball:GetFullName())

	local prompt = ensurePrompt(ball)
	if not prompt then
		warn("Missing push ball prompt target: " .. tostring(ballInstanceId))
		return
	end

	if prompt:GetAttribute(PROMPT_BOUND_ATTRIBUTE) then
		debugLog("Prompt already bound: " .. prompt:GetFullName())
		return
	end

	prompt:SetAttribute(PROMPT_BOUND_ATTRIBUTE, true)
	debugLog(
		("Bound %s prompt=%s Enabled=%s Key=%s Distance=%s Indicator=%s LOS=%s"):format(
			tostring(ballInstanceId),
			prompt:GetFullName(),
			tostring(prompt.Enabled),
			tostring(prompt.KeyboardKeyCode),
			tostring(prompt.MaxActivationDistance),
			tostring(prompt.MaxIndicatorDistance),
			tostring(prompt.RequiresLineOfSight)
		)
	)
	prompt.Triggered:Connect(function(player)
		debugLog(("Triggered %s by %s"):format(tostring(ballInstanceId), player and player.Name or "nil"))
		if onPromptTriggered then
			onPromptTriggered(player, ballInstanceId)
		end
	end)
end

function PushBallWorldSync.InitWorld(onPromptTriggered)
	task.spawn(function()
		debugLog("InitWorld start")

		local balls = PushBallSceneTheta.Balls
		if type(balls) ~= "table" then
			warn("Missing PushBallSceneTheta.Balls")
			return
		end

		for ballInstanceId, ballConfig in pairs(balls) do
			if type(ballInstanceId) == "string" and type(ballConfig) == "table" then
				task.spawn(bindBallPrompt, ballInstanceId, ballConfig, onPromptTriggered)
			end
		end
	end)
end

return PushBallWorldSync
