local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")

if not RunService:IsStudio() then
	return
end

local theta = ReplicatedStorage:WaitForChild("theta")
local AutoAreaSceneTheta = require(theta:WaitForChild("Scene"):WaitForChild("AutoAreaSceneTheta"))

local displayModules = StarterPlayer
	:WaitForChild("StarterPlayerScripts")
	:WaitForChild("T")
	:WaitForChild("AutoAreaDisplay")
local DataAdapter = require(displayModules:WaitForChild("DataAdapter"))
local Renderer = require(displayModules:WaitForChild("Renderer"))

local function countEntries(source)
	local count = 0
	for _ in pairs(source) do
		count += 1
	end
	return count
end

local models = DataAdapter.BuildModels({ RebirthCount = 2 })
local configuredInstanceCount = countEntries(AutoAreaSceneTheta.Instances)
assert(configuredInstanceCount > 0, "Expected configured auto area scene instances")
assert(countEntries(models) == configuredInstanceCount, "Expected one display model per configured scene instance")

assert(models.World2R2.PowerText == "x1.25 Power", "R2 multiplier text must preserve useful decimals")
assert(models.World2R4.PowerText == "x2 Power", "Integer multipliers must not include trailing decimals")
assert(models.World2R2.RebirthText == "Requires 1 Rebirth", "R2 requirement must use singular Rebirth")
assert(models.UseSceneR1.RebirthText == "Requires 0 Rebirths", "R1 requirement must use plural Rebirths")

for _, instanceId in ipairs({ "UseSceneR2", "World2R2", "World3R2" }) do
	local model = models[instanceId]
	assert(model.PowerText == models.UseSceneR2.PowerText, instanceId .. " must share R2 power text")
	assert(model.RebirthText == models.UseSceneR2.RebirthText, instanceId .. " must share R2 rebirth text")
	assert(model.IsUnlocked == models.UseSceneR2.IsUnlocked, instanceId .. " must share R2 unlock state")
end

for instanceId, instanceConfig in pairs(AutoAreaSceneTheta.Instances) do
	local areaNumber = tonumber(string.match(instanceConfig.AreaId, "^R(%d+)$"))
	assert(areaNumber ~= nil, "Unexpected AreaId for " .. instanceId)
	assert(models[instanceId].IsUnlocked == (areaNumber <= 3), instanceId .. " has incorrect unlock state")
end

local displayNode = {
	PowerText = Instance.new("TextLabel"),
	RebirthText = Instance.new("TextLabel"),
	Locked = Instance.new("TextLabel"),
	Unlocked = Instance.new("TextLabel"),
}

Renderer.RenderNode(displayNode, models.World2R2)
assert(displayNode.PowerText.Text == "x1.25 Power" and displayNode.PowerText.Visible, "Power must render visibly")
assert(
	displayNode.RebirthText.Text == "Requires 1 Rebirth" and displayNode.RebirthText.Visible,
	"Rebirth requirement must render visibly"
)
assert(not displayNode.Locked.Visible and displayNode.Unlocked.Visible, "Unlocked state labels must be mutually exclusive")

Renderer.RenderNode(displayNode, models.World2R4)
assert(displayNode.Locked.Visible and not displayNode.Unlocked.Visible, "Locked state labels must be mutually exclusive")

for _, instance in pairs(displayNode) do
	instance:Destroy()
end

print("[AutoAreaDisplayTest] passed")
