local TweenService = game:GetService("TweenService")

local forgeGui = script.Parent.Parent
local counterFrame = forgeGui.CounterFrame

local counterManager = {}

local textLabels = {
	["1"] = counterFrame.Three,
	["2"] = counterFrame.Two,
	["3"] = counterFrame.One,
	["4"] = counterFrame.Go,
}

local START_SIZE = UDim2.fromScale(0.166, 0.176)
local DEFAULT_SIZE = UDim2.fromScale(0.138, 0.131)
local END_SIZE = START_SIZE:Lerp(DEFAULT_SIZE, 0.5)

local popInfo = TweenInfo.new(0.3, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out)
local increaseSizeInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local lastIncreasSizeInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local fadeOutInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local transparencyInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function counterManager:StartCount()
	for i = 1, 4 do
		local label = textLabels[tostring(i)]
		
		counterFrame.GroupTransparency = 1
		label.Size = START_SIZE
		label.Visible = true
		
		local transparencyTween = TweenService:Create(counterFrame, transparencyInfo, {GroupTransparency = 0})
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
				local fadeOutTween = TweenService:Create(counterFrame, fadeOutInfo , {GroupTransparency = 1})
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
		
		local fadeOutTween = TweenService:Create(counterFrame, fadeOutInfo , {GroupTransparency = 1})
		fadeOutTween:Play()
		
		fadeOutTween.Completed:Wait()
		
		label.Visible = false
		task.wait(0.1)
	end
end

return counterManager
