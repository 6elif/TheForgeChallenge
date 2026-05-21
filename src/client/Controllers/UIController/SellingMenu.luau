local RepStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local addOresToFrame = require(script.Parent.Utils.AddOresToFrame)

local function getQuantity(textLabel: TextLabel)
    if not textLabel or not textLabel.Visible then return 1 end
    local str = string.gsub(textLabel.Text, "%D", "")
    return tonumber(str) or 1
end

local SellingMenu = {}

SellingMenu.CloseRequested = Instance.new("BindableEvent")
SellingMenu.MAX_HOLD_TIME = 1

function SellingMenu:Init()
    self.Player = Players.LocalPlayer
    self.PlayerGui = self.Player:WaitForChild("PlayerGui")
    
    self.SellGui = self.PlayerGui:WaitForChild("SellGui")
    self.MainFrame = self.SellGui.MainFrame
    self.MainSellFrame = self.MainFrame.InnerFrame.MainSell
    self.MainContainer = self.MainSellFrame.Container
    
    self.PersonalStashScroll = self.MainContainer.PersonalStash.ScrollingFrame
    self.SelectedItemsScroll = self.MainContainer.SelectedItems.ScrollingFrame
    
    self.PopUp = self.MainFrame.PopUp
    self.InputFrame = self.PopUp.InnerFrame.Main.InputFrame
    self.TextBox = self.InputFrame.TextBox
    
    self.CloseButton = self.MainSellFrame.Title.Close
    self.ClosePopUpButton = self.PopUp.InnerFrame.Main.Title.Close
    self.AcceptButton = self.MainFrame.InnerFrame.SelectionButtons.Accept.Button
    self.SelectAllButton = self.MainFrame.InnerFrame.SelectionButtons.Accept.SellectAllButton
    self.PopUpSelectButton = self.PopUp.InnerFrame.Main.Container.SelectButton
    
    self.SellItemsEvent = RepStorage.Assets.Network.Events.SellItems

    self.Connections = {}
    self.SelectedItem = nil
end

function SellingMenu:UpdateTextBox(newAmount)
    self.TextBox.Text = tostring(newAmount)
end

function SellingMenu:ItemPressCon(oreButton)
    local tracker = { Pressed = nil, ParentChange = nil }
    
    tracker.Pressed = oreButton.MouseButton1Down:Connect(function()
        if oreButton.Parent == self.PersonalStashScroll then
            self.PopUp.Visible = true
            self.PopUp.InnerFrame.Main.Container.Text.Text = "How many of " .. oreButton.Name .. " do you want to select?"
            self.SelectedItem = oreButton
            self:UpdateTextBox(1)
        end
    end)
    
    tracker.ParentChange = oreButton:GetPropertyChangedSignal("Parent"):Connect(function()
        if oreButton.Parent ~= self.PersonalStashScroll then
            tracker.Pressed:Disconnect()
            tracker.ParentChange:Disconnect()
            self.Connections[oreButton] = nil
        end
    end)
    
    self.Connections[oreButton] = tracker
end

function SellingMenu:InSelectedCon(newItem)
    local tracker = { HoldStartCon = nil, HoldEndCon = nil }
    
    local function cleanUp()
        if tracker.HoldStartCon then tracker.HoldStartCon:Disconnect() end
        if tracker.HoldEndCon then tracker.HoldEndCon:Disconnect() end
        self.Connections[newItem] = nil
    end
    
    local function moveAll()
        local itemInStash = self.PersonalStashScroll:FindFirstChild(newItem.Name)
        local addQuantity = getQuantity(newItem.Quantity)

        if not itemInStash then
            newItem.Parent = self.PersonalStashScroll
            cleanUp()
            self:ItemPressCon(newItem)
            return
        else
            local inStashQuantity = getQuantity(itemInStash.Quantity)
            itemInStash.Quantity.Visible = true
            itemInStash.Quantity.Text = "x" .. tostring(inStashQuantity + addQuantity)
        end
        newItem:Destroy()
    end 
    
    local function moveOne()
        local itemInStash = self.PersonalStashScroll:FindFirstChild(newItem.Name)

        if not itemInStash then
            itemInStash = newItem:Clone()
            itemInStash.Parent = self.PersonalStashScroll
            itemInStash.Quantity.Text = "x1"
            itemInStash.Quantity.Visible = false
            self:ItemPressCon(itemInStash)
        else
            local itemInStashQuantity = getQuantity(itemInStash.Quantity)
            itemInStash.Quantity.Visible = true
            itemInStash.Quantity.Text = "x" .. tostring(itemInStashQuantity + 1)
        end
        
        local itemInSelectQuantity = getQuantity(newItem.Quantity)
        
        if itemInSelectQuantity - 1 == 0 then
            cleanUp()
            newItem:Destroy()
        elseif itemInSelectQuantity - 1 == 1 then
            newItem.Quantity.Text = "x1"
            newItem.Quantity.Visible = false
        else
            newItem.Quantity.Text = "x" .. tostring(itemInSelectQuantity - 1)
        end
    end

    local holdTime = 0
    local holdingButton = false
    
    tracker.HoldStartCon = newItem.MouseButton1Down:Connect(function()
        holdingButton = true
        local holdStart = time()
        while holdingButton do
            task.wait()
            holdTime = time() - holdStart
            
            if holdTime >= self.MAX_HOLD_TIME then
                holdingButton = false
                moveAll()
            end
        end
        if holdTime < self.MAX_HOLD_TIME then
            moveOne()
        end
    end)
    
    tracker.HoldEndCon = newItem.MouseButton1Up:Connect(function()
        holdingButton = false
    end)
    
    self.Connections[newItem] = tracker
end

function SellingMenu:LoadInItems()
    local oreButtons = addOresToFrame.AddOres(self.PersonalStashScroll)
    
    for _, oreButton in ipairs(oreButtons) do
        self:ItemPressCon(oreButton)
    end
end

function SellingMenu:CleanScrolls()
    for obj, tracker in pairs(self.Connections) do
        for _, con in pairs(tracker) do
            con:Disconnect()
        end
    end
    table.clear(self.Connections)
    
    for _, item in ipairs(self.SelectedItemsScroll:GetChildren()) do
        if item:IsA("ImageButton") and item.Visible then 
            item:Destroy() 
        end
    end
    
    for _, item in ipairs(self.PersonalStashScroll:GetChildren()) do
        if item:IsA("ImageButton") and item.Visible then 
            item:Destroy() 
        end
    end
end

function SellingMenu:SetVisible(visible: boolean)
    self.MainFrame.Visible = visible
    if visible then
        self:LoadInItems()
    else
        self:CleanScrolls()
    end
end

function SellingMenu:Start()
    self.CloseButton.Activated:Connect(function()
        self.CloseRequested:Fire()
    end)

    self.ClosePopUpButton.Activated:Connect(function()
        self.PopUp.Visible = false
    end)

    self.InputFrame.Plus1.Activated:Connect(function()
        self:UpdateTextBox((tonumber(self.TextBox.Text) or 0) + 1)
    end)

    self.InputFrame.Plus5.Activated:Connect(function()
        self:UpdateTextBox((tonumber(self.TextBox.Text) or 0) + 5)
    end)

    self.InputFrame.Max.Activated:Connect(function()
        if self.SelectedItem then
            self:UpdateTextBox(getQuantity(self.SelectedItem.Quantity))
        end
    end)

    self.InputFrame.Minus1.Activated:Connect(function()
        self:UpdateTextBox((tonumber(self.TextBox.Text) or 0) - 1)
    end)

    self.InputFrame.Minus5.Activated:Connect(function()
        self:UpdateTextBox((tonumber(self.TextBox.Text) or 0) - 5)
    end)

    self.InputFrame.Min.Activated:Connect(function()
        self:UpdateTextBox(1)
    end)

    self.TextBox:GetPropertyChangedSignal("Text"):Connect(function()
        local newText = string.gsub(self.TextBox.Text, "%D", "")
        local maxQuantity = self.SelectedItem and getQuantity(self.SelectedItem.Quantity) or 1
        
        if newText == "" then newText = "1" end
        self.TextBox.Text = tostring(math.clamp(tonumber(newText) or 1, 1, maxQuantity))
    end)

    self.PopUpSelectButton.Activated:Connect(function()
        self.PopUp.Visible = false
        
        local addAmount = tonumber(self.TextBox.Text) or 1
        if not self.SelectedItem then 
            return 
        end
        
        local currentQuantity = getQuantity(self.SelectedItem.Quantity)
        
        local newItem
        local alreadySelectedQuantity = nil
        local existingItem = self.SelectedItemsScroll:FindFirstChild(self.SelectedItem.Name)
        
        if existingItem then
            newItem = existingItem
            alreadySelectedQuantity = getQuantity(newItem.Quantity)
        else
            newItem = self.SelectedItem:Clone()
            newItem.Quantity.Text = "x0"
            newItem.Parent = self.SelectedItemsScroll
            self:InSelectedCon(newItem)
        end
        
        if not self.SelectedItem.Quantity.Visible or currentQuantity - addAmount <= 0 then
            self.SelectedItem:Destroy()
            currentQuantity = 1
        elseif currentQuantity > 1 then
            self.SelectedItem.Quantity.Text = "x" .. tostring(currentQuantity - addAmount)
            if currentQuantity - addAmount == 1 then
                self.SelectedItem.Quantity.Visible = false
            end
        end
        
        if alreadySelectedQuantity then
            newItem.Quantity.Text = "x" .. tostring(alreadySelectedQuantity + addAmount)
            newItem.Quantity.Visible = true
        else
            newItem.Quantity.Text = "x" .. tostring(addAmount)
            if addAmount == 1 then
                newItem.Quantity.Visible = false
            else
                newItem.Quantity.Visible = true
            end
        end
    end)

    self.AcceptButton.Activated:Connect(function()
        local itemsToSell = {}
        for _, item in ipairs(self.SelectedItemsScroll:GetChildren()) do
            if item:IsA("ImageButton") and item.Visible then
                itemsToSell[item.Name] = getQuantity(item.Quantity)
            end
        end
        
        self.SellItemsEvent:FireServer(itemsToSell)
        self.CloseRequested:Fire()
    end)

    self.SelectAllButton.Activated:Connect(function()
        for _, item in ipairs(self.PersonalStashScroll:GetChildren()) do
            if not item:IsA("ImageButton") or not item.Visible then continue end

            local itemInSelectedScroll = self.SelectedItemsScroll:FindFirstChild(item.Name)
            
            if itemInSelectedScroll then
                local quantityInStash = getQuantity(item.Quantity)
                local quantityInSelected = getQuantity(itemInSelectedScroll.Quantity)
                
                itemInSelectedScroll.Quantity.Text = "x" .. tostring(quantityInStash + quantityInSelected)
                itemInSelectedScroll.Quantity.Visible = true
                item:Destroy()
            else
                item.Parent = self.SelectedItemsScroll
                self:InSelectedCon(item)
            end
        end
    end)
end

return SellingMenu