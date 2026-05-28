local RepStorage = game:GetService("ReplicatedStorage")

local ArmorProbabilities = require(RepStorage.Shared.Data.ArmorProbabilities)
local WeaponProbabilities = require(RepStorage.Shared.Data.WeaponProbabilities)
local AddOresToFrame = require(script.Parent.Utils.AddOresToFrame)
local OreDataModule = require(RepStorage.Shared.Data.OreData)
local UIAnims = require(script.Parent.Utils.UIAnims)
local ForgeConfig = require(script.ForgeConfig)

local Forge = {}

Forge.ForgeToggleRequested = Instance.new("BindableEvent")
Forge.MAX_HOLD_TIME = ForgeConfig.MaxHoldTimeBeforeRemovingOre

local function getQuantity(textLabel)
    if not textLabel or not textLabel.Visible then return 1 end
    local str = string.gsub(textLabel.Text, "%D", "")
    return tonumber(str) or 1
end

local function cleanUpOreFrame(data)
    data.OreInFrame = nil
    if data.Button:FindFirstChild("OreImage") then data.Button.OreImage:Destroy() end
    if data.Button:FindFirstChild("Shadow") then data.Button.Shadow:Destroy() end
    data.Button.NameLabel.Text = "Empty"
    data.Button.Quantity.Visible = false
    
    data.Button.UIStroke.Color = Color3.new(0.258824, 0.258824, 0.258824)
    data.Button.Corners.GroupColor3 = Color3.new(0.588235, 0.588235, 0.588235)
    data.Button.BackgroundColor3 = Color3.new(0.176471, 0.176471, 0.176471)
    data.Button.ImageTransparency = 1
end

function Forge:ForgeButtonActivated()
    if self.TotalAmountOfOres < 3 then return end
            
    self.GuiAnimationManager:MainVisible(false)
    
    self.CamManager:SetToPump()
    self.BucketManager:Pump()
    self.CounterManager:StartCount()
    self.GuiAnimationManager:TransitionToPump()
    self.Pump:Start()
    self.Pump:WaitUntilEnds()
    self.GuiAnimationManager:TransitionOffPump()
    
    self.CamManager:SetToPour()
    self.BucketManager:Pour()
    self.CounterManager:StartCount()
    self.GuiAnimationManager:PourVisible(true)
    self.PourManager:Start()
    self.PourManager:WaitUntilEnds()
    self.GuiAnimationManager:PourVisible(false)
    
    self:CloseForgeGui()
end

function Forge:Init()
    self.Pump = require(script.PumpManager)
    self.CounterManager = require(script.CounterManager)
    self.CamManager = require(script.CameraManager)
    self.BucketManager = require(script.BucketMovementManager)
    self.GuiAnimationManager = require(script.GuiAnimationManager)
    self.PourManager = require(script.PourManager)

    self.Player = game:GetService("Players").LocalPlayer
    self.PlayerGui = self.Player:WaitForChild("PlayerGui")
    self.ForgeGui = self.PlayerGui:WaitForChild("ForgeGui")
    self.MainFrame = self.ForgeGui:WaitForChild("MainFrame")
    self.SelectFrame = self.MainFrame:WaitForChild("SelectFrame")
    self.SelectScroll = self.SelectFrame:WaitForChild("ScrollingFrame")
    self.CloseButton = self.SelectFrame:WaitForChild("Title"):WaitForChild("Close")
    self.WeaponButton = self.SelectFrame:WaitForChild("Weapon")
    self.ArmorButton = self.SelectFrame:WaitForChild("Armor")

    self.ForgeButtonFrame = self.MainFrame:WaitForChild("ForgeButtonFrame")
    self.SlotFrame = self.ForgeButtonFrame:WaitForChild("SlotFrame")
    self.MultiplierTextLabel = self.ForgeButtonFrame:WaitForChild("MultiplierFrame"):WaitForChild("TextCanvas"):WaitForChild("TextLabel")

    self.ForgeButton = self.ForgeButtonFrame:WaitForChild("ForgeButton")

    self.ChancesFrame = self.MainFrame:WaitForChild("ChanceFrame")
    self.WeaponScroll = self.ChancesFrame:WaitForChild("WeaponScroll")
    self.ArmorScroll = self.ChancesFrame:WaitForChild("ArmorScroll")

    self.TotalAmountOfOres = 0

    self.Slots = {
        Slot1 = {Button = self.SlotFrame.Slot1, OreInFrame = nil},
        Slot2 = {Button = self.SlotFrame.Slot2, OreInFrame = nil},
        Slot3 = {Button = self.SlotFrame.Slot3, OreInFrame = nil},
        Slot4 = {Button = self.SlotFrame.Slot4, OreInFrame = nil},
    }

    self.Connections = {}
end

function Forge:Start(forgeModel)
    self.ForgeModel = forgeModel
    self.ProximityPrompt = self.ForgeModel:WaitForChild("ProximityPart").ProximityPrompt

    self.BucketManager:Init(forgeModel)
    self.CamManager:Init(forgeModel)
    self.CounterManager:Init()
    self.GuiAnimationManager:Init()
    self.PourManager:Init()
    self.Pump:Init()

    self.ForgeButton.Activated:Connect(function()
        self:ForgeButtonActivated()
    end)

    self.ProximityPrompt.Triggered:Connect(function()
        self.ForgeToggleRequested:Fire()
        self:OpenForgeGui()
    end)

    self.CloseButton.Activated:Connect(function()
        self.ForgeToggleRequested:Fire()
    end)

    self.WeaponButton.Activated:Connect(function()
        self.WeaponScroll.Visible = true
    end)

    self.ArmorButton.Activated:Connect(function()
        self.ArmorScroll.Visible = true
    end)

    self.WeaponScroll:GetPropertyChangedSignal("Visible"):Connect(function()
        if self.WeaponScroll.Visible then
            self:ChangeButtonColor(self.WeaponButton, true)
            self.ArmorScroll.Visible = false
        else
            self:ChangeButtonColor(self.WeaponButton, false)
        end
    end)

    self.ArmorScroll:GetPropertyChangedSignal("Visible"):Connect(function()
        if self.ArmorScroll.Visible then
            self.WeaponScroll.Visible = false
            self:ChangeButtonColor(self.ArmorButton, true)
        else
            self:ChangeButtonColor(self.ArmorButton, false)
        end
    end)

    local listOfButtons = {
        self.ArmorButton,
        self.WeaponButton,  
        self.ForgeButton,
    }

    for _, button in ipairs(listOfButtons) do
        local data = {defaultSize = button.Size}
        
        if button == self.ForgeButton then
            data = {
                defaultSize = self.ForgeButtonFrame.Size,
                frameInsteadOfButton = self.ForgeButtonFrame,
                maxSize = UDim2.fromScale(self.ForgeButtonFrame.Size.X.Scale * 1.025, self.ForgeButtonFrame.Size.Y.Scale * 1.025),
                minSize = UDim2.fromScale(self.ForgeButtonFrame.Size.X.Scale * 0.95, self.ForgeButtonFrame.Size.Y.Scale * 0.95),
            }
        end
        
        UIAnims.AddAnimationsToButton(button, data)
    end

    self:HandleSlots()
end

function Forge:CleanUp()
    for _, oreButton in ipairs(self.SelectScroll:GetChildren()) do
        if not oreButton:IsA("ImageButton") then continue end
        
        UIAnims.CleanUp(oreButton)
        oreButton:Destroy()
    end
    
    for _, data in pairs(self.Slots) do
        cleanUpOreFrame(data)
    end
    
    for _, tracker in pairs(self.Connections) do
        for _, con in pairs(tracker) do
            con:Disconnect()
        end
    end
    table.clear(self.Connections)
end

function Forge:FindOpenSlot()
    for slot, data in pairs(self.Slots) do
        if not data.OreInFrame then
            return slot, data.Button
        end
    end
    return nil
end

function Forge:CheckIfOreInSlot(ore)
    for _, data in pairs(self.Slots) do
        if data.OreInFrame == ore then
            return data.Button
        end
    end
    return nil
end

function Forge:UpdateChances()
    local function makeDefaultSingleFrame(catFrame)
        local textFrame = catFrame.TextFrame
        local textLabel = textFrame.Text

        local name = string.gsub(catFrame.Name, "([%l])([%u])", "%1 %2")
        textLabel.Text = name.." (0%)"
        catFrame.LayoutOrder = 0
        
        textFrame.UIGradient.Color = ColorSequence.new(Color3.new(1, 1, 1))
        textFrame.UIGradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 1),
            NumberSequenceKeypoint.new(1, 1)
        })
        
        for _, item in ipairs(catFrame.Frame:GetChildren()) do
            if not item:IsA("Frame") then continue end
            item.UIStroke.Color = Color3.new(0.4, 0.4, 0.4)
            item.ImageButton.ImageColor3 = Color3.new(0.380392, 0.380392, 0.380392)
            item.Text.TextColor3 = Color3.new(0.380392, 0.380392, 0.380392)
            item.Corners.GroupColor3 = Color3.new(0.247059, 0.247059, 0.247059)
            item.BackgroundColor3 = Color3.new(0.133333, 0.133333, 0.133333)
        end
    end
    
    local function makeDefaultAll()
        for _, catFrame in ipairs(self.WeaponScroll:GetChildren()) do
            if not catFrame:IsA("Frame") then continue end
            makeDefaultSingleFrame(catFrame)
        end
        
        for _, catFrame in ipairs(self.ArmorScroll:GetChildren()) do
            if not catFrame:IsA("Frame") then continue end
            makeDefaultSingleFrame(catFrame)
        end
    end
    
    local function updateFrames(category, probability)
        local probPercent = math.round(probability * 100)
        local catFrame = if self.WeaponScroll:FindFirstChild(category) then self.WeaponScroll[category] else self.ArmorScroll[category]
        if not catFrame then return end

        local textFrame = catFrame.TextFrame
        local textLabel = textFrame.Text

        local name = string.gsub(category, "([%l])([%u])", "%1 %2")
        textLabel.Text = name.." ("..probPercent.."%)"
        catFrame.LayoutOrder = -probPercent
        
        local colorValue = 1 - (0.35 * probPercent) / 100
        if probPercent > 0 then
            textFrame.UIGradient.Color = ColorSequence.new(Color3.new(0.984314, 1, 0))
            textFrame.UIGradient.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, colorValue),
                NumberSequenceKeypoint.new(1, 1)
            })
            
            for _, item in ipairs(catFrame.Frame:GetChildren()) do
                if not item:IsA("Frame") then continue end
                item.UIStroke.Color = Color3.new(1, 1, 1)
                item.ImageButton.ImageColor3 = Color3.new(1, 1, 1)
                item.Text.TextColor3 = Color3.new(1, 1, 1)
                item.Corners.GroupColor3 = Color3.new(0.407843, 0.407843, 0.407843)
                item.BackgroundColor3 = Color3.new(0.243137, 0.243137, 0.243137)
            end
        else
            makeDefaultSingleFrame(catFrame)
        end
    end
    
    local weaponProbabilityTable = WeaponProbabilities[self.TotalAmountOfOres]
    local armorProbabilityTable = ArmorProbabilities[self.TotalAmountOfOres]
    
    if not weaponProbabilityTable or not armorProbabilityTable then 
        makeDefaultAll()
        return 
    end
    
    task.spawn(function()
        for category, probability in pairs(weaponProbabilityTable) do
            updateFrames(category, probability)
        end
    end)
    
    for category, probability in pairs(armorProbabilityTable) do
        updateFrames(category, probability)
    end
end

function Forge:Update()
    local totalMult = 0
    local localTotalOres = 0
    for _, data in pairs(self.Slots) do
        if not data.OreInFrame then continue end
        
        local quantity = getQuantity(data.Button.Quantity)
        local oreData = OreDataModule.GetOreData(data.OreInFrame)
        local mult = 0
        if oreData then
            mult = oreData.Multiplier
        end
        
        localTotalOres += quantity
        totalMult += (mult * quantity)
    end
    
    self.TotalAmountOfOres = localTotalOres
    
    local finalMult = math.round((totalMult / localTotalOres) * 100) / 100
    if totalMult == 0 then
        finalMult = 0
    end
    self.MultiplierTextLabel.Text = "Multiplier: "..finalMult.."x"
    
    if self.TotalAmountOfOres >= 3 then
        self.ForgeButton.Text.TextColor3 = Color3.new(1, 1, 1)
        self.ForgeButton.Corners.GroupColor3 = Color3.new(0.780392, 0.768627, 0.47451)
        self.ForgeButton.UIStroke.Color = Color3.new(0.423529, 0.423529, 0.207843)
    else
        self.ForgeButton.Text.TextColor3 = Color3.new(0.384314, 0.384314, 0.384314)
        self.ForgeButton.Corners.GroupColor3 = Color3.new(0.219608, 0.219608, 0.219608)
        self.ForgeButton.UIStroke.Color = Color3.new(0.211765, 0.211765, 0.211765)
    end
    
    self:UpdateChances()
end

function Forge:HandleSlots()
    for _, data in pairs(self.Slots) do
        local holdTime = 0
        local holdingButton = false

        data.Button.MouseButton1Down:Connect(function()
            if not data.OreInFrame then return end
            
            holdingButton = true
            local holdStart = time()
            while holdingButton do
                task.wait()
                holdTime = time() - holdStart

                if holdTime >= self.MAX_HOLD_TIME then
                    holdingButton = false
                    cleanUpOreFrame(data)
                end
            end
            
            if holdTime < self.MAX_HOLD_TIME then
                local quantity = getQuantity(data.Button.Quantity)
                if quantity == 1 then
                    cleanUpOreFrame(data)
                else
                    data.Button.Quantity.Text = "x"..(quantity - 1)
                end
            end
            self:Update()
        end)

        data.Button.MouseButton1Up:Connect(function()
            holdingButton = false
        end)
    end
end

function Forge:HandleButtons(oreButtons)
    for _, oreButton in ipairs(oreButtons) do
        local tracker = {
            clickCon = nil
        }
        tracker.clickCon = oreButton.Activated:Connect(function()
            local maxQuantity = getQuantity(oreButton.Quantity)
            local slotButton = self:CheckIfOreInSlot(oreButton.Name)
            
            if slotButton then
                local previousQuantity = getQuantity(slotButton.Quantity)
                if previousQuantity >= maxQuantity then
                    warn("EverythingAdded")
                else
                    slotButton.Quantity.Text = "x"..(previousQuantity + 1)
                end
            else
                local slot, openSlotButton = self:FindOpenSlot()
                if openSlotButton then
                    self.Slots[slot].OreInFrame = oreButton.Name
                    local oreImage = oreButton.OreImage:Clone()
                    local oreShadow = oreButton.Shadow:Clone()
                    
                    oreImage.Parent = openSlotButton
                    oreShadow.Parent = openSlotButton
                    
                    openSlotButton.NameLabel.Text = oreButton.Name
                    openSlotButton.Quantity.Text = "x1"
                    openSlotButton.Quantity.Visible = true
                    
                    local _, color = OreDataModule.GetOreData(oreButton.Name)
                    local hue, sat, value = color:ToHSV()
                    
                    openSlotButton.UIStroke.Color = Color3.fromHSV(hue, sat, value * 0.35)
                    openSlotButton.Corners.GroupColor3 = Color3.fromHSV(hue, sat, value * 0.50)
                    openSlotButton.BackgroundColor3 = Color3.fromHSV(hue, sat, value * 0.40)
                    openSlotButton.ImageTransparency = 0.9
                end
            end
            
            self:Update()
        end)

        self.Connections[oreButton] = tracker
    end
end

function Forge:OpenForgeGui()
    local allButtons = AddOresToFrame.AddOres(self.SelectScroll)
    
    for _, button in ipairs(allButtons) do
        local frame = Instance.new("Frame")
        frame.BackgroundTransparency = 1
        frame.Size = UDim2.fromScale(1, 1)
        frame.AnchorPoint = Vector2.new(0.5, 0.5)
        frame.Position = UDim2.fromScale(0.5, 0.5)
        
        button.Parent = frame
        frame.Parent = self.SelectScroll
        
        UIAnims.AddAnimationsToButton(button, {defaultSize = button.Size})
    end
    
    self:HandleButtons(allButtons)
    self:Update()
    
    self.GuiAnimationManager:BlackBarsVisible(false)
    self.ProximityPrompt.Enabled = false
    
    self.GuiAnimationManager:FadeInPlay()
    self.GuiAnimationManager:MainVisible(true)
    self.GuiAnimationManager:BlackBarsVisible(true)
    
    self.CamManager:SetToForge()
    self.GuiAnimationManager:FadeOutPlay()
end

function Forge:CloseForgeGui()
    self.GuiAnimationManager:FadeInPlay()
    self:CleanUp()
    
    self.GuiAnimationManager:MainVisible(false)
    self.GuiAnimationManager:BlackBarsVisible(false)
    self.ProximityPrompt.Enabled = true
    
    self.CamManager:BackToDefault()
    self.GuiAnimationManager:FadeOutPlay()
end

function Forge:ChangeButtonColor(button, on)
    if on then
        button.Corners.GroupColor3 = Color3.new(0.729412, 0.729412, 0.729412)
        button.UIStroke.Color = Color3.new(1, 1, 1)
        button.Text.TextColor3 = Color3.new(1, 1, 1)
        button.UIGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0.152941, 0.152941, 0.152941)),
            ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1))
        })
    else
        button.Corners.GroupColor3 = Color3.new(0.313725, 0.313725, 0.313725)
        button.UIStroke.Color = Color3.new(0.568627, 0.568627, 0.568627)
        button.Text.TextColor3 = Color3.new(0.568627, 0.568627, 0.568627)
        button.UIGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.new(0.152941, 0.152941, 0.152941)),
            ColorSequenceKeypoint.new(1, Color3.new(0.152941, 0.152941, 0.152941))
        })
    end
end

return Forge