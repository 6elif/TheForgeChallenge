local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")


local MOUSE_LOCK_KEYS = "LeftControl,RightControl"
local MOUSE_LOCK_IMAGE = "rbxassetid://117508370121623"

local shiftLockManager = {}

function shiftLockManager:Init()
	local player = Players.LocalPlayer
	local mouseLockController = player
		.PlayerScripts
		:WaitForChild("PlayerModule")
		:WaitForChild("CameraModule")
		:WaitForChild("MouseLockController")

	local boundKeys = mouseLockController:FindFirstChild("BoundKeys")
	if boundKeys then
		boundKeys.Value = MOUSE_LOCK_KEYS
	else
		boundKeys = Instance.new("StringValue")
		boundKeys.Name = "BoundKeys"
		boundKeys.Value = MOUSE_LOCK_KEYS
		boundKeys.Parent = mouseLockController
	end
	
	local cursorImage = mouseLockController:FindFirstChild("CursorImage")
	if cursorImage then
		cursorImage.Value = MOUSE_LOCK_IMAGE
	else
		cursorImage = Instance.new("StringValue")
		cursorImage.Name = "CursorImage"
		cursorImage.Value = MOUSE_LOCK_IMAGE
		cursorImage.Parent = mouseLockController
	end
	
	task.spawn(function()
		-- PreLoad
		local forceRenderGui = Instance.new("ScreenGui")
		forceRenderGui.Name = "ForceRenderContainer"
		forceRenderGui.DisplayOrder = -1000
		forceRenderGui.Parent = player:WaitForChild("PlayerGui")

		local clone = Instance.new("ImageLabel")
		clone.Image = MOUSE_LOCK_IMAGE
		clone.Size = UDim2.new(0, 1, 0, 1)
		clone.ImageTransparency = 0.99
		clone.Parent = forceRenderGui
		

		ContentProvider:PreloadAsync({clone, MOUSE_LOCK_IMAGE})

		task.wait(0.5)
		forceRenderGui:Destroy()
	end)
end

return shiftLockManager
