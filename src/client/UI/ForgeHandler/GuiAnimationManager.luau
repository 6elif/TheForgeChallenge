local TweenService = game:GetService("TweenService")

--main
local forgeGui = script.Parent.Parent
local mainFrame = forgeGui.MainFrame
local blackFrame = forgeGui.BlackFrame
local blackBars = forgeGui.BlackBars

--pump
local pumpFrame = forgeGui.PumpFrame
local pump = pumpFrame.Pump
local progressFrame = pumpFrame.ProgressFrame

--pour
local pourFrame = forgeGui.PourFrame


local fadeInInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeOutInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
local fadeInTween = TweenService:Create(blackFrame, fadeInInfo, {BackgroundTransparency = 0})
local fadeOutTween = TweenService:Create(blackFrame, fadeInInfo, {BackgroundTransparency = 1})

local bounceInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local outInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local pumpTransitionTween = TweenService:Create(pump, bounceInfo, {Position = UDim2.fromScale(0, 0)})
local prBarTransitionTween = TweenService:Create(progressFrame, bounceInfo, {Position = UDim2.fromScale(0.934, 0.52)})

local pumpOutTween = TweenService:Create(pump, outInfo, {Position = UDim2.fromScale(-0.5, 0)})
local prBarOutTween = TweenService:Create(progressFrame, outInfo, {Position = UDim2.fromScale(1.1, 0.52)})

local guiAnimationManager = {}

function guiAnimationManager:FadeInPlay()
	fadeInTween:Play()
	fadeInTween.Completed:Wait()
end

function guiAnimationManager:FadeOutPlay()
	fadeOutTween:Play()
end

function guiAnimationManager:BlackBarsVisible(value)
	blackBars.Visible = value
end

function guiAnimationManager:MainVisible(value)
	mainFrame.Visible = value
end

function guiAnimationManager:PourVisible(value)
	pourFrame.Visible = value
end

function guiAnimationManager:TransitionToPump()
	pump.Position = UDim2.fromScale(-0.5, 0)
	progressFrame.Position = UDim2.fromScale(1.1, 0.52)
	
	pumpFrame.Visible = true
	
	pumpTransitionTween:Play()
	prBarTransitionTween:Play()
	
	pumpTransitionTween.Completed:Wait()
end

function guiAnimationManager:TransitionOffPump()
	pumpOutTween:Play()
	prBarOutTween:Play()
	
	task.spawn(function()
		prBarOutTween.Completed:Wait()
		pumpFrame.Visible = false
	end)
end


return guiAnimationManager
