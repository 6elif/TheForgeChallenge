local RepStorage = game:GetService("ReplicatedStorage")

local addOresToFrame = require(RepStorage.Shared.Util.AddOresToFrame)

local sellItems = RepStorage.Assets.Network.Events.SellItems

local playerGui = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
local sellGui = playerGui.SellGui
local mainFrame = sellGui.MainFrame
local mainSellFrame = mainFrame.InnerFrame.MainSell
local mainContrainer = mainSellFrame.Container
local personalStashScroll = mainContrainer.PersonalStash.ScrollingFrame
local selectedItemsScroll = mainContrainer.SelectedItems.ScrollingFrame
local popUp = mainFrame.PopUp
local inputFrame = popUp.InnerFrame.Main.InputFrame

local closeButton = mainSellFrame.Title.Close
local acceptButton = mainFrame.InnerFrame.SelectionButtons.Accept.Button
local sellectAllButton = mainFrame.InnerFrame.SelectionButtons.Accept.SellectAllButton

local popUpSelectButton = popUp.InnerFrame.Main.Container.SelectButton
local textBox = inputFrame.TextBox
local closePopUpButton = popUp.InnerFrame.Main.Title.Close

local connections = {}
local selectedItem

local MAX_HOLD_TIME = 1

closeButton.Activated:Connect(function()
	mainFrame.Visible = false
end)

closePopUpButton.Activated:Connect(function()
	popUp.Visible = false
end)

inputFrame.Plus1.Activated:Connect(function()
	local amount = tonumber(textBox.Text)
	amount += 1
	textBox.Text = amount
end)

inputFrame.Plus5.Activated:Connect(function()
	local amount = tonumber(textBox.Text)
	amount += 5
	textBox.Text = amount
end)

inputFrame.Max.Activated:Connect(function()
	local amount = string.gsub(selectedItem.Quantity.Text, "%D", "")
	amount = tonumber(amount)
	textBox.Text = amount
end)

inputFrame.Minus1.Activated:Connect(function()
	local amount = tonumber(textBox.Text)
	amount -= 1
	textBox.Text = amount
end)

inputFrame.Minus5.Activated:Connect(function()
	local amount = tonumber(textBox.Text)
	amount -= 5
	textBox.Text = amount
end)

inputFrame.Min.Activated:Connect(function()
	textBox.Text = 1
end)

local function itemPressCon(oreButton)
	local tracker = {
		Pressed = nil,
		ParentChange = nil
	}
	tracker.Pressed = oreButton.MouseButton1Down:Connect(function()
		if oreButton.Parent == personalStashScroll then
			popUp.Visible = true
			popUp.InnerFrame.Main.Container.Text.Text = "How many of " .. oreButton.Name .. " do you want to select?"
			selectedItem = oreButton
			popUp.InnerFrame.Main.InputFrame.TextBox.Text = "1"
		end
	end)
	
	tracker.ParentChange = oreButton:GetPropertyChangedSignal("Parent"):Connect(function()
		if oreButton.Parent ~= personalStashScroll then
			tracker.Pressed:Disconnect()
			tracker.ParentChange:Disconnect()
			connections[oreButton] = nil
		end
	end)
	
	connections[oreButton] = tracker
end

local function inSelectedCon(newItem)
	
	local tracker = {
		HoldStartCon = nil,
		HoldEndCon = nil
	}
	
	local function cleanUp()
		tracker.HoldStartCon:Disconnect()
		tracker.HoldEndCon:Disconnect()
		connections[newItem] = nil
	end
	
	local function moveAll()
		local itemInStash = personalStashScroll:FindFirstChild(newItem.Name)
		local addQuantity
		if not newItem.Quantity.Visible then
			addQuantity = 1
		else
			local str = string.gsub(newItem.Quantity.Text, "%D", "")
			addQuantity = tonumber(str)
		end

		if not itemInStash then
			newItem.Parent = personalStashScroll
			cleanUp()
			itemPressCon(newItem)
			return
		else
			if not itemInStash.Quantity.Visible then
				itemInStash.Quantity.Visible = true
				itemInStash.Quantity.Text = "x"..(addQuantity + 1)
			else
				local strInStash = string.gsub(itemInStash.Quantity.Text, "%D", "")
				local inStashQuantity = tonumber(strInStash)
				itemInStash.Quantity.Text = "x".. (inStashQuantity + addQuantity)
			end
		end
		newItem:Destroy()
	end	
	
	local function moveOne()
		local itemInStash = personalStashScroll:FindFirstChild(newItem.Name)

		if not itemInStash then
			itemInStash = newItem:Clone()
			itemInStash.Parent = personalStashScroll
			itemInStash.Quantity.Text = "x".. 1
			itemInStash.Quantity.Visible = false
			itemPressCon(itemInStash)
		else
			local str = string.gsub(itemInStash.Quantity.Text, "%D", "")
			local itemInStashQuantity = tonumber(str)
			itemInStash.Quantity.Visible = true
			itemInStash.Quantity.Text = "x".. (itemInStashQuantity + 1)
		end
		
		local str = string.gsub(newItem.Quantity.Text, "%D", "")
		local itemInSelectQuantity = tonumber(str)
		
		if not newItem.Quantity.Visible then
			itemInSelectQuantity = 1
		end
		
		print(itemInSelectQuantity)
		
		if itemInSelectQuantity - 1 == 0 then
			cleanUp()
			newItem:Destroy()
		elseif itemInSelectQuantity - 1 == 1 then
			newItem.Quantity.Text = "x".. (1)
			newItem.Quantity.Visible = false
		else
			newItem.Quantity.Text = "x".. (itemInSelectQuantity - 1)
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
			
			if holdTime >= MAX_HOLD_TIME then
				holdingButton = false
				moveAll()
			end
		end
		if holdTime < MAX_HOLD_TIME then
			moveOne()
		end
	end)
	
	tracker.HoldEndCon = newItem.MouseButton1Up:Connect(function()
		holdingButton = false
	end)
	
	connections[newItem] = tracker
end

popUpSelectButton.Activated:Connect(function()
	popUp.Visible = false
	
	local amountInStr = popUp.InnerFrame.Main.InputFrame.TextBox.Text
	local addAmount = tonumber(amountInStr)
		
	-- Sanity check
	if not selectedItem then 
		warn("No item selected")
		return 
	end
	
	local currentItemQuantityStr = string.gsub(selectedItem.Quantity.Text, "%D", "")
	local currentQuantity = tonumber(currentItemQuantityStr)
	
	-- Puts the item into the selcetion frame or find it there already
	local newItem
	local alreadySelectedQuantity
	if selectedItemsScroll:FindFirstChild(selectedItem.Name) then
		newItem = selectedItemsScroll:FindFirstChild(selectedItem.Name)
		local alreadySelectedQuantityStr = string.gsub(newItem.Quantity.Text, "%D", "")
		alreadySelectedQuantity = tonumber(alreadySelectedQuantityStr)
	else
		newItem = selectedItem:Clone()
		newItem.Quantity.Text = "x".. 0
		newItem.Parent = selectedItemsScroll
		
		inSelectedCon(newItem)
	end
	
	-- if there's one or less left
	if not selectedItem.Quantity.Visible or currentQuantity - addAmount <= 0 then
		selectedItem:Destroy()
		currentQuantity = 1
	end
	
	if currentQuantity > 1 then
		selectedItem.Quantity.Text = "x"..(currentQuantity - addAmount)
		if currentQuantity - 1 == 1 then
			selectedItem.Quantity.Visible = false
		end
	end
	if alreadySelectedQuantity then
		newItem.Quantity.Text = "x"..(alreadySelectedQuantity + addAmount)
		newItem.Quantity.Visible = true
	else
		newItem.Quantity.Text = "x"..addAmount
		if addAmount == 1 then
			newItem.Quantity.Visible = false
		end
	end
		
end)

textBox:GetPropertyChangedSignal("Text"):Connect(function()
	local newText = string.gsub(textBox.Text, "%D", "")
	local quantity
	if selectedItem.Quantity.Visible then
		quantity = string.gsub(selectedItem.Quantity.Text, "%D", "")
		quantity = tonumber(quantity) or 1
	else
		quantity = 1
	end
	
	if newText == "" then
		newText = "1"
	end

	textBox.Text = math.clamp(tonumber(newText) or 1, 1, quantity)
end)



acceptButton.Activated:Connect(function()
	local itemsToSell = {}
	for _, item in ipairs(selectedItemsScroll:GetChildren()) do
		if not item:IsA("ImageButton") or not item.Visible then continue end
		
		local quantity
		if item.Quantity.Visible then
			quantity = string.gsub(item.Quantity.Text, "%D", "")
			quantity = tonumber(quantity) or 1
		else
			quantity = 1
		end
		itemsToSell[item.Name] = quantity
	end
	
	sellItems:FireServer(itemsToSell)
	mainFrame.Visible = false
end)

sellectAllButton.Activated:Connect(function()
	for _, item in ipairs(personalStashScroll:GetChildren()) do
		if not item:IsA("ImageButton") or not item.Visible then continue end

		local itemInSelectedScroll = selectedItemsScroll:FindFirstChild(item.Name)
		
		if itemInSelectedScroll then
			local quantityInStash = string.gsub(item.Quantity.Text, "%D", "")
			quantityInStash = tonumber(quantityInStash) or 1
			
			local quantityInSelected = string.gsub(itemInSelectedScroll.Quantity.Text, "%D", "")
			quantityInSelected = tonumber(quantityInSelected) or 1
			
			if not itemInSelectedScroll.Quantity.Visible then
				itemInSelectedScroll.Quantity.Text = "x"..(quantityInStash + 1)
				itemInSelectedScroll.Quantity.Visible = true
			else
				itemInSelectedScroll.Quantity.Text = "x"..(quantityInStash + quantityInSelected)
			end
			item:Destroy()
		else
			item.Parent = selectedItemsScroll
			inSelectedCon(item)
		end
	end
end)


local function loadInItems()
	local oreButtons = addOresToFrame.AddOres(personalStashScroll)
	
	for _, oreButton in ipairs(oreButtons) do
		itemPressCon(oreButton)
	end
end

local function cleanScrolls()
	for _, tracker in pairs(connections) do
		for _, con in pairs(tracker) do
			con:Disconnect()
		end
		connections[tracker] = nil
	end
	
	for _, item in ipairs(selectedItemsScroll:GetChildren()) do
		if not item:IsA("ImageButton") or not item.Visible then continue end
		
		item:Destroy()
	end
	
	for _, item in ipairs(personalStashScroll:GetChildren()) do
		if not item:IsA("ImageButton") or not item.Visible then continue end

		item:Destroy()
	end
end

mainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if mainFrame.Visible then
		loadInItems()
	else
		cleanScrolls()
	end
end)


workspace:WaitForChild("IBuyStuff"):WaitForChild("Torso").ProximityPrompt.Triggered:Connect(function()
	mainFrame.Visible = true
end)