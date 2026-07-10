local InstancePath = {}

function InstancePath.Find(root, path)
	if typeof(root) ~= "Instance" or type(path) ~= "table" then
		return nil
	end

	local current = root

	for _, childName in ipairs(path) do
		if type(childName) ~= "string" or childName == "" then
			return nil
		end

		current = current:FindFirstChild(childName)
		if not current then
			return nil
		end
	end

	return current
end

return InstancePath
