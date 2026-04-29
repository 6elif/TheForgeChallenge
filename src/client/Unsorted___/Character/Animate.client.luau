local animationManager = require(game:GetService("ReplicatedStorage").Modules.AnimationManager)

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:FindFirstChild("Humanoid")
local animator = humanoid:FindFirstChild("Animator")

animationManager:initialize(animator)

animationManager:StartAnims(humanoid)
