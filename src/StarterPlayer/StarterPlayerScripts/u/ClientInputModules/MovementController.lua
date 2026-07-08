-- MovementController
-- 客户端移动输入层，只负责 Running/Died 到移动 Remote 的转换。

local MovementController = {}

-- 初始化移动控制器。
function MovementController.Init(player, remoteClient, autoAreaController)
	local isMoving = false
	local isSuspended = false

	-- 只在移动状态真的变化时通知服务端。
	local function setMoving(nextIsMoving)
		if isSuspended then
			nextIsMoving = false
		end

		if isMoving == nextIsMoving then
			return
		end

		isMoving = nextIsMoving
		if isMoving then
			remoteClient.Fire("MoveStart")
		else
			remoteClient.Fire("MoveStop")
		end
	end

	-- 给角色绑定移动和死亡监听。
	local function bindCharacter(character)
		setMoving(false)
		autoAreaController.Reset()

		local humanoid = character:WaitForChild("Humanoid")

		-- Running 事件负责把本地速度转换成移动状态。
		local function handleRunning(speed)
			if isSuspended then
				setMoving(false)
				return
			end

			setMoving(speed > 0.1)
		end

		-- 死亡时清空移动和自动区本地状态。
		local function handleDied()
			setMoving(false)
			autoAreaController.Reset()
		end

		humanoid.Running:Connect(handleRunning)
		humanoid.Died:Connect(handleDied)
	end

	local function setSuspended(nextIsSuspended)
		isSuspended = nextIsSuspended == true
		if isSuspended then
			setMoving(false)
			autoAreaController.Reset()
		end
	end

	-- 绑定当前角色和后续重生角色。
	local function bind()
		if player.Character then
			bindCharacter(player.Character)
		end

		player.CharacterAdded:Connect(bindCharacter)
	end

	return {
		Bind = bind,
		SetSuspended = setSuspended,
	}
end

return MovementController
