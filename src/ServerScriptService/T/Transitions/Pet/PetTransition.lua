local PetEquipTransition = require(script.Parent.PetEquipTransition)
local PetRollTransition = require(script.Parent.PetRollTransition)

local PetTransition = {}

PetTransition.RequestRoll = PetRollTransition.RequestRoll
PetTransition.RequestEquip = PetEquipTransition.RequestEquip
PetTransition.RequestUnequip = PetEquipTransition.RequestUnequip
PetTransition.IsPetInstanceEquipped = PetEquipTransition.IsPetInstanceEquipped

return PetTransition
