local TweenService = game:GetService("TweenService")

local CounterManager = {}

local START_SIZE = UDim2.fromScale(0.166, 0.176)
local DEFAULT_SIZE = UDim2.fromScale(0.138, 0.131)
local END_SIZE = START_SIZE:Lerp(DEFAULT_SIZE, 0.5)

local popInfo = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local increaseSizeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local lastIncreasSizeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local transparencyInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function CounterManager:Init()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local forgeGui = playerGui.ForgeGui

	self.CounterFrame = forgeGui.CounterFrame
	self.TextLabels = {
		["1"] = self.CounterFrame.Three,
		["2"] = self.CounterFrame.Two,
		["3"] = self.CounterFrame.One,
		["4"] = self.CounterFrame.Go,
	}
end

function CounterManager:StartCount()
	for i = 1, 4 do
		local label = self.TextLabels[tostring(i)]
		
		self.CounterFrame.GroupTransparency = 1
		label.Size = START_SIZE
		label.Visible = true
		
		local transparencyTween = TweenService:Create(self.CounterFrame, transparencyInfo, {GroupTransparency = 0})
		transparencyTween:Play()
		
		local popTween = TweenService:Create(label, popInfo, {Size = DEFAULT_SIZE})
		popTween:Play()
		
		popTween.Completed:Wait()
		
		local longSizeIncreaseTween
		if i == 4 then
			longSizeIncreaseTween = TweenService:Create(label, lastIncreasSizeInfo, {Size = START_SIZE})
			longSizeIncreaseTween:Play()
			
			task.spawn(function()
				task.wait(1)
				local fadeOutTween = TweenService:Create(self.CounterFrame, fadeOutInfo , {GroupTransparency = 1})
				fadeOutTween:Play()

				fadeOutTween.Completed:Wait()

				label.Visible = false
			end)
			
			task.wait(0.5)
			
			return
		else
			longSizeIncreaseTween = TweenService:Create(label, increaseSizeInfo, {Size = END_SIZE})
			longSizeIncreaseTween:Play()
		end
		
		task.wait(0.4)
		
		local fadeOutTween = TweenService:Create(self.CounterFrame, fadeOutInfo , {GroupTransparency = 1})
		fadeOutTween:Play()
		
		fadeOutTween.Completed:Wait()
		
		label.Visible = false
		task.wait(0.1)
	end
end

return CounterManager
