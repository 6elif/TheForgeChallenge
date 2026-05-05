local Players = game:GetService("Players")

local Sprinting = require(script.Sprinting)
local ShiftLock = require(script.ShiftLock)
local AnimationManager = require(Players.LocalPlayer.PlayerScripts.Client.Managers.AnimationManager)

local MovementController = {}

function MovementController.Init()
    Players.LocalPlayer.CharacterAdded:Connect(function(char)
        local humanoid = char:WaitForChild("Humanoid")
        local animator = humanoid:WaitForChild("Animator")
        
        AnimationManager.Init(animator)
    end)
end

function MovementController.Start()
    local player = Players.LocalPlayer
    local char = player.Character or player.CharacterAdded:Wait()
    local humanoid = char:FindFirstChild("Humanoid")

    AnimationManager.StartAnims(humanoid)
    Sprinting.Start()
    ShiftLock.Start()
end

return MovementController