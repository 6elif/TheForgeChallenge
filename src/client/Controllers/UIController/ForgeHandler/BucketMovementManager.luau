local TweenService = game:GetService("TweenService")

local forge = workspace:WaitForChild("Forge")
local bucket = forge:WaitForChild("Bucket")
local bucketMainPart = bucket:WaitForChild("Main")

local DEFAULT_POS = Vector3.new(-9.938, 8.889, 30.179)
local PUMP_POS = Vector3.new(-9.938, 3.852, 30.179)
local POUR_POS = Vector3.new(-9.938, 6.825, 30.179)

local info = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local bucketManager = {}

function bucketManager:Pump()
	local tween = TweenService:Create(bucketMainPart, info, {CFrame = CFrame.new(PUMP_POS)})
	
	tween:Play()
	tween.Completed:Wait()
end

function bucketManager:Pour()
	local tween = TweenService:Create(bucketMainPart, info, {CFrame = CFrame.new(POUR_POS)})

	tween:Play()
	tween.Completed:Wait()
end

return bucketManager
