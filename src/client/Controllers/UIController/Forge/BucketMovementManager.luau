local TweenService = game:GetService("TweenService")

local ForgeConfig = require(script.Parent.ForgeConfig)

local _DEFAULT_POS = ForgeConfig.DefaultBucketPosition
local PUMP_POS = ForgeConfig.PumpBucketPosition
local POUR_POS = ForgeConfig.PourBucketPosition

local info = TweenInfo.new(2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local BucketManager = {}

function BucketManager:Init(forgeModel)
	local bucket = forgeModel:WaitForChild("Bucket")

	self.BucketMainPart = bucket:WaitForChild("Main")
end

function BucketManager:Pump()
	local tween = TweenService:Create(self.BucketMainPart, info, {CFrame = CFrame.new(PUMP_POS)})
	
	tween:Play()
	tween.Completed:Wait()
end

function BucketManager:Pour()
	local tween = TweenService:Create(self.BucketMainPart, info, {CFrame = CFrame.new(POUR_POS)})

	tween:Play()
	tween.Completed:Wait()
end

return BucketManager
