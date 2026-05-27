local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local Pump = {}

Pump.MAX_STRETCH = 0.242
Pump.MIN_STRETCH = 0.057
Pump.MAX_POS = 0.241
Pump.MIN_POS = 0.425
Pump.START_COLOR = Color3.new(1, 0.4, 0)
Pump.FINAL_COLOR = Color3.new(1, 0.85098, 0)
Pump.MIN_TRANSPARENCY = 0.7
Pump.MAX_TRANSPARENCY = 0.5

function Pump:Init()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local forgeGui = playerGui.ForgeGui

	self.PumpFrame = forgeGui.PumpFrame
	self.Pump = self.PumpFrame.Pump
	self.Top = self.Pump.Top
	self.Middle = self.Pump.Middle
	self.ProgressFrame = self.PumpFrame.ProgressFrame
	self.ProgressBar = self.ProgressFrame.ProgressBar

	self.Cam = workspace.CurrentCamera

	self.CurrentProgress = 0
	self.Done = false
end

function Pump:WaitUntilEnds()
	while not self.Done or not self.PumpFrame.Visible do
		task.wait(0.1)
	end
end

function Pump:Start()
	self.CurrentProgress = 0
	self.ProgressBar.Size = UDim2.fromScale(1, self.CurrentProgress)
	self.ProgressBar.BackgroundColor3 = self.START_COLOR
	self.ProgressBar.BackgroundTransparency = self.MIN_TRANSPARENCY
	
	local holdingM1 = false
	
	
	local downCon, upCon
	downCon = self.Top.MouseButton1Down:Connect(function()
		holdingM1 = true
		
		local targetLocationYScale, targetSizeYScale
		local currentLocationYScale, currentSizeYScale
		local previousAlpha
		
		local holdingCon 
		holdingCon = RunService.RenderStepped:Connect(function(dt)
			local function stop()
				holdingCon:Disconnect()
				holdingCon = nil
			end
			
			local mouseLocation = UIS:GetMouseLocation()
			local inset = GuiService:GetGuiInset()
			local viewportSize = self.Cam.ViewportSize
			
			local mouseLocationYScale = (mouseLocation.Y - inset.Y) / viewportSize.Y
			mouseLocationYScale = math.clamp(mouseLocationYScale, self.MAX_POS, self.MIN_POS)
			
			local alpha = ((mouseLocationYScale - self.MIN_POS) / (self.MAX_POS - self.MIN_POS))
			local middleYScale = math.lerp(self.MIN_STRETCH, self.MAX_STRETCH, alpha)
			
			currentLocationYScale = self.Top.Position.Y.Scale
			targetLocationYScale = mouseLocationYScale
			
			currentSizeYScale = self.Middle.Size.Y.Scale
			targetSizeYScale = middleYScale
			
			self.Top.Position = UDim2.fromScale(self.Top.Position.X.Scale, math.lerp(currentLocationYScale, targetLocationYScale, self.SMOOTHNESS))
			self.Middle.Size = UDim2.fromScale(self.Middle.Size.X.Scale, math.lerp(currentSizeYScale, targetSizeYScale, self.SMOOTHNESS))
			
			if previousAlpha and previousAlpha > alpha then
				self.CurrentProgress += 0.01
			end
			
			self.CurrentProgress -= 0.0001
			self.CurrentProgress = math.clamp(self.CurrentProgress, 0, 1)
			
			previousAlpha = alpha
			
			self.ProgressBar.Size = UDim2.fromScale(1, math.lerp(self.ProgressBar.Size.Y.Scale, self.CurrentProgress, 0.1))
			
			self.ProgressBar.BackgroundColor3 = self.START_COLOR:Lerp(self.FINAL_COLOR, self.CurrentProgress)
			self.ProgressBar.BackgroundTransparency = math.lerp(self.MIN_TRANSPARENCY, self.MAX_TRANSPARENCY, self.CurrentProgress)
			self.ProgressFrame.Corners.LeftLowCorner.GroupColor3 = self.START_COLOR:Lerp(self.FINAL_COLOR, self.CurrentProgress)
			self.ProgressFrame.Corners.RightLowerCorner.GroupColor3 = self.START_COLOR:Lerp(self.FINAL_COLOR, self.CurrentProgress)
			
			if self.ProgressBar.Size.Y.Scale >= 0.99 then
				warn("Done")
				self.Done = true
				downCon:Disconnect()
				upCon:Disconnect()
				upCon = nil
				downCon = nil
				stop()
			end
			
			if not holdingM1 then
				stop()
			end
		end)
	end)
	
	upCon = self.Top.MouseButton1Up:Connect(function()
		holdingM1 = false
	end)
end

return Pump
