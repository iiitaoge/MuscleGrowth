local rawPets = {
	{ Id = "Pet1_1", Name = "Magical Blocks", Rarity = "Common", Boost = 1.1, Model = "Magical Blocks", Image = "rbxassetid://71888395631331" },
	{ Id = "Pet1_2", Name = "Heaven Blocks", Rarity = "Rare", Boost = 1.2, Model = "Heaven Blocks", Image = "rbxassetid://113764562813427" },
	{ Id = "Pet1_3", Name = "Jailer Block", Rarity = "Epic", Boost = 1.3, Model = "Jailer Block", Image = "rbxassetid://91684084888727" },
	{ Id = "Pet1_4", Name = "Gabriel", Rarity = "Legendary", Boost = 1.5, Model = "Gabriel", Image = "rbxassetid://139625950878842" },
	{ Id = "Pet1_5", Name = "Masked King", Rarity = "Secret", Boost = 2, Model = "Masked King", Image = "rbxassetid://132840812922130" },
	{ Id = "Pet2_1", Name = "King of the Night", Rarity = "Common", Boost = 1.5, Model = "King of the Night", Image = "rbxassetid://109187198132316" },
	{ Id = "Pet2_2", Name = "Holy Sword King", Rarity = "Rare", Boost = 2, Model = "Holy Sword King", Image = "rbxassetid://79047832599742" },
	{ Id = "Pet2_3", Name = "Petrified King", Rarity = "Epic", Boost = 2.5, Model = "Petrified King", Image = "rbxassetid://139782463157652" },
	{ Id = "Pet2_4", Name = "Kirby Knight", Rarity = "Legendary", Boost = 2.8, Model = "Kirby Knight", Image = "rbxassetid://87635564895722" },
	{ Id = "Pet2_5", Name = "Sun incarnation", Rarity = "Secret", Boost = 4, Model = "Sun incarnation", Image = "rbxassetid://80876869690210" },
	{ Id = "Pet3_1", Name = "Luna", Rarity = "Common", Boost = 2.5, Model = "Luna", Image = "rbxassetid://82314461161999" },
	{ Id = "Pet3_2", Name = "Frenzy Day", Rarity = "Rare", Boost = 3.1, Model = "Frenzy Day", Image = "rbxassetid://71264429232812" },
	{ Id = "Pet3_3", Name = "Ice Emperor", Rarity = "Epic", Boost = 4, Model = "Ice Emperor", Image = "rbxassetid://112149143708961" },
	{ Id = "Pet3_4", Name = "Psychedelic Dream", Rarity = "Legendary", Boost = 5, Model = "Psychedelic Dream", Image = "rbxassetid://77979746124001" },
	{ Id = "Pet3_5", Name = "Pale Shadow", Rarity = "Secret", Boost = 8, Model = "Pale Shadow", Image = "rbxassetid://136721805278818" },
	{ Id = "Pet4_1", Name = "Dark Night", Rarity = "Common", Boost = 4, Model = "Dark Night", Image = "rbxassetid://137429259368506" },
	{ Id = "Pet4_2", Name = "Fake Mask", Rarity = "Rare", Boost = 5, Model = "Fake Mask", Image = "rbxassetid://103689525802666" },
	{ Id = "Pet4_3", Name = "Prism", Rarity = "Epic", Boost = 7, Model = "Prism", Image = "rbxassetid://105013482634239" },
	{ Id = "Pet4_4", Name = "Angry Twin Tails", Rarity = "Legendary", Boost = 9, Model = "Angry Twin Tails", Image = "rbxassetid://82990811635362" },
	{ Id = "Pet4_5", Name = "Enchanting Twin Ponytails", Rarity = "Secret", Boost = 15, Model = "Enchanting Twin Ponytails", Image = "rbxassetid://100499286248082" },
	{ Id = "Event_1", Name = "Green Princess", Rarity = "Secret", Boost = 15, Model = "Green Princess", Image = "rbxassetid://85383340055752" },
	{ Id = "PEgg1_1", Name = "Cold aloof empress", Rarity = "Secret", Boost = 25, Model = "Cold aloof empress", Image = "rbxassetid://89991710252326" },
	{ Id = "PEgg1_2", Name = "Space Raiders", Rarity = "Secret", Boost = 50, Model = "Space Raiders", Image = "rbxassetid://78222696226297" },
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
