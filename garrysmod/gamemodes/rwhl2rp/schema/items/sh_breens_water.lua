--[[ 
	Rework � 2016-2017 TeslaCloud Studios
	Do not share or re-distribute before 
	the framework is publicly released.
--]]

local ITEM = Item("breens_water");

	ITEM.Name = "Breen's Water";
	ITEM.PrintName = "Breen's Water";
	ITEM.Description = "A blue can filled with water. It has 'Breen's Private Reserve' printed on it."
	ITEM.Model = "models/props_junk/popcan01a.mdl";
	ITEM.Weight = 0.35;
	ITEM.Stackable = true;
	ITEM.MaxStack = 8;
	ITEM.useText = "Drink";

	function ITEM:OnUse(player)
		print("Player just drank some breen's water. #brainwash");
	end;

ITEM:Register();