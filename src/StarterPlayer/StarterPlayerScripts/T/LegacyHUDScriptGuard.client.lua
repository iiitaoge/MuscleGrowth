local Players = game:GetService("Players")

local player = Players.LocalPlayer

local HUD_WAIT_SECONDS = 10
local DISABLED_ATTRIBUTE = "MuscleGrowthDisabledLegacyScript"

local function disableLegacyScript(instance)
	if not instance:IsA("LocalScript") then
		return
	end

	instance:SetAttribute(DISABLED_ATTRIBUTE, true)
	instance.Disabled = true
end

local function guardHud(hud)
	for _, descendant in ipairs(hud:GetDescendants()) do
		disableLegacyScript(descendant)
	end

	hud.DescendantAdded:Connect(disableLegacyScript)
end

local playerGui = player:WaitForChild("PlayerGui")
local hud = playerGui:FindFirstChild("HUD") or playerGui:WaitForChild("HUD", HUD_WAIT_SECONDS)

if hud then
	guardHud(hud)
end
