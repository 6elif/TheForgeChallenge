local Players = game:GetService("Players")

local Sprinting = require(script.Sprinting)
local ShiftLock = require(script.ShiftLock)
local AnimationManager = require(script.Parent.Parent.Managers.AnimationManager)

local MovementController = {}

function MovementController:Init()
    self.Player = Players.LocalPlayer
end

function MovementController:OnCharacterAdded(character: Model)
    local humanoid = character:WaitForChild("Humanoid")
    local animator = humanoid:WaitForChild("Animator")
    
    AnimationManager.Init(animator)
    AnimationManager.StartAnims(humanoid)

    ShiftLock.Start()
end

function MovementController:Start()
   self.Player.CharacterAdded:Connect(function(character)
        self:OnCharacterAdded(character)
    end)
    
    if self.Player.Character then
        task.spawn(function()
            self:OnCharacterAdded(self.Player.Character)
        end)
    end
    
    Sprinting.Start()
    ShiftLock.Start()
end

return MovementController