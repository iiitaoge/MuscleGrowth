local PetEquipTransition = require(script.Parent.PetEquipTransition)
local PetDeleteTransition = require(script.Parent.PetDeleteTransition)
local PetRollTransition = require(script.Parent.PetRollTransition)

local PetTransition = {}

PetTransition.RequestRoll = PetRollTransition.RequestRoll
PetTransition.RequestEquip = PetEquipTransition.RequestEquip
PetTransition.RequestUnequip = PetEquipTransition.RequestUnequip
PetTransition.RequestDelete = PetDeleteTransition.RequestDelete
PetTransition.IsPetInstanceEquipped = PetEquipTransition.IsPetInstanceEquipped

return PetTransition
