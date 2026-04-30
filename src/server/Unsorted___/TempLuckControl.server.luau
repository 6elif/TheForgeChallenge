local Players = game:GetService("Players")

local dataHandler = require(game:GetService("ServerScriptService").Server.Unsorted___.Data.DataHandler)

local luckNum = game:GetService("ServerScriptService"):WaitForChild("Luck")

local function changeLuck(player, newLuck)
	dataHandler.playerProfiles[player].Luck	= newLuck
end

while luckNum do
	for _, player in ipairs(Players:GetPlayers()) do
		changeLuck(player, luckNum.Value)
	end
	task.wait(0.1)
end