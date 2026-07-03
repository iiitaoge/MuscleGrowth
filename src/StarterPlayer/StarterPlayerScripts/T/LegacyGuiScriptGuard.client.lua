local Players = game:GetService("Players")

local player = Players.LocalPlayer

local GUI_WAIT_SECONDS = 10
local DISABLED_ATTRIBUTE = "MuscleGrowthDisabledLegacyScript"
local LEGACY_SCREEN_NAMES = {
	"HUD",
	"Main",
}

local function disableLegacyScript(instance)
	if not instance:IsA("LocalScript") then
		return
	end

	instance:SetAttribute(DISABLED_ATTRIBUTE, true)
	instance.Disabled = true
end

local function guardLegacyGui(screenGui)
	for _, descendant in ipairs(screenGui:GetDescendants()) do
		disableLegacyScript(descendant)
	end

	screenGui.DescendantAdded:Connect(disableLegacyScript)
end

local playerGui = player:WaitForChild("PlayerGui")

for _, screenName in ipairs(LEGACY_SCREEN_NAMES) do
	local screenGui = playerGui:WaitForChild(screenName, GUI_WAIT_SECONDS)
	if screenGui then
		guardLegacyGui(screenGui)
	end
end
