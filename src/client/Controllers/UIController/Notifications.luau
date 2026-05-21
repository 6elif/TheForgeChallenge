local RepStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local events = RepStorage.Assets.Network.Events
local collectedEvent = events.OreCollected
local hitEvent = events.Hit
local notificationEvent = events.Notification

local oreDataModule = require(RepStorage.Shared.Data.OreData)
local soundManager = require(script.Parent.Parent.Parent.Managers.SoundManager)
local oreFolder = RepStorage.Assets.Models.Ores

local Notifications = {}

function Notifications:Init()
    self.Player = Players.LocalPlayer
    self.PlayerGui = self.Player:WaitForChild("PlayerGui")
    
    self.NotificationGui = self.PlayerGui:WaitForChild("NotificationGui")
    self.MainFrame = self.NotificationGui.MainFrame
    self.FlashEffect = self.NotificationGui.Parent.MiningGui.FlashEffect

    self.OreDropTemplate = self.MainFrame.OreDropTemplate
    self.BaseNotTemplate = self.MainFrame.BaseNotificationTemplate

    self.FlashEffectDb = false
    self.NewFlash = false
    self.PreviousFlashTween = nil
end

function Notifications:PopupText(canvas, dir)
    dir = dir or 1
    canvas.UIGradient.Transparency = NumberSequence.new(dir == 1 and 1 or 0)

    local waitTime = 0.02
    local edgeSoftness = 0.05

    for i = 0, 1, 0.05 do
        local keypoints = {}

        for pos = 0, 1, 0.1 do
            local transparency
            if dir == 1 then
                transparency = math.clamp((pos - i) / edgeSoftness, 0, 1)
            else
                transparency = math.clamp((pos - (1 - i)) / edgeSoftness, 0, 1)
            end
            table.insert(keypoints, NumberSequenceKeypoint.new(pos, transparency))
        end

        canvas.UIGradient.Transparency = NumberSequence.new(keypoints)
        task.wait(waitTime)
    end

    canvas.UIGradient.Transparency = NumberSequence.new(dir == 1 and 0 or 1)
end

function Notifications:OrePopUp(ore, dir)
    dir = dir or 1
    
    local info, tween
    if dir == 1 then
        ore.Position = UDim2.new(0.5, 0, 1.5, 0)
        info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
        tween = TweenService:Create(ore, info, {Position = UDim2.new(0.5, 0, 0.5, 0)})
    else
        info = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        tween = TweenService:Create(ore, info, {Position = UDim2.new(0.5, 0, 1.5, 0)})
    end
    
    tween:Play()
end

function Notifications:FadeInOut(Ui, dir)
    dir = dir or 1
    
    local info, tween
    if dir == 1 then
        Ui.ImageTransparency = 1
        info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        tween = TweenService:Create(Ui, info, {ImageTransparency = 0})
    else
        info = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
        tween = TweenService:Create(Ui, info, {ImageTransparency = 1})
    end

    tween:Play()
end

function Notifications:PlayFlashEffect(finalHit, oresDropped)
    if self.FlashEffectDb then return end

    self.FlashEffect.Flash1.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
    self.FlashEffect.Flash2.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))

    if self.FlashEffect.Visible then
        self.NewFlash = true
        if self.PreviousFlashTween then
            self.PreviousFlashTween:Cancel()
        end
    end
    self.FlashEffectDb = true
    self.FlashEffect.Visible = true

    if oresDropped then
        local highestRarity = "Common"

        for _, oreName in pairs(oresDropped) do
            local oreData, _ = oreDataModule.GetOreData(oreName)
            
            if oreData.Rarity == "Epic" then
                highestRarity = "Epic"
            elseif oreData.Rarity == "Rare" and highestRarity ~= "Epic" then
                highestRarity = "Rare"
            elseif oreData.Rarity == "Uncommon" and highestRarity ~= "Epic" and highestRarity ~= "Rare" then
                highestRarity = "Uncommon"
            end
        end

        local rarityColor = oreDataModule.RarityColors[highestRarity]
        self.FlashEffect.Flash1.UIGradient.Color = ColorSequence.new(rarityColor)
        self.FlashEffect.Flash2.UIGradient.Color = ColorSequence.new(rarityColor) 
    end

    local flashInfo
    if finalHit then
        self.FlashEffect.GroupTransparency = 0
        flashInfo = TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    else
        self.FlashEffect.GroupTransparency = 0.5
        flashInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    end

    local flashTween = TweenService:Create(self.FlashEffect, flashInfo, {GroupTransparency = 1})
    flashTween:Play()
    self.PreviousFlashTween = flashTween

    task.delay(0.2, function()
        self.FlashEffectDb = false
    end)

    flashTween.Completed:Wait()

    if not self.NewFlash then
        self.FlashEffect.Visible = false
    else
        self.NewFlash = false
    end
end

function Notifications:ShowOreDrop(oreName)
    local oreData, color = oreDataModule.GetOreData(oreName)
    
    if not color or not oreData then return end
    
    soundManager.PlaySound({soundName = "OreCollected", category = "SFX"})
    
    local r = math.floor(color.R * 255)
    local g = math.floor(color.G * 255)
    local b = math.floor(color.B * 255)
    
    local dropGui = self.OreDropTemplate:Clone()
    
    local oreModel = if oreFolder:FindFirstChild(oreName) then oreFolder[oreName]:Clone() else oreFolder.Placeholder:Clone()
    oreModel.Parent = dropGui.OreFrame.OreImageCanv.OreImage
    
    local message = "You just found <font color=\"rgb("..r..", "..g..", "..b..")\">"..oreData.Rarity.."</font> "
        .. oreName ..", 1 in ".. oreData.Chance .." chance!"
    
    dropGui.TextFrame.TextCanvas.TextLabel.Text = message
    dropGui.OreFrame.ImageLabel.ImageColor3 = color
    dropGui.Name = oreName
    dropGui.Parent = self.MainFrame
    dropGui.Visible = true
    
    local rotationTween = TweenService:Create(
        dropGui.OreFrame.ImageLabel, 
        TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1), 
        {Rotation = 360}
    )
    rotationTween:Play()
    
    self:FadeInOut(dropGui.OreFrame.ImageLabel, 1)
    self:OrePopUp(dropGui.OreFrame.OreImageCanv.OreImage, 1)
    self:PopupText(dropGui.TextFrame.TextCanvas, 1)
    
    task.wait(1.5)

    self:FadeInOut(dropGui.OreFrame.ImageLabel, -1)
    self:OrePopUp(dropGui.OreFrame.OreImageCanv.OreImage, -1)
    self:PopupText(dropGui.TextFrame.TextCanvas, -1)
    
    rotationTween:Cancel()
    dropGui:Destroy()
end

function Notifications:NotEnoughDmg(value)
    local gui = self.BaseNotTemplate:Clone()
    gui.Parent = self.MainFrame
    gui.TextCanvas.TextLabel.TextColor3 = Color3.new(1, 0, 0.0156863)
    gui.TextCanvas.TextLabel.Text = "You need to deal at least ".. value .." base damage to mine this rock!"
    gui.Visible = true
    
    self:PopupText(gui.TextCanvas, 1)
    task.wait(1.5)
    self:PopupText(gui.TextCanvas, -1)
    
    gui:Destroy()
end

function Notifications:OtherPlayersRock()
    local gui = self.BaseNotTemplate:Clone()
    gui.Parent = self.MainFrame
    gui.TextCanvas.TextLabel.TextColor3 = Color3.new(1, 0, 0.0156863)
    gui.TextCanvas.TextLabel.Text = "Someone else is already mining this rock!"
    gui.Visible = true

    self:PopupText(gui.TextCanvas, 1)
    task.wait(1.5)
    self:PopupText(gui.TextCanvas, -1)

    gui:Destroy()
end

function Notifications:Start()
    hitEvent.OnClientEvent:Connect(function(finalHit, oresDropped)
        self:PlayFlashEffect(finalHit, oresDropped)
    end)

    collectedEvent.OnClientEvent:Connect(function(oreName)
        task.spawn(function()
            self:ShowOreDrop(oreName)
        end)
    end)

    notificationEvent.OnClientEvent:Connect(function(notification, value)
        task.spawn(function()
            if notification == "NotEnoughDmg" then
                self:NotEnoughDmg(value)
            elseif notification == "OtherPlayersRock"  then
                self:OtherPlayersRock()
            end
        end)
    end)
end

return Notifications