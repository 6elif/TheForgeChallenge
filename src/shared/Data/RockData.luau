
local RepStorage = game:GetService("ReplicatedStorage")

local rocks = RepStorage.Assets.Models.Rocks

local rockData = {
	Pebble = {
		Health = 14,
		Exp = 5,
		MaxOreDropAmount = 1,
		RequiredPower = 3,
		ChanceToSpawn = 1,
		["Luck Boost"] = 0,
		Model = rocks.Pebble,
	},
	Rock = {
		Health = 45,
		Exp = 7.5,
		MaxOreDropAmount = 2,
		RequiredPower = 7,
		ChanceToSpawn = 3,
		["Luck Boost"] = 0.5,
		Model = rocks.Rock,
	},
	Boulder = {
		Health = 100,
		Exp = 10,
		MaxOreDropAmount = 3,
		RequiredPower = 13,
		ChanceToSpawn = 7,
		["Luck Boost"] = 1,
		Model = rocks.Boulder,
	},	
}

return rockData
