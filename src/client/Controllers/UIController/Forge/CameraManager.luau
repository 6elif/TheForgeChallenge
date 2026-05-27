local TweenService = game:GetService("TweenService")

local CamManager = {}

local moveInfo = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

function CamManager:Init(forgeModel)
	self.Cam = workspace.CurrentCamera

	self.ForgeModel = workspace:WaitForChild("Forge")
	self.DefaultCamPos = self.ForgeModel:WaitForChild("CamPos1")
	self.PumpCamPos = self.ForgeModel:WaitForChild("CamPos2")
	self.PourCamPos = self.ForgeModel:WaitForChild("CamPos3")

end

function CamManager:SetToForge()
	self.Cam.CameraType = Enum.CameraType.Scriptable
	self.Cam.CFrame = self.DefaultCamPos.CFrame
end

function CamManager:BackToDefault()
	self.Cam.CameraType = Enum.CameraType.Custom
end

function CamManager:SetToPump()
	local pumpTween = TweenService:Create(self.Cam, moveInfo, {CFrame = self.PumpCamPos.CFrame})
	pumpTween:Play()
end

function CamManager:SetToPour()
	local pourTween = TweenService:Create(self.Cam, moveInfo, {CFrame = self.PourCamPos.CFrame})
	pourTween:Play()
end

function CamManager:TestCam()
	task.spawn(function()
		self:SetToForge()
		task.wait(1)
		self:SetToPump()
	end)
end

return CamManager
