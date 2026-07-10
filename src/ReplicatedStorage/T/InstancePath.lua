local InstancePath = {}

function InstancePath.Find(root, path)

    -- 先保证输入正确
    if not root or type(path) ~= "table" or typeof(root) ~= "Instance" then
		return nil
	end


	-- 路径遍历算法

    local current = root

    for _, childName in ipairs(path) do
        if type(childName) ~= "string" or childName == "" then
            return nil;
        end

        -- 等待一会
        current = current:FindFirstChild(childName)
        if not current then
			return nil
		end
	end

	return current

end

return InstancePath