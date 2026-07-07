-- BarbellDisplay/Refs
-- 按已验证 UI 合同解析杠铃场景展示实例。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellTheta = require(theta:WaitForChild("BarbellTheta"))
local UIContract = require(script.Parent.Parent.UIContract)

local Refs = {}

local SCENE_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

local function waitForRequiredChild(parent, childName, context, timeout)
	local child = parent:WaitForChild(childName, timeout)
	if not child then
		error(context .. " '" .. childName .. "' was not found under " .. parent:GetFullName() .. ".", 2)
	end

	return child
end

local function waitForPath(root, path, context)
	local current = root
	for _, childName in ipairs(path) do
		current = waitForRequiredChild(current, childName, context, NODE_WAIT_SECONDS)
	end

	return current
end

local function requireTextLabel(instance, context)
	assert(instance:IsA("TextLabel"), context .. " must be a TextLabel.")
	return instance
end

local function requireGuiObject(instance, context)
	assert(instance:IsA("GuiObject"), context .. " must be a GuiObject.")
	return instance
end

function Refs.Resolve()
	local config = UIContract.GetConfig("BarbellDisplay")
	local worldRoot = waitForRequiredChild(Workspace, config.WorkspaceRootName, "Workspace root", SCENE_WAIT_SECONDS)
	local sceneEquipment =
		waitForRequiredChild(worldRoot, config.SceneEquipmentRootName, "Barbell scene equipment", SCENE_WAIT_SECONDS)
	local displayNodes = {}

	for barbellId, barbellConfig in pairs(BarbellTheta) do
		if type(barbellId) == "string" and type(barbellConfig) == "table" then
			local barbellNode = waitForRequiredChild(sceneEquipment, barbellId, "Barbell scene node", SCENE_WAIT_SECONDS)
			local displayNode =
				waitForRequiredChild(barbellNode, config.DisplayModelName, "Barbell display model", SCENE_WAIT_SECONDS)
			local fieldPaths = config.FieldPaths
			displayNodes[barbellId] = {
				PowerText = requireTextLabel(
					waitForPath(displayNode, fieldPaths.PowerText, "Barbell power text"),
					"Barbell power text"
				),
				CostText = requireTextLabel(
					waitForPath(displayNode, fieldPaths.CostText, "Barbell cost text"),
					"Barbell cost text"
				),
				Locked = requireGuiObject(
					waitForPath(displayNode, fieldPaths.Locked, "Barbell locked indicator"),
					"Barbell locked indicator"
				),
				Equip = requireGuiObject(
					waitForPath(displayNode, fieldPaths.Equip, "Barbell equip indicator"),
					"Barbell equip indicator"
				),
				Equipped = requireGuiObject(
					waitForPath(displayNode, fieldPaths.Equipped, "Barbell equipped indicator"),
					"Barbell equipped indicator"
				),
			}
		end
	end

	return {
		DisplayNodes = displayNodes,
	}
end

return Refs
