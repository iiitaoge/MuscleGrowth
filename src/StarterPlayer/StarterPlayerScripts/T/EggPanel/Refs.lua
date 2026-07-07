-- EggPanel/Refs
-- 按已验证 UI 合同解析蛋面板运行时实例。

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

local function findRequiredDescendant(root, childName, context)
	local descendant = root:FindFirstChild(childName, true)
	if not descendant then
		error(context .. " '" .. childName .. "' was not found under " .. root:GetFullName() .. ".", 2)
	end

	return descendant
end

local function requireGuiObject(instance, context)
	assert(instance:IsA("GuiObject"), context .. " must be a GuiObject.")
	return instance
end

local function requireTextObject(instance, context)
	assert(instance:IsA("TextLabel") or instance:IsA("TextButton"), context .. " must be a text object.")
	return instance
end

local function requireImageObject(instance, context)
	assert(instance:IsA("ImageLabel") or instance:IsA("ImageButton"), context .. " must be an image object.")
	return instance
end

local function resolveRewardSlots(mainGui, slotPaths, slotFields)
	local slots = {}
	for index, path in ipairs(slotPaths) do
		local slotRoot = requireGuiObject(
			waitForPath(mainGui, path, "Egg reward slot " .. tostring(index)),
			"Egg reward slot " .. tostring(index)
		)
		slots[index] = {
			Root = slotRoot,
			Icon = requireImageObject(
				findRequiredDescendant(slotRoot, slotFields.Icon, "Egg reward slot icon"),
				"Egg reward slot icon"
			),
			ChanceText = requireTextObject(
				findRequiredDescendant(slotRoot, slotFields.ChanceText, "Egg reward slot chance text"),
				"Egg reward slot chance text"
			),
			MultiplierText = requireTextObject(
				findRequiredDescendant(slotRoot, slotFields.MultiplierText, "Egg reward slot multiplier text"),
				"Egg reward slot multiplier text"
			),
		}
	end

	return slots, #slotPaths
end

local function resolveResultTemplate(mainGui, templatePath, templateFields)
	local templateRoot = requireGuiObject(
		waitForPath(mainGui, templatePath, "Egg result template"),
		"Egg result template"
	)

	return {
		Root = templateRoot,
		Icon = requireImageObject(
			findRequiredDescendant(templateRoot, templateFields.Icon, "Egg result template icon"),
			"Egg result template icon"
		),
		NameText = requireTextObject(
			findRequiredDescendant(templateRoot, templateFields.NameText, "Egg result template name text"),
			"Egg result template name text"
		),
		RarityText = requireTextObject(
			findRequiredDescendant(templateRoot, templateFields.RarityText, "Egg result template rarity text"),
			"Egg result template rarity text"
		),
	}
end

function Refs.Resolve(player)
	local config = UIContract.GetConfig("EggPanel")
	local playerGui = player:WaitForChild("PlayerGui", GUI_WAIT_SECONDS)
	if not playerGui then
		error("PlayerGui was not found under " .. player:GetFullName() .. ".", 2)
	end

	local mainGui = playerGui:WaitForChild(config.ScreenGuiName, GUI_WAIT_SECONDS)
	if not mainGui then
		error("Egg ScreenGui '" .. config.ScreenGuiName .. "' was not found under " .. playerGui:GetFullName() .. ".", 2)
	end
	assert(mainGui:IsA("ScreenGui"), "Egg ScreenGui '" .. config.ScreenGuiName .. "' must be a ScreenGui.")

	local paths = config.Paths
	local rewardSlots, rewardSlotCount = resolveRewardSlots(mainGui, paths.RewardSlots, config.RewardSlotFields)

	return {
		PanelRoot = requireGuiObject(waitForPath(mainGui, paths.PanelRoot, "Egg PanelRoot"), "Egg PanelRoot"),
		TitleRoot = requireGuiObject(waitForPath(mainGui, paths.TitleRoot, "Egg TitleRoot"), "Egg TitleRoot"),
		CloseButton = requireGuiObject(waitForPath(mainGui, paths.CloseButton, "Egg CloseButton"), "Egg CloseButton"),
		RewardSlots = rewardSlots,
		RewardSlotCount = rewardSlotCount,
		ResultTemplate = resolveResultTemplate(mainGui, paths.ResultTemplate, config.ResultTemplateFields),
		SingleButton = requireGuiObject(
			waitForPath(mainGui, paths.SingleRollButton, "Egg SingleRollButton"),
			"Egg SingleRollButton"
		),
		TripleButton = requireGuiObject(
			waitForPath(mainGui, paths.TripleRollButton, "Egg TripleRollButton"),
			"Egg TripleRollButton"
		),
		AutoButton = requireGuiObject(waitForPath(mainGui, paths.AutoRollButton, "Egg AutoRollButton"), "Egg AutoRollButton"),
	}
end

return Refs
