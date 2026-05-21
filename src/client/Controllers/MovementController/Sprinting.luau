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

local Sprinting = {}

Sprinting.DefaultSpeed = 16
Sprinting.SprintSpeed = 25
Sprinting.DefaultFov = 70
Sprinting.SprintFov = 80

function Sprinting:UpdateVisuals()
    if not self.CurrentIcon or not self.CurrentText then return end

    if self.IsSprinting then
        self.CurrentIcon.Image = BUTTON_PRESSED_IMAGE
        self.CurrentText.TextColor3 = BUTTON_PRESSED_TEXT_COLOR
    else
        self.CurrentIcon.Image = BUTTON_IMAGE
        self.CurrentText.TextColor3 = BUTTON_TEXT_COLOR
    end
end

function Sprinting:StartSprinting()
    if not self.Humanoid then return end
    self.IsSprinting = true
    
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fovTween = TweenService:Create(self.Camera, info, {FieldOfView = self.SprintFov})
    local sprintTween = TweenService:Create(self.Humanoid, info, {WalkSpeed = self.SprintSpeed})
    
    sprintTween:Play()
    fovTween:Play()
    self:UpdateVisuals()
end

function Sprinting:StopSprinting()
    if not self.Humanoid then return end
    self.IsSprinting = false
    
    local info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fovTween = TweenService:Create(self.Camera, info, {FieldOfView = self.DefaultFov})
    local sprintTween = TweenService:Create(self.Humanoid, info, {WalkSpeed = self.DefaultSpeed})
    
    sprintTween:Play()
    fovTween:Play()
    self:UpdateVisuals()
end

local function handleSprintAction(actionName, inputState, inputObject)
    local self = Sprinting 
    local isToggleDevice = self.IsMobile or inputObject.UserInputType == Enum.UserInputType.Gamepad1

    if isToggleDevice then
        if inputState == Enum.UserInputState.Begin then
            if not self.IsSprinting then
                self:StartSprinting()
            else
                self:StopSprinting()
            end
        end
    else
        if inputState == Enum.UserInputState.Begin then
            self:StartSprinting()
        elseif inputState == Enum.UserInputState.End then
            self:StopSprinting()
        end
    end
end

function Sprinting:OnCharacterSpawn(character)
    self.Character = character
    self.Humanoid = character:WaitForChild("Humanoid")
    self:StopSprinting()
    
    self.Humanoid.Died:Connect(function()
        self:StopSprinting()
    end)
end

function Sprinting:Init()
    self.Player = Players.LocalPlayer
    self.Camera = workspace.CurrentCamera
    
    self.CurrentIcon = nil 
    self.CurrentText = nil
    self.IsMobile = false
    self.IsSprinting = false
    
    task.spawn(function()
        local forceRenderGui = Instance.new("ScreenGui")
        forceRenderGui.Name = "ForceRenderContainer"
        forceRenderGui.DisplayOrder = -1000
        forceRenderGui.Parent = self.Player:WaitForChild("PlayerGui")
        
        local imagesToPreloadIds = { BUTTON_IMAGE, BUTTON_PRESSED_IMAGE }
        
        for _, id in ipairs(imagesToPreloadIds) do
            if type(id) ~= "string" then continue end
            local clone = Instance.new("ImageLabel")
            clone.Image = id
            clone.Size = UDim2.new(0, 1, 0, 1)
            clone.ImageTransparency = 0.99
            clone.Parent = forceRenderGui
        end
        
        ContentProvider:PreloadAsync(forceRenderGui:GetChildren())
        task.wait(0.5)
        forceRenderGui:Destroy()
    end)
end

function Sprinting:Start()
    CAS:BindAction(
        ACTION_NAME,
        handleSprintAction,
        true,
        Enum.KeyCode.LeftShift,
        Enum.KeyCode.ButtonL3
    )
    
    local button = CAS:GetButton(ACTION_NAME)
    if button and BUTTON_IMAGE then      
        self.IsMobile = true
        
        local playerGui = self.Player:WaitForChild("PlayerGui")
        local touchGui = playerGui:WaitForChild("TouchGui", 5)
        if touchGui then
            local controlFrame = touchGui:WaitForChild("TouchControlFrame", 5)
            local jumpButton = controlFrame and controlFrame:FindFirstChild("JumpButton")
            if jumpButton then
                button.Size = jumpButton.Size
                button.Position = UDim2.new(
                    jumpButton.Position.X.Scale, jumpButton.Position.X.Offset,
                    jumpButton.Position.Y.Scale, jumpButton.Position.Y.Offset - (jumpButton.Size.Y.Offset * 1.1)
                )
            end
        end
        
        button.ImageTransparency = 1 
        button.BackgroundTransparency = 1
        
        local icon = Instance.new("ImageLabel")
        icon.Name = "CustomIcon"
        icon.Size = UDim2.fromScale(1, 1)
        icon.BackgroundTransparency = 1
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
        
        self.CurrentIcon = icon
        self.CurrentText = text
        
        text.Parent = icon
        icon.Parent = button
    elseif button then
        CAS:SetTitle(ACTION_NAME, BUTTON_TITLE)
    end
end

return Sprinting