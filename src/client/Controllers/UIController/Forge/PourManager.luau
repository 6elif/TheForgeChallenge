local TweenService = game:GetService("TweenService")

local PourManager = {}

PourManager.BAR_MIN_POS_Y = 0
PourManager.BAR_MAX_POS_Y = 0.771 * 1000  
PourManager.BAR_MIN_SPEED = 2 * 10
PourManager.BAR_MAX_SPEED = 1 * 10

PourManager.CURSOR_MIN_POS_Y = 0.833
PourManager.CURSOR_MAX_POS_Y = 0.17

function PourManager:isInside()
	local innerPos = self.Cursor.AbsolutePosition
	local innerSize = self.Cursor.AbsoluteSize

	local outerPos = self.Bar.AbsolutePosition
	local outerSize = self.Bar.AbsoluteSize

	local isWithinY = innerPos.Y >= outerPos.Y and (innerPos.Y + innerSize.Y) <= (outerPos.Y + outerSize.Y)

	return isWithinY
end

function PourManager:Init()
	local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	local forgeGui = playerGui.ForgeGui
	self.PourFrame = forgeGui.PourFrame
	self.Cursor = self.PourFrame.Cursor
	self.PourMiniGame = self.PourFrame.PourMiniGame
	self.Bar = self.PourMiniGame.Bar
	self.ProgressBar = self.PourFrame.ProgressBar
	self.ProgressIndicator = self.ProgressBar.Indicator

	self.Done = false
	self.Progress = 0
	self.PreviousYPos = 0
end

function PourManager:WaitUntilEnds()
	while not self.Done do
		task.wait(0.1)
	end
end

function PourManager:Start()
	-- init
	self.Done = false
	self.Progress = 0
	local m1Down = false
	self.ProgressIndicator.Size = UDim2.fromScale(0, self.ProgressIndicator.Size.Y.Scale)
	
	local downCon, upCon
	
	task.spawn(function()
		while not self.Done do
			local newBarPositionY
			repeat
			 	newBarPositionY = math.random(self.BAR_MIN_POS_Y, self.BAR_MAX_POS_Y) / 1000
			until newBarPositionY > self.PreviousYPos + 0.1 or newBarPositionY < self.PreviousYPos - 0.1
			
			self.PreviousYPos = newBarPositionY
			
			local speed = math.random(self.BAR_MAX_SPEED, self.BAR_MIN_SPEED) / 10

			local info = TweenInfo.new(speed, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
			local tween = TweenService:Create(self.Bar, info, {Position = UDim2.fromScale(self.Bar.Position.X.Scale, newBarPositionY)})

			tween:Play()
			tween.Completed:Wait()
		end
	end)
	
	task.spawn(function()
		while not self.Done do
			if not m1Down then
				local newY = math.clamp(self.Cursor.Position.Y.Scale + 0.004, self.CURSOR_MAX_POS_Y, self.CURSOR_MIN_POS_Y)
				self.Cursor.Position = UDim2.fromScale(self.Cursor.Position.X.Scale, newY)
			end
			
			if self:isInside() then
				self.Progress += 0.2
				self.ProgressIndicator.Size = UDim2.fromScale(self.Progress / 100, self.ProgressIndicator.Size.Y.Scale)
			end
			
			if self.Progress >= 99 then
				self.Done = true
				downCon:Disconnect()
				upCon:Disconnect()
				upCon = nil
				downCon = nil
			end
			task.wait()
		end
	end)
	
	downCon = self.PourFrame.MouseButton1Down:Connect(function()
		m1Down = true
		while m1Down do
			local newY = math.clamp(self.Cursor.Position.Y.Scale - 0.004, self.CURSOR_MAX_POS_Y, self.CURSOR_MIN_POS_Y)
			self.Cursor.Position = UDim2.fromScale(self.Cursor.Position.X.Scale, newY)
			task.wait()
		end
	end)
	upCon = self.PourFrame.MouseButton1Up:Connect(function()
		m1Down = false
	end)
end

return PourManager
