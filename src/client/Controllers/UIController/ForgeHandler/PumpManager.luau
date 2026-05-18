local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local forgeGui = playerGui.ForgeGui
local pumpFrame = forgeGui.PumpFrame
local pump = pumpFrame.Pump
local top = pump.Top
local middle = pump.Middle
local progressFrame = pumpFrame.ProgressFrame
local progressBar = progressFrame.ProgressBar

local pump = {}

local cam = workspace.CurrentCamera

local MAX_STRETCH = 0.242
local MIN_STRETCH = 0.057
local MAX_POS = 0.241
local MIN_POS = 0.425
local START_COLOR = Color3.new(1, 0.4, 0)
local FINAL_COLOR = Color3.new(1, 0.85098, 0)
local MIN_TRANSPARENCY = 0.7
local MAX_TRANSPARENCY = 0.5

local currentProgress = 0

local done = false

function pump:WaitUntilEnds()
	while not done or not pumpFrame.Visible do
		task.wait(0.1)
	end
end

function pump:Start()
	-- init
	currentProgress = 0
	progressBar.Size = UDim2.fromScale(1, currentProgress)
	progressBar.BackgroundColor3 = START_COLOR
	progressBar.BackgroundTransparency = MIN_TRANSPARENCY
	
	local holdingM1 = false
	
	
	local downCon, upCon
	downCon = top.MouseButton1Down:Connect(function()
		holdingM1 = true
		
		local targetLocationYScale, targetSizeYScale
		local currentLocationYScale, currentSizeYScale
		
		local SMOOTHNESS = 0.3
		local previousAlpha
		
		local holdingCon 
		holdingCon = RunService.RenderStepped:Connect(function(dt)
			local function stop()
				holdingCon:Disconnect()
				holdingCon = nil
			end
			
			local mouseLocation = UIS:GetMouseLocation()
			local inset = GuiService:GetGuiInset()
			local viewportSize = cam.ViewportSize
			
			local mouseLocationYScale = (mouseLocation.Y - inset.Y) / viewportSize.Y
			mouseLocationYScale = math.clamp(mouseLocationYScale, MAX_POS, MIN_POS)
			
			local alpha = ((mouseLocationYScale - MIN_POS) / (MAX_POS - MIN_POS))
			local middleYScale = math.lerp(MIN_STRETCH, MAX_STRETCH, alpha)
			
			currentLocationYScale = top.Position.Y.Scale
			targetLocationYScale = mouseLocationYScale
			
			currentSizeYScale = middle.Size.Y.Scale
			targetSizeYScale = middleYScale
			
			top.Position = UDim2.fromScale(top.Position.X.Scale, math.lerp(currentLocationYScale, targetLocationYScale, SMOOTHNESS))
			middle.Size = UDim2.fromScale(middle.Size.X.Scale, math.lerp(currentSizeYScale, targetSizeYScale, SMOOTHNESS))
			
			if previousAlpha and previousAlpha > alpha then
				currentProgress += 0.01
			end
			
			currentProgress -= 0.0001
			currentProgress = math.clamp(currentProgress, 0, 1)
			
			previousAlpha = alpha
			
			progressBar.Size = UDim2.fromScale(1, math.lerp(progressBar.Size.Y.Scale, currentProgress, 0.1))
			
			progressBar.BackgroundColor3 = START_COLOR:Lerp(FINAL_COLOR, currentProgress)
			progressBar.BackgroundTransparency = math.lerp(MIN_TRANSPARENCY, MAX_TRANSPARENCY, currentProgress)
			progressFrame.Corners.LeftLowCorner.GroupColor3 = START_COLOR:Lerp(FINAL_COLOR, currentProgress)
			progressFrame.Corners.RightLowerCorner.GroupColor3 = START_COLOR:Lerp(FINAL_COLOR, currentProgress)
			
			if progressBar.Size.Y.Scale >= 0.99 then
				warn("Done")
				done = true
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
	
	upCon = top.MouseButton1Up:Connect(function()
		holdingM1 = false
	end)
end

return pump
