-- BarbellDisplay/Renderer
-- 只负责查找杠铃场景展示节点并写入文本/可见性。

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local theta = ReplicatedStorage:WaitForChild("theta")
local BarbellDisplayTheta = require(theta:WaitForChild("BarbellDisplayTheta"))
local SceneTheta = require(theta:WaitForChild("SceneTheta"))

local Renderer = {}

-- 取得 UseScene 根节点。
local function getUseSceneRoot()
	return Workspace:WaitForChild(SceneTheta.WorkspaceRootName, 10)
end

-- 取得指定场景子目录。
local function getSceneChild(childName)
	local useScene = getUseSceneRoot()
	return useScene and useScene:WaitForChild(childName, 10)
end

-- 给展示节点中的文本字段写入文本。
local function setDisplayText(root, labelName, value)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label:IsA("TextLabel") then
		label.Text = value
	end
end

-- 给展示节点中的 GUI 字段切换可见性。
local function setDisplayVisible(root, labelName, isVisible)
	local label = root and root:FindFirstChild(labelName, true)
	if label and label:IsA("GuiObject") then
		label.Visible = isVisible == true
	end
end

-- 解析杠铃展示根目录。
function Renderer.Resolve()
	return {
		SceneEquipment = nil,
		SceneEquipmentRootName = BarbellDisplayTheta.SceneEquipmentRootName or SceneTheta.SceneEquipmentRootName,
		Fields = BarbellDisplayTheta.Fields or {},
		DisplayModelName = BarbellDisplayTheta.DisplayModelName or SceneTheta.BarbellDisplayModelName,
	}
end

-- 渲染所有杠铃展示状态。
function Renderer.Render(refs, models)
	if not refs then
		return
	end

	if not refs.SceneEquipment then
		refs.SceneEquipment = getSceneChild(refs.SceneEquipmentRootName)
	end

	if not refs.SceneEquipment then
		return
	end

	local fields = refs.Fields or {}
	for _, model in ipairs(models or {}) do
		local barbellNode = refs.SceneEquipment:FindFirstChild(model.BarbellId)
		local displayNode = barbellNode and (barbellNode:FindFirstChild(refs.DisplayModelName) or barbellNode)

		setDisplayText(displayNode, fields.PowerText or "power", model.PowerText)
		setDisplayText(displayNode, fields.CostText or "num", model.CostText)
		setDisplayVisible(displayNode, fields.Locked or "Locked", not model.IsUnlocked)
		setDisplayVisible(displayNode, fields.Equip or "Equip", model.IsUnlocked and not model.IsEquipped)
		setDisplayVisible(displayNode, fields.Equipped or "Equipped", model.IsEquipped)
	end
end

return Renderer
