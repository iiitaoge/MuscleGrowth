-- HUD/Refs
-- 按已验证 UI 合同解析 HUD 运行时实例。

local UIContract = require(script.Parent.Parent.UIContract)

local Refs = {}

local GUI_WAIT_SECONDS = 10
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

local function requireTextObject(instance, context)
	assert(instance:IsA("TextLabel") or instance:IsA("TextButton"), context .. " must be a text object.")
	return instance
end

local function requireGuiObject(instance, context)
	assert(instance:IsA("GuiObject"), context .. " must be a GuiObject.")
	return instance
end

local function requireGuiButton(instance, context)
	assert(instance:IsA("GuiButton"), context .. " must be a GuiButton.")
	return instance
end

function Refs.Resolve(player)
	local config = UIContract.GetConfig("HUD")
	local playerGui = waitForRequiredChild(player, "PlayerGui", "PlayerGui", GUI_WAIT_SECONDS)
	local hud = waitForRequiredChild(playerGui, config.ScreenGuiName, "HUD ScreenGui", GUI_WAIT_SECONDS)
	assert(hud:IsA("ScreenGui"), "HUD ScreenGui '" .. config.ScreenGuiName .. "' must be a ScreenGui.")

	local paths = config.Paths
	return {
		StrengthText = requireTextObject(waitForPath(hud, paths.StrengthText, "HUD StrengthText"), "HUD StrengthText"),
		TrophiesText = requireTextObject(waitForPath(hud, paths.TrophiesText, "HUD TrophiesText"), "HUD TrophiesText"),
		RebirthMultiplierText = requireTextObject(
			waitForPath(hud, paths.RebirthMultiplierText, "HUD RebirthMultiplierText"),
			"HUD RebirthMultiplierText"
		),
		BarbellMultiplierText = requireTextObject(
			waitForPath(hud, paths.BarbellMultiplierText, "HUD BarbellMultiplierText"),
			"HUD BarbellMultiplierText"
		),
		PetMultiplierText = requireTextObject(
			waitForPath(hud, paths.PetMultiplierText, "HUD PetMultiplierText"),
			"HUD PetMultiplierText"
		),
		ExpBar = requireGuiObject(waitForPath(hud, paths.ExpBar, "HUD ExpBar"), "HUD ExpBar"),
		LevelText = requireTextObject(waitForPath(hud, paths.LevelText, "HUD LevelText"), "HUD LevelText"),
		ExpText = requireTextObject(waitForPath(hud, paths.ExpText, "HUD ExpText"), "HUD ExpText"),
		RebirthButton = requireGuiButton(
			waitForPath(hud, paths.RebirthButton, "HUD RebirthButton"),
			"HUD RebirthButton"
		),
	}
end

return Refs
