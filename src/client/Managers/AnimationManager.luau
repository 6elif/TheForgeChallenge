local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local regularAnimsFolder = ReplicatedStorage.Assets.Animations.RegularAnims
local pickaxeAnimsFolder = ReplicatedStorage.Assets.Animations.PickaxeAnims

local pickaxeAnimations = {
	["Swing1"] = pickaxeAnimsFolder.Swing1,
	["Swing2"] = pickaxeAnimsFolder.Swing2,
	["Equip"] = pickaxeAnimsFolder.Equip,
	["Jump"] = pickaxeAnimsFolder.Jump,
	["Walk"] = pickaxeAnimsFolder.Walk,
	["Run"] = pickaxeAnimsFolder.Run,
	["Idle"] = pickaxeAnimsFolder.Idle,
	["Land"] = pickaxeAnimsFolder.Land,
	["Fall"] = pickaxeAnimsFolder.Fall,
}

local regularAnimations = {
	["Jump"] = regularAnimsFolder.Jump,
	["Walk"] = regularAnimsFolder.Walk,
	["Run"] = regularAnimsFolder.Run,
	["Idle"] = regularAnimsFolder.Idle,
	["Land"] = regularAnimsFolder.Land,
	["Fall"] = regularAnimsFolder.Fall,
}

local loadedPickaxeAnims = {}
local loadedRegularAnims = {}
local updateConnection = nil
local stateConnection = nil

local animationManager = {}
animationManager.IsPickaxeEquipped = false

local function loadAnims(animator, animsToLoad, tableToPlaceThemIn)
	for name, anim in pairs(animsToLoad) do
		local track = animator:LoadAnimation(anim)

		if name == "Idle" or name == "Walk" or name == "Run" then
			track.Priority = Enum.AnimationPriority.Movement
		elseif name == "Jump" or name == "Fall" or name == "Land" then
			track.Priority = Enum.AnimationPriority.Action
		else
			track.Priority = Enum.AnimationPriority.Action 
		end

		tableToPlaceThemIn[name] = track
	end
end

local function stopAllTracks(trackTable)
	for _, track in pairs(trackTable) do
		if track.IsPlaying then
			track:Stop(0.5)
		end
	end
end

function animationManager:initialize(animator: Animator)
	table.clear(loadedPickaxeAnims)
	table.clear(loadedRegularAnims)

	loadAnims(animator, pickaxeAnimations, loadedPickaxeAnims)
	loadAnims(animator, regularAnimations, loadedRegularAnims)

	local humanoid = animator.Parent :: Humanoid
	if stateConnection then stateConnection:Disconnect() end

	stateConnection = humanoid.StateChanged:Connect(function(_, newState)
		if newState == Enum.HumanoidStateType.Landed then
			self:PlayOneShot("Land")
		end
	end)
end

function animationManager:StartAnims(humanoid)
	if updateConnection then updateConnection:Disconnect() end

	updateConnection = RunService.RenderStepped:Connect(function()
		local velocity = humanoid.MoveDirection.Magnitude
		local state = humanoid:GetState()

		if state == Enum.HumanoidStateType.Jumping then
			self:PlayExclusive("Jump")
			return
		elseif state == Enum.HumanoidStateType.Freefall then
			self:PlayExclusive("Fall")
			return
		end

		if velocity > 0.1 then
			if humanoid.WalkSpeed > 20 then
				self:PlayExclusive("Run")
			else
				self:PlayExclusive("Walk")
			end
		else
			self:PlayExclusive("Idle")
		end
	end)
end

function animationManager:PlayExclusive(name)
	local currentSet = self.IsPickaxeEquipped and loadedPickaxeAnims or loadedRegularAnims
	local target = currentSet[name]

	if not target or target.IsPlaying then return end

	local movementTracks = {"Idle", "Walk", "Run", "Jump", "Fall"}
	for _, trackName in ipairs(movementTracks) do
		if trackName ~= name then
			if loadedPickaxeAnims[trackName] then loadedPickaxeAnims[trackName]:Stop(0.2) end
			if loadedRegularAnims[trackName] then loadedRegularAnims[trackName]:Stop(0.2) end
		end
	end

	target:Play(0.2)
end

function animationManager:PlayOneShot(name)
	local currentSet = self.IsPickaxeEquipped and loadedPickaxeAnims or loadedRegularAnims
	if currentSet[name] then
		currentSet[name]:Play(0.1)
	end
end

function animationManager:PlayEquip()
	if loadedPickaxeAnims["Equip"] then
		loadedPickaxeAnims["Equip"]:Play(0.1)
	end
end

function animationManager:PlaySwing(swingNumber)
	local name = "Swing" .. swingNumber
	if loadedPickaxeAnims[name] then
		loadedPickaxeAnims[name]:Play(0.1)
		return loadedPickaxeAnims[name]
	end
end

function animationManager:SetEquipped(equipped: boolean)
	self.IsPickaxeEquipped = equipped

	stopAllTracks(loadedRegularAnims)
	stopAllTracks(loadedPickaxeAnims)

	if equipped then
		self:PlayEquip()
	end
end

function animationManager:StopAnims()
	if updateConnection then updateConnection:Disconnect(); updateConnection = nil end
	if stateConnection then stateConnection:Disconnect(); stateConnection = nil end

	for _, track in pairs(loadedPickaxeAnims) do track:Stop(0.2) end
	for _, track in pairs(loadedRegularAnims) do track:Stop(0.2) end
end

return animationManager