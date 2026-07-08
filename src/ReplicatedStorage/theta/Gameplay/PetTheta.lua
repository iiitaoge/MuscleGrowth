local rawPets = {
	{ Id = "Pet1_1", Name = "Magical Blocks", Rarity = "Common", Boost = 1.1, Model = "Magical_Blocks", Image = "rbxassetid://71888395631331" },
	{ Id = "Pet1_2", Name = "Heaven Blocks", Rarity = "Rare", Boost = 1.2, Model = "Heaven_Blocks", Image = "rbxassetid://113764562813427" },
	{ Id = "Pet1_3", Name = "Jailer Block", Rarity = "Epic", Boost = 1.3, Model = "Jailer_Block", Image = "rbxassetid://91684084888727" },
	{ Id = "Pet1_4", Name = "Gabriel", Rarity = "Legendary", Boost = 1.5, Model = "Gabriel", Image = "rbxassetid://139625950878842" },
	{ Id = "Pet1_5", Name = "Masked King", Rarity = "Secret", Boost = 2, Model = "Masked_King", Image = "rbxassetid://132840812922130" },
	{ Id = "Pet2_1", Name = "King of the Night", Rarity = "Common", Boost = 1.5, Model = "King_of_the_Night", Image = "rbxassetid://109187198132316" },
	{ Id = "Pet2_2", Name = "Holy Sword King", Rarity = "Rare", Boost = 2, Model = "Holy_Sword_King", Image = "rbxassetid://79047832599742" },
	{ Id = "Pet2_3", Name = "Petrified King", Rarity = "Epic", Boost = 2.5, Model = "Petrified_King", Image = "rbxassetid://139782463157652" },
	{ Id = "Pet2_4", Name = "Kirby Knight", Rarity = "Legendary", Boost = 2.8, Model = "Kirby_Knight", Image = "rbxassetid://87635564895722" },
	{ Id = "Pet2_5", Name = "Sun incarnation", Rarity = "Secret", Boost = 4, Model = "Sun_incarnation", Image = "rbxassetid://80876869690210" },
	{ Id = "Event_1", Name = "Green Princess", Rarity = "Secret", Boost = 15, Model = "Green_Princess", Image = "rbxassetid://85383340055752" },
	{ Id = "PEgg1_1", Name = "Cold aloof empress", Rarity = "Secret", Boost = 25, Model = "Cold_aloof_empress", Image = "rbxassetid://89991710252326" },
	{ Id = "PEgg1_2", Name = "Space Raiders", Rarity = "Secret", Boost = 50, Model = "Space_Raiders", Image = "rbxassetid://78222696226297" },
}

local PetTheta = {}

for _, pet in ipairs(rawPets) do
	PetTheta[pet.Id] = {
		DisplayName = pet.Name,
		Rarity = pet.Rarity,
		Multiplier = pet.Boost,
		ModelName = pet.Model,
		Image = pet.Image,
	}
end

return PetTheta
