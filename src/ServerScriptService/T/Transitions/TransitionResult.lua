local PlayerSnapshotBuilder = require(script.Parent.Parent.Snapshots.PlayerSnapshotBuilder)

local TransitionResult = {}

local function mergeExtra(result, extraResult)
	if type(extraResult) ~= "table" then
		return result
	end

	for key, value in pairs(extraResult) do
		result[key] = value
	end

	return result
end

function TransitionResult.New(success, message, extraResult)
	return mergeExtra({
		Success = success == true,
		Message = message,
	}, extraResult)
end

function TransitionResult.WithSnapshot(player, success, message, extraResult)
	return mergeExtra({
		Success = success == true,
		Message = message,
		Data = PlayerSnapshotBuilder.GetPlayerSnapshot(player),
	}, extraResult)
end

function TransitionResult.SuccessWithSnapshot(player, message, extraResult)
	return TransitionResult.WithSnapshot(player, true, message, extraResult)
end

function TransitionResult.FailureWithSnapshot(player, message, extraResult)
	return TransitionResult.WithSnapshot(player, false, message, extraResult)
end

return TransitionResult
