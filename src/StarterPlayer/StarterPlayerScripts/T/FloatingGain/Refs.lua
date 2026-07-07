-- FloatingGain/Refs
-- 按已验证 UI 合同解析飘字模板实例。

local UIContract = require(script.Parent.Parent.UIContract)

local Refs = {}

local GUI_WAIT_SECONDS = 10

local function waitForRequiredChild(parent, childName, context)
	local child = parent:WaitForChild(childName, GUI_WAIT_SECONDS)
	if not child then
		error(context .. " '" .. childName .. "' was not found under " .. parent:GetFullName() .. ".", 2)
	end

	return child
end

local function requireGuiObject(instance, context)
	assert(instance:IsA("GuiObject"), context .. " must be a GuiObject.")
	return instance
end

function Refs.Resolve(player)
	local config = UIContract.GetConfig("FloatingGain")
	local playerGui = waitForRequiredChild(player, "PlayerGui", "PlayerGui")
	local hud = waitForRequiredChild(playerGui, config.ScreenGuiName, "Floating gain HUD ScreenGui")
	assert(hud:IsA("ScreenGui"), "Floating gain HUD '" .. config.ScreenGuiName .. "' must be a ScreenGui.")

	local strengthTemplate = requireGuiObject(
		waitForRequiredChild(hud, config.Templates.StrengthGain, "Floating gain strength template"),
		"Floating gain strength template"
	)
	local trophyTemplate = requireGuiObject(
		waitForRequiredChild(hud, config.Templates.TrophyGain, "Floating gain trophy template"),
		"Floating gain trophy template"
	)

	strengthTemplate.Visible = false
	trophyTemplate.Visible = false

	return {
		StrengthTemplate = strengthTemplate,
		TrophyTemplate = trophyTemplate,
		Animation = config.Animation,
	}
end

return Refs
