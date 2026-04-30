local animationManager = require(game:GetService("Players").LocalPlayer.PlayerScripts.Client.Managers.AnimationManager)

local player = game:GetService("Players").LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoid = char:FindFirstChild("Humanoid")
local animator = humanoid:FindFirstChild("Animator")

animationManager:initialize(animator)

animationManager:StartAnims(humanoid)
