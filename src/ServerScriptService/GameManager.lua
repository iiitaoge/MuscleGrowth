local Workspace = game:GetService("Workspace")

local GameManager = {}
local growthLoops = {}

local PlayerData = require(script.Parent.PlayerData)
local GrowthState = require(script.Parent.GrowthState)
local AutoAreaConfig = require(game:GetService("ReplicatedStorage").Configs.AutoAreaConfig)

local AREA_CONTACT_PADDING = 1
local ENTER_CONTACT_RETRY_COUNT = 4
local ENTER_CONTACT_RETRY_INTERVAL = 0.05

-- 获取角色的根部件（HumanoidRootPart），用于检测玩家是否在自动区内。
local function getCharacterRoot(player)
	local character = player.Character
	if not character then
		return nil
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end

	return nil
end

-- 获取自动区的触发部件（Touch），用于检测玩家是否与自动区有接触。
local function getAutoAreaTouchPart(areaId)
	local world = Workspace:FindFirstChild("World1")
	local trainAreas = world and world:FindFirstChild("TrainAreas")
	local area = trainAreas and trainAreas:FindFirstChild(areaId)
	local touch = area and area:FindFirstChild("Touch")

	if touch and touch:IsA("BasePart") then
		return touch
	end

	return nil
end

-- 检查一个点是否在指定的部件内，可以额外扩展检测盒。
local function isPointInsidePart(part, position, extraHalfSize)
	local relative = part.CFrame:PointToObjectSpace(position)
	local halfSize = part.Size * 0.5 + (extraHalfSize or Vector3.new())

	return math.abs(relative.X) <= halfSize.X
		and math.abs(relative.Y) <= halfSize.Y
		and math.abs(relative.Z) <= halfSize.Z
end

local function isPartOverlappingPart(areaPart, targetPart)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { targetPart }
	overlapParams.MaxParts = 1

	local success, parts = pcall(function()
		return Workspace:GetPartsInPart(areaPart, overlapParams)
	end)

	return success and parts[1] ~= nil
end

local function isRootOverlappingTouch(root, touch)
	if isPartOverlappingPart(touch, root) then
		return true
	end

	local rootHalfSize = root.Size * 0.5
	local extraHalfSize = rootHalfSize
		+ Vector3.new(AREA_CONTACT_PADDING, AREA_CONTACT_PADDING, AREA_CONTACT_PADDING)

	return isPointInsidePart(touch, root.Position, extraHalfSize)
end

-- 服务器端的自动区检测逻辑，确保玩家在进入自动区时，只有在与自动区的触发区域有有效接触时才会被认为是进入了自动区。
local function isPlayerInsideAutoArea(player, areaId)
	local root = getCharacterRoot(player)
	local touch = getAutoAreaTouchPart(areaId)

	return root ~= nil and touch ~= nil and isRootOverlappingTouch(root, touch)
end

-- 检查玩家是否与指定的自动区有有效接触
local function isValidAutoAreaContact(player, areaId)
	--print("AutoAreaConfig[areaId]:", AutoAreaConfig[areaId])
	local hasAreaConfig = AutoAreaConfig[areaId] ~= nil
	local isInside = hasAreaConfig and isPlayerInsideAutoArea(player, areaId)
	print("isPlayerInsideAutoArea:", isInside)
	return hasAreaConfig and isInside
end

local function waitForValidAutoAreaContact(player, areaId)
	for _ = 1, ENTER_CONTACT_RETRY_COUNT do
		if isValidAutoAreaContact(player, areaId) then
			return true
		end

		task.wait(ENTER_CONTACT_RETRY_INTERVAL)
	end

	return false
end

local function pruneInvalidAutoAreas(player)
	local autoAreas = GrowthState.getAutoAreas(player)

	for areaId in pairs(autoAreas) do
		if not isValidAutoAreaContact(player, areaId) then
			GrowthState.leaveAutoArea(player, areaId)
		end
	end
end

-- 获取玩家当前的增长上下文，包括是否应该增长、自动区倍率等信息。
local function getGrowthContext(player)
	local playerData = PlayerData.get(player)
	if not playerData then
		return nil
	end

	pruneInvalidAutoAreas(player)
	return GrowthState.getActiveContext(player, playerData)
end

local function stopGrowthLoop(player)
	growthLoops[player] = nil
end

-- 开始增长循环，每秒检查一次增长条件，并根据当前的增长状态和玩家数据进行增长。
local function startGrowthLoop(player)
	-- 如果已经在增长循环中，则不需要再次启动
	if growthLoops[player] then
		return
	end

	growthLoops[player] = true

	task.spawn(function()
		while growthLoops[player] do
			task.wait(1)

			local context = getGrowthContext(player)
			if not context or not context.ShouldGrow then
				stopGrowthLoop(player)
				break
			end

			PlayerData.addProgress(player, context)
		end
	end)
end

-- 更新增长状态
function GameManager.refreshGrowth(player)
	local context = getGrowthContext(player)
	if context and context.ShouldGrow then
		--print("Starting growth loop for player:", player.Name)
		startGrowthLoop(player)
	else
		stopGrowthLoop(player)
	end
end

-- 设置玩家的移动状态，并刷新增长状态
function GameManager.setMoving(player, isMoving)
	GrowthState.setMoving(player, isMoving)
	GameManager.refreshGrowth(player)
end

-- 客户端进入自动区时，服务器端会验证玩家是否与自动区的触发区域有有效接触，如果有，则允许进入自动区并开始增长。
function GameManager.enterAutoArea(player, areaId)
	if type(areaId) ~= "string" then
		--print("Invalid areaId type:", areaId)
		return false
	end

	if not waitForValidAutoAreaContact(player, areaId) then
		print("Invalid auto area contact for player:", player.Name, "Area:", areaId)
		return false
	end

	GrowthState.enterAutoArea(player, areaId)
	GameManager.refreshGrowth(player)
	return true
end

function GameManager.leaveAutoArea(player, areaId)
	if type(areaId) ~= "string" then
		return
	end

	GrowthState.leaveAutoArea(player, areaId)
	GameManager.refreshGrowth(player)
end

function GameManager.stopGrowth(player)
	stopGrowthLoop(player)
end

function GameManager.removePlayer(player)
	stopGrowthLoop(player)
	GrowthState.remove(player)
end

return GameManager
