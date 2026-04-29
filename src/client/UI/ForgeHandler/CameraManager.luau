local TweenService = game:GetService("TweenService")

local forge = workspace:WaitForChild("Forge")
local defaultCamPos = forge:WaitForChild("CamPos1")
local pumpCamPos = forge:WaitForChild("CamPos2")
local pourCamPos = forge:WaitForChild("CamPos3")

local cam = workspace.CurrentCamera

local camManager = {}

local moveInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function camManager:SetToForge()
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = defaultCamPos.CFrame
end

function camManager:BackToDefault()
	cam.CameraType = Enum.CameraType.Custom
end

function camManager:SetToPump()
	local pumpTween = TweenService:Create(cam, moveInfo, {CFrame = pumpCamPos.CFrame})
	pumpTween:Play()
end

function camManager:SetToPour()
	local pourTween = TweenService:Create(cam, moveInfo, {CFrame = pourCamPos.CFrame})
	pourTween:Play()
end

function camManager:TestCam()
	task.spawn(function()
		camManager:SetToForge()
		task.wait(1)
		camManager:SetToPump()
	end)
end

return camManager
