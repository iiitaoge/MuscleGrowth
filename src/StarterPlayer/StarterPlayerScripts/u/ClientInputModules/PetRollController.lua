-- PetRollController
-- 客户端抽蛋动作层，负责按钮请求、自动抽循环和结果展示。

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local theta = ReplicatedStorage:WaitForChild("theta")
local PetSystemTheta = require(theta:WaitForChild("PetSystemTheta"))

local PetRollController = {}

-- 初始化抽蛋动作控制器。
function PetRollController.Init(remoteClient, snapshotController, eggPanelView, eggInteractionController)
	local isRequestingPetRoll = false
	local isAutoRolling = false

	-- 请求服务端执行一次或多次抽蛋。
	local function invokePetRoll(eggId, rollCount)
		if isRequestingPetRoll then
			return nil
		end

		isRequestingPetRoll = true
		local success, result = remoteClient.SafeInvoke("RequestPetRoll", eggId, rollCount)
		isRequestingPetRoll = false

		if not success then
			warn(result)
			return nil
		end

		snapshotController.ApplyRemoteResult(success, result)
		eggPanelView.ShowRollResults(result and result.RollResults, result and result.Message)
		return result
	end

	-- 停止自动抽，并按需展示总结。
	local function stopAutoRoll(showSummary, rolledCount)
		isAutoRolling = false
		eggPanelView.SetAutoRolling(false)
		if showSummary then
			eggPanelView.ShowAutoSummary(rolledCount or 0)
		end
	end

	-- 自动抽循环，每次仍走服务端 RequestPetRoll。
	local function runAutoRoll(eggId)
		local rolledCount = 0
		local cooldown = math.max(0.1, tonumber(PetSystemTheta.RollCooldownSeconds) or 0.5)

		while isAutoRolling and eggPanelView.IsOpen() and eggPanelView.GetCurrentEggId() == eggId do
			if not eggInteractionController.IsPlayerNearEgg(eggId) then
				break
			end

			local result = invokePetRoll(eggId, 1)
			if not result or result.Success ~= true then
				break
			end

			rolledCount += #(result.RollResults or {})
			task.wait(cooldown + 0.05)
		end

		stopAutoRoll(eggPanelView.IsOpen(), rolledCount)
	end

	-- 开始或停止自动抽。
	local function startAutoRoll(eggId)
		if isAutoRolling then
			stopAutoRoll(false, 0)
			return
		end

		isAutoRolling = true
		eggPanelView.SetAutoRolling(true)

		task.spawn(runAutoRoll, eggId)
	end

	-- 处理蛋面板发出的抽奖请求。
	local function handleRollRequest(eggId, rollCount, isAuto)
		if isAuto then
			startAutoRoll(eggId)
			return
		end

		if isAutoRolling then
			return
		end

		if not eggInteractionController.IsPlayerNearEgg(eggId) then
			warn("Player is not near this egg")
			return
		end

		invokePetRoll(eggId, rollCount)
	end

	eggPanelView.SetRollHandler(handleRollRequest)

	return {}
end

return PetRollController
