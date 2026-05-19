ModRegisterAudioEventMappings("mods/evaisa.drone/GUIDs.txt")

local get_player = function()
	local players = EntityGetWithTag("player_unit") or {}
	for i, v in ipairs(players)do
		return v
	end
	return nil
end

--[[
function OnWorldPreUpdate() 
	local player = get_player()

	if(player)then
		local char_data = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
		if(char_data == nil)then return end
		ComponentSetValue2(char_data, "is_on_ground", true)
	end
end

function OnWorldPostUpdate() 
	local player = get_player()

	if(player)then
		local char_data = EntityGetFirstComponentIncludingDisabled(player, "CharacterDataComponent")
		if(char_data == nil)then return end
		ComponentSetValue2(char_data, "is_on_ground", false)
	end
end
]]


function OnPlayerSpawned(player)
	local x, y = EntityGetTransform(player)
	EntityLoad("mods/evaisa.drone/mina_spawn_entity.xml", x+2, y+3 )
end