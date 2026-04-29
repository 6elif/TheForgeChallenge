local Players = game:GetService("Players")

local dataHandler = require(game:GetService("ServerScriptService").Data.DataHandler)

local luckNum = script:WaitForChild("Luck")

local function changeLuck(player, newLuck)
	dataHandler.playerProfiles[player].Luck	= newLuck
end

while luckNum do
	for _, player in ipairs(Players:GetPlayers()) do
		changeLuck(player, luckNum.Value)
	end
	task.wait(0.1)
end