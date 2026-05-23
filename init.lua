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

ModLuaFileAppend("data/scripts/perks/perk_list.lua", "mods/evaisa.drone/files/perks.lua")
ModLuaFileAppend("data/scripts/gun/gun.lua", "mods/evaisa.drone/files/gun_hook.lua")

local translations = ModTextFileGetContent("data/translations/common.csv")
local new_translations = ModTextFileGetContent("mods/evaisa.drone/translations.csv")
translations = translations .. "\n" .. new_translations .. "\n"
translations = translations:gsub("\r", ""):gsub("\n\n+", "\n")
ModTextFileSetContent("data/translations/common.csv", translations)

function OnPlayerSpawned(player)
	local x, y = EntityGetTransform(player)
	EntityLoad("mods/evaisa.drone/mina_spawn_entity.xml", x+2, y+3 )
end

function OnMagicNumbersAndWorldSeedInitialized()
	if(ModIsEnabled("evaisa.arena"))then
		local arena_client = ModTextFileGetContent("mods/evaisa.drone/files/arena_compat/client.xml")
		local arena_player = ModTextFileGetContent("mods/evaisa.drone/files/arena_compat/player_base.xml")
		
		ModTextFileSetContent("mods/evaisa.arena/files/entities/player_base.xml", arena_player)
		ModTextFileSetContent("mods/evaisa.arena/files/entities/client.xml", arena_client)

		local perk_fix = ModTextFileGetContent("mods/evaisa.arena/files/scripts/append/perk_fix.lua")

		perk_fix = perk_fix:gsub("LEVITATION_TRAIL", "FAKEPERK1")
		perk_fix = perk_fix:gsub("ATTACK_FOOT", "FAKEPERK2")
		
		ModTextFileSetContent("mods/evaisa.arena/fiels/scripts/append/perk_fix.lua", perk_fix)
	end
end