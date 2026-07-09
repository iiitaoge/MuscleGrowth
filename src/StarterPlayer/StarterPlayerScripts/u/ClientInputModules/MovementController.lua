-- MovementController
-- 客户端移动输入层，只负责 Running/Died 到移动 Remote 的转换。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PushBallTheta = require(theta:WaitForChild("Gameplay"):WaitForChild("PushBallTheta"))

local MovementController = {}

local function debugLog(...)
	if PushBallTheta.DebugPushBall == true then
		print("[MovementController]", ...)
	end
end

-- 初始化移动控制器。
function MovementController.Init(player, remoteClient, autoAreaController)
	local isMoving = false
	local isSuspended = false
	local lastSuspendedRunningLogAt = 0

	-- 只在移动状态真的变化时通知服务端。
	local function setMoving(nextIsMoving)
		local requestedIsMoving = nextIsMoving == true
		if isSuspended then
			nextIsMoving = false
		end

		if isMoving == nextIsMoving then
			if isSuspended and requestedIsMoving then
				local now = os.clock()
				if now - lastSuspendedRunningLogAt >= 1 then
					lastSuspendedRunningLogAt = now
					debugLog("SetMoving ignored by suspension", "requested=", requestedIsMoving, "current=", isMoving)
				end
			end
			return
		end

		isMoving = nextIsMoving
		if isMoving then
			remoteClient.Fire("MoveStart")
		else
			remoteClient.Fire("MoveStop")
		end

		debugLog("SetMoving", "requested=", requestedIsMoving, "applied=", isMoving, "isSuspended=", isSuspended)
	end

	-- 给角色绑定移动和死亡监听。
	local function bindCharacter(character)
		debugLog("BindCharacter", "character=", character and character.Name or nil)
		setMoving(false)
		autoAreaController.Reset()

		local humanoid = character:WaitForChild("Humanoid")
		debugLog(
			"BindCharacter humanoid",
			"walkSpeed=", humanoid.WalkSpeed,
			"jumpPower=", humanoid.JumpPower,
			"autoRotate=", humanoid.AutoRotate,
			"state=", humanoid:GetState().Name,
			"floor=", humanoid.FloorMaterial.Name
		)

		-- Running 事件负责把本地速度转换成移动状态。
		local function handleRunning(speed)
			if isSuspended then
				local now = os.clock()
				if now - lastSuspendedRunningLogAt >= 1 then
					lastSuspendedRunningLogAt = now
					debugLog("Running ignored while suspended", "speed=", speed)
				end
				setMoving(false)
				return
			end

			setMoving(speed > 0.1)
		end

		-- 死亡时清空移动和自动区本地状态。
		local function handleDied()
			debugLog("HumanoidDied")
			setMoving(false)
			autoAreaController.Reset()
		end

		humanoid.Running:Connect(handleRunning)
		humanoid.Died:Connect(handleDied)
	end

	local function setSuspended(nextIsSuspended)
		local previous = isSuspended
		isSuspended = nextIsSuspended == true
		debugLog("SetSuspended", "previous=", previous, "next=", isSuspended)
		if isSuspended then
			setMoving(false)
			autoAreaController.Reset()
		end
	end

	-- 绑定当前角色和后续重生角色。
	local function bind()
		debugLog("Bind")
		if player.Character then
			bindCharacter(player.Character)
		end

		player.CharacterAdded:Connect(function(character)
			debugLog("CharacterAdded", "character=", character and character.Name or nil)
			bindCharacter(character)
		end)
	end

	return {
		Bind = bind,
		SetSuspended = setSuspended,
	}
end

return MovementController
