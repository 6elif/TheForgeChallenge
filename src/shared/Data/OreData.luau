local RarityColors = {
	Common = Color3.new(0.784, 0.784, 0.784),   
	Uncommon = Color3.new(0.333, 1, 0.333),       
	Rare = Color3.new(0.333, 0.667, 1),         
	Epic = Color3.new(0.667, 0.333, 1),       
}

local oreData = {
	Stone = {
		Chance = 1,
		Rarity = "Common",
		DropsFrom = {"Pebble"},
		Multiplier = 0.2,
		Price = 3,
		Description = "It's a rock. What more do you want?",
	},
	["Sand Stone"] = {
		Chance = 2,
		Rarity = "Common",
		DropsFrom = {"Pebble", "Rock"},
		Multiplier = 0.25,
		Price = 3.75,
		Description = "Crumbly yet sturdy enough to build with. Not great in water.",
	},
	Copper = {
		Chance = 3,
		Rarity = "Common",
		DropsFrom = {"Pebble", "Rock", "Boulder"},
		Multiplier = 0.3,
		Price = 4.5,
		Description = "Basic but dependable. A beginner's best friend in the forge.",
	},
	Iron = {
		Chance = 5,
		Rarity = "Common",
		DropsFrom = {"Pebble", "Rock", "Boulder"},
		Multiplier = 0.35,
		Price = 5.25,
		Description = "The workhorse of the forge. Reliable, versatile, and a classic choice.",
	},
	Tin = {
		Chance = 7,
		Rarity = "Uncommon",
		DropsFrom = {"Rock", "Boulder"},
		Multiplier = 0.425,
		Price = 6.38,
		Description = "Weak on its own, but blends beautifully with others.",
	},
	Silver = {
		Chance = 12,
		Rarity = "Uncommon",
		DropsFrom = {"Rock", "Boulder"},
		Multiplier = 0.5,
		Price = 7.5,
		Description = "Malleable and pure. Naturally anti-curse, anti-werewolf, anti-everything-bad.",
	},
	Gold = {
		Chance = 16,
		Rarity = "Uncommon",
		DropsFrom = {"Boulder"},
		Multiplier = 0.65,
		Price = 19.5,
		Description = "Not the strongest, but hey- it's gold. Fancy never goes out of style.",
	},
	Mushroomite = {
		Chance = 22,
		Rarity = "Rare",
		DropsFrom = {"Rock", "Boulder"},
		Multiplier = 0.8,
		Price = 12,
		Description = "Grows in damp places. Sometimes glows. Sometimes talks. Probably fine.",
	},
	Platinum = {
		Chance = 28,
		Rarity = "Rare",
		DropsFrom = {"Boulder"},
		Multiplier = 0.8,
		Price = 12,
		Description = "Smooth, silvery, and highly conductive. Rare and sought-after.",
	},
	Bananite = {
		Chance = 30,
		Rarity = "Uncommon",
		DropsFrom = {"Rock", "Boulder"},
		Multiplier = 0.85,
		Price = 12.75,
		Description = "Yellow, slippery, looks and smells like a banana and surprisingly durable. Smells weird when heated though.",
	},
	Cardboardite = {
		Chance = 30,
		Rarity = "Common",
		DropsFrom = {"Rock", "Boulder"},
		Multiplier = 0.7,
		Price = 10.5,
		Description = "Looks like trash, feels like trash... but somehow incredibly useful.",
	},
	Aite = {
		Chance = 44,
		Rarity = "Epic",
		DropsFrom = {"Boulder"},
		Multiplier = 1.1,
		Price = 16.5,
		Description = "It's a ore made out of A's - but that's actually lightweight and razor sharp.",
	},
	Poopite = {
		Chance = 131,
		Rarity = "Epic",
		DropsFrom = {"Pebble", "Rock", "Boulder"},
		Multiplier = 1.2,
		Price = 18,
		Description = "Ew. Why is this even mineable? Smells awful, but apparently makes great fertilizer-fused armor.",
	},
}

local function GetOreData(oreName)
	local ore = oreData[oreName]
	if not ore then return nil end
	
	return ore, RarityColors[ore.Rarity]
end


return {
	Data = oreData, 
	GetOreData = GetOreData,
	RarityColors = RarityColors
}
