local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local AnimationManager = {}

local function loadAnims(animator, animsToLoad, tableToPlaceThemIn)
    for name, anim in pairs(animsToLoad) do
        local track = animator:LoadAnimation(anim)

        if name == "Idle" or name == "Walk" or name == "Run" then
            track.Priority = Enum.AnimationPriority.Movement
        elseif name == "Jump" or name == "Fall" or name == "Land" then
            track.Priority = Enum.AnimationPriority.Action
        else
            track.Priority = Enum.AnimationPriority.Action2
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

function AnimationManager:Init(animator: Animator)
    self:StopAnims() 

    self.LoadedPickaxeAnims = {}
    self.LoadedRegularAnims = {}
    self.IsPickaxeEquipped = false

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

    loadAnims(animator, pickaxeAnimations, self.LoadedPickaxeAnims)
    loadAnims(animator, regularAnimations, self.LoadedRegularAnims)

    local humanoid = animator.Parent :: Humanoid

    self.StateConnection = humanoid.StateChanged:Connect(function(_, newState)
        if newState == Enum.HumanoidStateType.Landed then
            self:PlayOneShot("Land")
        end
    end)
end

function AnimationManager:StartAnims(humanoid: Humanoid)
    if self.UpdateConnection then self.UpdateConnection:Disconnect() end

    self.UpdateConnection = RunService.RenderStepped:Connect(function()
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

function AnimationManager:PlayExclusive(name: string)
    local currentSet = self.IsPickaxeEquipped and self.LoadedPickaxeAnims or self.LoadedRegularAnims
    local target = currentSet[name]

    if not target or target.IsPlaying then return end

    local movementTracks = {"Idle", "Walk", "Run", "Jump", "Fall"}
    for _, trackName in ipairs(movementTracks) do
        if trackName ~= name then
            if self.LoadedPickaxeAnims[trackName] then self.LoadedPickaxeAnims[trackName]:Stop(0.2) end
            if self.LoadedRegularAnims[trackName] then self.LoadedRegularAnims[trackName]:Stop(0.2) end
        end
    end

    target:Play(0.2)
end

function AnimationManager:PlayOneShot(name: string)
    local currentSet = self.IsPickaxeEquipped and self.LoadedPickaxeAnims or self.LoadedRegularAnims
    if currentSet[name] then
        currentSet[name]:Play(0.1)
    end
end

function AnimationManager:PlayEquip()
    if self.LoadedPickaxeAnims["Equip"] then
        self.LoadedPickaxeAnims["Equip"]:Play(0.1)
    end
end

function AnimationManager:PlaySwing(swingNumber: number)
    local name = "Swing" .. swingNumber
    if self.LoadedPickaxeAnims[name] then
        self.LoadedPickaxeAnims[name]:Play(0.1)
        return self.LoadedPickaxeAnims[name]
    end
    return nil
end

function AnimationManager:SetEquipped(equipped: boolean)
    self.IsPickaxeEquipped = equipped

    stopAllTracks(self.LoadedRegularAnims)
    stopAllTracks(self.LoadedPickaxeAnims)

    if equipped then
        self:PlayEquip()
    end
end

function AnimationManager:StopAnims()
    if self.UpdateConnection then 
        self.UpdateConnection:Disconnect() 
        self.UpdateConnection = nil 
    end
    if self.StateConnection then 
        self.StateConnection:Disconnect() 
        self.StateConnection = nil 
    end

    if self.LoadedPickaxeAnims then
        for _, track in pairs(self.LoadedPickaxeAnims) do track:Stop(0.2) end
    end
    if self.LoadedRegularAnims then
        for _, track in pairs(self.LoadedRegularAnims) do track:Stop(0.2) end
    end
end

return AnimationManager