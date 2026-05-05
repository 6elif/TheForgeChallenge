local TweenService = game:GetService("TweenService")
local CAS = game:GetService("ContextActionService")
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")

local ACTION_NAME = "SprintAction"
local BUTTON_TITLE = "Run"
local BUTTON_IMAGE = "rbxassetid://137772167757442"
local BUTTON_PRESSED_IMAGE = "rbxassetid://126614244813233"
local BUTTON_PRESSED_TEXT_COLOR = Color3.new(0, 0, 0)
local BUTTON_TEXT_COLOR = Color3.new(1, 1, 1)
local BUTTON_TEXT_SIZE = 24
local BUTTON_TEXT_TRANSPARENCY = 0.5

local player
local camera
local char = nil
local hum : Humanoid = nil

local currentIcon = nil 
local currentText = nil
local isMobile = false
local isSprinting = false

local Sprinting = {}

Sprinting.DefaultSpeed = 16
Sprinting.SprintSpeed = 25

Sprinting.DefaultFov = 70
Sprinting.SprintFov = 80

local function updateVisuals()
	if not currentIcon or not currentText then return end

	if isSprinting then
		currentIcon.Image = BUTTON_PRESSED_IMAGE
		currentText.TextColor3 = BUTTON_PRESSED_TEXT_COLOR
	else
		currentIcon.Image = BUTTON_IMAGE
		currentText.TextColor3 = BUTTON_TEXT_COLOR
	end
end

local function startSprinting()
	isSprinting = true
	
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fovTween = TweenService:Create(camera, info, {FieldOfView = Sprinting.SprintFov})
	local sprintTween = TweenService:Create(hum, info, {WalkSpeed = Sprinting.SprintSpeed})
	sprintTween:Play()
	fovTween:Play()
	updateVisuals()
end

local function stopSprinting()
	isSprinting = false
	
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local fovTween = TweenService:Create(camera, info, {FieldOfView = Sprinting.DefaultFov})
	local sprintTween = TweenService:Create(hum, info, {WalkSpeed = Sprinting.DefaultSpeed})
	sprintTween:Play()
	fovTween:Play()
	updateVisuals()
end

local function handleSprintAction(actionName, inputState, inputObject)
	local isToggleDevice = isMobile or inputObject.UserInputType == Enum.UserInputType.Gamepad1

	if isToggleDevice then
		if inputState == Enum.UserInputState.Begin then
			if not isSprinting then
				startSprinting()
			else
				stopSprinting()
			end
		end
	else
		-- PC "Hold" Logic
		if inputState == Enum.UserInputState.Begin then
			startSprinting()
		elseif inputState == Enum.UserInputState.End then
			stopSprinting()
		end
	end
end

function Sprinting.Start()
	player = Players.LocalPlayer
	camera = workspace.CurrentCamera
	char = player.Character or player.CharacterAdded:Wait()
	hum = char:FindFirstChild("Humanoid")
	
	if not hum then return end
	
	task.spawn(function()
		local forceRenderGui = Instance.new("ScreenGui")
		forceRenderGui.Name = "ForceRenderContainer"
		forceRenderGui.DisplayOrder = -1000
		forceRenderGui.Parent = player:WaitForChild("PlayerGui")
		
		local imagesToPreloadIds = {
			BUTTON_IMAGE, 
			BUTTON_PRESSED_IMAGE
		}
		
		for _, id in ipairs(imagesToPreloadIds) do
			if type(id) ~= "string" then continue end
			
			local clone = Instance.new("ImageLabel")
			clone.Image = id
			clone.Size = UDim2.new(0, 1, 0, 1)
			clone.ImageTransparency = 0.99
			clone.Parent = forceRenderGui
			
			table.insert(imagesToPreloadIds, clone)
		end
		
		ContentProvider:PreloadAsync(imagesToPreloadIds)

		task.wait(0.5)
		forceRenderGui:Destroy()
	end)
	
	player.CharacterAdded:Connect(function(newChar)
		char = newChar
		hum = newChar:WaitForChild("Humanoid")
		stopSprinting()
	end)
	
	CAS:BindAction(
		ACTION_NAME,
		handleSprintAction,
		true,
		Enum.KeyCode.LeftShift, -- Keyboard
		Enum.KeyCode.ButtonL3   -- Gamepad
	)
	
	local button = CAS:GetButton(ACTION_NAME)
	
	if button then		
		local playerGui = player:WaitForChild("PlayerGui")
		local touchGui = playerGui:WaitForChild("TouchGui", 5)
		if touchGui then
			local controlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
			if controlFrame then
				local jumpButton = controlFrame:FindFirstChild("JumpButton")
				if jumpButton then
					button.Size = jumpButton.Size
					
					button.Position = UDim2.new(
						jumpButton.Position.X.Scale, 
						jumpButton.Position.X.Offset,
						jumpButton.Position.Y.Scale, 
						jumpButton.Position.Y.Offset - (jumpButton.Size.Y.Offset * 1.1)
					)
				end
			end
		end
		
		if BUTTON_IMAGE then
			isMobile = true
			
			button.ImageTransparency = 1 
			button.BackgroundTransparency = 1
			
			local icon = Instance.new("ImageLabel")
			icon.Name = "CustomIcon"
			icon.Size = UDim2.fromScale(1, 1)
			icon.BackgroundTransparency = 1
			icon.ScaleType = Enum.ScaleType.Stretch
			icon.Image = BUTTON_IMAGE 
			
			local text = Instance.new("TextLabel")
			text.Name = "CustomText"
			text.Size = UDim2.fromScale(1, 1)
			text.BackgroundTransparency = 1
			text.TextColor3 = Color3.new(1, 1, 1)
			text.Font = Enum.Font.GothamBold
			text.TextSize = BUTTON_TEXT_SIZE
			text.TextTransparency = BUTTON_TEXT_TRANSPARENCY
			text.Text = BUTTON_TITLE
			
			currentIcon = icon
			currentText = text
			
			text.Parent = icon
			icon.Parent = button
		else
			CAS:SetTitle(ACTION_NAME, BUTTON_TITLE)
		end
	end
	
	hum.Died:Connect(function()
		stopSprinting()
	end)
end

return Sprinting