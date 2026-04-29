local TweenService = game:GetService("TweenService")

local forgeGui = script.Parent.Parent
local pourFrame = forgeGui.PourFrame
local cursor = pourFrame.Cursor
local pourMiniGame = pourFrame.PourMiniGame
local bar = pourMiniGame.Bar
local progressBar = pourFrame.ProgressBar
local progressIndicator = progressBar.Indicator

local BAR_MIN_POS_Y = 0
local BAR_MAX_POS_Y = 0.771 * 1000  
local BAR_MIN_SPEED = 2 * 10
local BAR_MAX_SPEED = 1 * 10

local CURSOR_MIN_POS_Y = 0.833
local CURSOR_MAX_POS_Y = 0.17


local done = false
local progress = 0
local previousYPos = 0

local pourManager = {}

local function isInside()
	local innerPos = cursor.AbsolutePosition
	local innerSize = cursor.AbsoluteSize

	local outerPos = bar.AbsolutePosition
	local outerSize = bar.AbsoluteSize

	local isWithinY = innerPos.Y >= outerPos.Y and (innerPos.Y + innerSize.Y) <= (outerPos.Y + outerSize.Y)

	return isWithinY
end

function pourManager:WaitUntilEnds()
	while not done do
		task.wait(0.1)
	end
end

function pourManager:Start()
	-- init
	done = false
	progress = 0
	local m1Down = false
	progressIndicator.Size = UDim2.fromScale(0, progressIndicator.Size.Y.Scale)
	
	local downCon, upCon
	
	task.spawn(function()
		while not done do
			local newBarPositionY
			repeat
			 	newBarPositionY = math.random(BAR_MIN_POS_Y, BAR_MAX_POS_Y) / 1000
			until newBarPositionY > previousYPos + 0.1 or newBarPositionY < previousYPos - 0.1
			
			previousYPos = newBarPositionY
			
			local speed = math.random(BAR_MAX_SPEED, BAR_MIN_SPEED) / 10

			local info = TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local tween = TweenService:Create(bar, info, {Position = UDim2.fromScale(bar.Position.X.Scale, newBarPositionY)})

			tween:Play()
			tween.Completed:Wait()
		end
	end)
	
	task.spawn(function()
		while not done do
			if not m1Down then
				local newY = math.clamp(cursor.Position.Y.Scale + 0.004, CURSOR_MAX_POS_Y, CURSOR_MIN_POS_Y)
				cursor.Position = UDim2.fromScale(cursor.Position.X.Scale, newY)
			end
			
			if isInside() then
				progress += 0.2
				progressIndicator.Size = UDim2.fromScale(progress / 100, progressIndicator.Size.Y.Scale)
			end
			
			if progress >= 99 then
				done = true
				downCon:Disconnect()
				upCon:Disconnect()
				upCon = nil
				downCon = nil
			end
			task.wait()
		end
	end)
	
	downCon = pourFrame.MouseButton1Down:Connect(function()
		m1Down = true
		while m1Down do
			local newY = math.clamp(cursor.Position.Y.Scale - 0.004, CURSOR_MAX_POS_Y, CURSOR_MIN_POS_Y)
			cursor.Position = UDim2.fromScale(cursor.Position.X.Scale, newY)
			task.wait()
		end
	end)
	upCon = pourFrame.MouseButton1Up:Connect(function()
		m1Down = false
	end)
end

return pourManager
