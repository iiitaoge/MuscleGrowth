-- PetInventory/Refs
-- 按已验证 UI 合同解析宠物背包运行时实例。

local UIContract = require(script.Parent.Parent.UIContract)

local Refs = {}

local GUI_WAIT_SECONDS = 10
local NODE_WAIT_SECONDS = 5

local function waitForRequiredChild(parent, childName, context)
	local child = parent:WaitForChild(childName, NODE_WAIT_SECONDS)
	if not child then
		error(context .. " '" .. childName .. "' was not found under " .. parent:GetFullName() .. ".", 2)
	end

	return child
end

local function waitForPath(root, path, context)
	local current = root
	for _, childName in ipairs(path) do
		current = waitForRequiredChild(current, childName, context)
	end

	return current
end

local function requireGuiObject(instance, context)
	assert(instance:IsA("GuiObject"), context .. " must be a GuiObject.")
	return instance
end

local function requireTextObject(instance, context)
	assert(instance:IsA("TextLabel") or instance:IsA("TextButton"), context .. " must be a text object.")
	return instance
end

function Refs.Resolve(player)
	local config = UIContract.GetConfig("PetInventory")
	local playerGui = player:WaitForChild("PlayerGui", GUI_WAIT_SECONDS)
	if not playerGui then
		error("PlayerGui was not found under " .. player:GetFullName() .. ".", 2)
	end

	local hud = playerGui:WaitForChild(config.HudScreenGuiName, GUI_WAIT_SECONDS)
	if not hud then
		error("Pet inventory HUD ScreenGui '" .. config.HudScreenGuiName .. "' was not found under " .. playerGui:GetFullName() .. ".", 2)
	end
	assert(hud:IsA("ScreenGui"), "Pet inventory HUD ScreenGui must be a ScreenGui.")

	local mainGui = playerGui:WaitForChild(config.ScreenGuiName, GUI_WAIT_SECONDS)
	if not mainGui then
		error("Pet inventory ScreenGui '" .. config.ScreenGuiName .. "' was not found under " .. playerGui:GetFullName() .. ".", 2)
	end
	assert(mainGui:IsA("ScreenGui"), "Pet inventory ScreenGui must be a ScreenGui.")

	local paths = config.Paths
	return {
		CardFields = config.PetCardFields,
		PetButton = requireGuiObject(waitForPath(hud, paths.PetButton, "PetInventory PetButton"), "PetInventory PetButton"),
		PanelRoot = requireGuiObject(waitForPath(mainGui, paths.PanelRoot, "PetInventory PanelRoot"), "PetInventory PanelRoot"),
		CloseButton = requireGuiObject(
			waitForPath(mainGui, paths.CloseButton, "PetInventory CloseButton"),
			"PetInventory CloseButton"
		),
		OwnedContainer = requireGuiObject(
			waitForPath(mainGui, paths.OwnedList, "PetInventory OwnedList"),
			"PetInventory OwnedList"
		),
		OwnedTemplate = requireGuiObject(
			waitForPath(mainGui, paths.OwnedTemplate, "PetInventory OwnedTemplate"),
			"PetInventory OwnedTemplate"
		),
		EquippedContainer = requireGuiObject(
			waitForPath(mainGui, paths.EquippedList, "PetInventory EquippedList"),
			"PetInventory EquippedList"
		),
		EquippedTemplate = requireGuiObject(
			waitForPath(mainGui, paths.EquippedTemplate, "PetInventory EquippedTemplate"),
			"PetInventory EquippedTemplate"
		),
		EquippedText = requireTextObject(
			waitForPath(mainGui, paths.EquippedText, "PetInventory EquippedText"),
			"PetInventory EquippedText"
		),
		NoPet = requireGuiObject(waitForPath(mainGui, paths.NoPet, "PetInventory NoPet"), "PetInventory NoPet"),
		EquipBestButton = requireGuiObject(
			waitForPath(mainGui, paths.EquipBestButton, "PetInventory EquipBestButton"),
			"PetInventory EquipBestButton"
		),
		UnequipAllButton = requireGuiObject(
			waitForPath(mainGui, paths.UnequipAllButton, "PetInventory UnequipAllButton"),
			"PetInventory UnequipAllButton"
		),
		DeleteButton = requireGuiObject(
			waitForPath(mainGui, paths.DeleteButton, "PetInventory DeleteButton"),
			"PetInventory DeleteButton"
		),
	}
end

return Refs
