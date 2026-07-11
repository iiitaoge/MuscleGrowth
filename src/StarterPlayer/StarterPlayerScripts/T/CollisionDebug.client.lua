-- 临时客户端碰撞诊断器。
-- 默认只输出角色碰到的近乎完全透明、且会阻挡角色的 BasePart。

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local ENABLED = true
local ONLY_TRANSPARENT = true
local TRANSPARENCY_THRESHOLD = 0.95
local LOG_COOLDOWN_SECONDS = 0.75
local CONTACT_SCAN_INTERVAL_SECONDS = 0.1

local activeCharacter = nil
local activeConnections = {}
local boundCharacterParts = setmetatable({}, { __mode = "k" })
local lastLogTimes = setmetatable({}, { __mode = "k" })

local function disconnectCharacter()
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end

	table.clear(activeConnections)
	table.clear(boundCharacterParts)
	table.clear(lastLogTimes)
	activeCharacter = nil
end

local function isTransparent(part)
	return part.Transparency >= TRANSPARENCY_THRESHOLD
		or part.LocalTransparencyModifier >= TRANSPARENCY_THRESHOLD
end

local function logCollision(characterPart, otherPart)
	local character = activeCharacter
	if not character or not otherPart:IsA("BasePart") or otherPart:IsDescendantOf(character) then
		return
	end

	-- 只关注真正可能形成“空气墙”的碰撞体。
	if not otherPart.CanCollide then
		return
	end

	if ONLY_TRANSPARENT and not isTransparent(otherPart) then
		return
	end

	local now = os.clock()
	local lastLogTime = lastLogTimes[otherPart]
	if lastLogTime and now - lastLogTime < LOG_COOLDOWN_SECONDS then
		return
	end
	lastLogTimes[otherPart] = now

	warn(
		("[CollisionDebug] %s hit %s | Transparency=%.2f LocalTransparencyModifier=%.2f CanCollide=%s CanTouch=%s CollisionGroup=%s Position=%s Size=%s"):format(
			characterPart:GetFullName(),
			otherPart:GetFullName(),
			otherPart.Transparency,
			otherPart.LocalTransparencyModifier,
			tostring(otherPart.CanCollide),
			tostring(otherPart.CanTouch),
			otherPart.CollisionGroup,
			tostring(otherPart.Position),
			tostring(otherPart.Size)
		)
	)
end

local function bindCharacterPart(instance)
	if not instance:IsA("BasePart") or boundCharacterParts[instance] then
		return
	end

	boundCharacterParts[instance] = true
	table.insert(activeConnections, instance.Touched:Connect(function(otherPart)
		logCollision(instance, otherPart)
	end))
end

local function bindCharacter(character)
	disconnectCharacter()
	activeCharacter = character

	table.insert(activeConnections, character.DescendantAdded:Connect(bindCharacterPart))
	for _, descendant in ipairs(character:GetDescendants()) do
		bindCharacterPart(descendant)
	end

	-- Touched 在任一碰撞体 CanTouch=false 时不会触发；轮询物理接触作为诊断兜底。
	local elapsed = 0
	table.insert(activeConnections, RunService.Heartbeat:Connect(function(deltaTime)
		elapsed += deltaTime
		if elapsed < CONTACT_SCAN_INTERVAL_SECONDS then
			return
		end
		elapsed = 0

		for characterPart in pairs(boundCharacterParts) do
			if characterPart:IsDescendantOf(character) then
				for _, otherPart in ipairs(characterPart:GetTouchingParts()) do
					logCollision(characterPart, otherPart)
				end
			end
		end
	end))
end

if ENABLED then
	player.CharacterAdded:Connect(bindCharacter)
	if player.Character then
		bindCharacter(player.Character)
	end
end
