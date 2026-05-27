local TweenService = game:GetService("TweenService")

local fadeInInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local fadeOutInfo = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local bounceInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
local outInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

local GuiAnimationManager = {}

function GuiAnimationManager:Init()
	--main
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local forgeGui = playerGui.ForgeGui

	self.MainFrame = forgeGui.MainFrame
	self.BlackFrame = forgeGui.BlackFrame
	self.BlackBars = forgeGui.BlackBars

	--pump
	self.Pump = forgeGui.PumpFrame.Pump
	self.ProgressFrame = forgeGui.PumpFrame.ProgressFrame

	--pour
	self.PourFrame = forgeGui.PourFrame

	self.PumpTransitionTween = TweenService:Create(self.Pump, bounceInfo, {Position = UDim2.fromScale(0, 0)})
	self.PrBarTransitionTween = TweenService:Create(self.ProgressFrame, bounceInfo, {Position = UDim2.fromScale(0.934, 0.52)})

	self.PumpOutTween = TweenService:Create(self.Pump, outInfo, {Position = UDim2.fromScale(-0.5, 0)})
	self.PrBarOutTween = TweenService:Create(self.ProgressFrame, outInfo, {Position = UDim2.fromScale(1.1, 0.52)})

	self.FadeInTween = TweenService:Create(self.BlackFrame, fadeInInfo, {BackgroundTransparency = 0})
	self.FadeOutTween = TweenService:Create(self.BlackFrame, fadeOutInfo, {BackgroundTransparency = 1})
end

function GuiAnimationManager:FadeInPlay()
	self.FadeInTween:Play()
	self.FadeInTween.Completed:Wait()
end

function GuiAnimationManager:FadeOutPlay()
	self.FadeOutTween:Play()
end

function GuiAnimationManager:BlackBarsVisible(value)
	self.BlackBars.Visible = value
end

function GuiAnimationManager:MainVisible(value)
	self.MainFrame.Visible = value
end

function GuiAnimationManager:PourVisible(value)
	self.PourFrame.Visible = value
end

function GuiAnimationManager:TransitionToPump()
	self.Pump.Position = UDim2.fromScale(-0.5, 0)
	self.ProgressFrame.Position = UDim2.fromScale(1.1, 0.52)
	
	self.Pump.Parent.Visible = true
	
	self.PumpTransitionTween:Play()
	self.PrBarTransitionTween:Play()
	
	self.PumpTransitionTween.Completed:Wait()
end

function GuiAnimationManager:TransitionOffPump()
	self.PumpOutTween:Play()
	self.PrBarOutTween:Play()
	
	task.spawn(function()
		self.PrBarOutTween.Completed:Wait()
		self.Pump.Parent.Visible = false
	end)
end

return GuiAnimationManager
