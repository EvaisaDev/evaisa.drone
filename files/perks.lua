local REPLACEMENTS = {
	["FASTER_LEVITATION"] = {
		id = "MOTOR_UPGRADE",
		ui_name = "$perk_drone_motor_upgrade",
		ui_description = "$perk_drone_motor_upgrade_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/faster_levitation.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/faster_levitation.png",
		stackable = STACKABLE_YES,
		func = function( entity_perk_item, entity_who_picked, item_name )
			local thrust_mult = tonumber(GlobalsGetValue("drone_thrust_mult", "1"))
			thrust_mult = thrust_mult + 0.2
			GlobalsSetValue("drone_thrust_mult", tostring(thrust_mult))
		end,
		func_remove = function( entity_who_picked )
			GlobalsSetValue("drone_thrust_mult", "1")
		end,
	},
	["HOVER_BOOST"] = {
		id = "GYRO_UPGRADE",
		ui_name = "$perk_drone_gyro_upgrade",
		ui_description = "$perk_drone_gyro_upgrade_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/hover_boost.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/hover_boost.png",
		stackable = STACKABLE_YES,
		func = function( entity_perk_item, entity_who_picked, item_name )
			local stabilizer_mult = tonumber(GlobalsGetValue("drone_stabilizer_mult", "1"))
			stabilizer_mult = stabilizer_mult + 0.5
			GlobalsSetValue("drone_stabilizer_mult", tostring(stabilizer_mult))
		end,
		func_remove = function( entity_who_picked )
			GlobalsSetValue("drone_stabilizer_mult", "1")
		end,
	},
	["MOVEMENT_FASTER"] = {
		id = "ROBUST_CHASSIS",
		ui_name = "Robust Chassis",
		ui_description = "Your drone is less prone to impact damage!",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/movement_faster.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/movement_faster.png",
		stackable = STACKABLE_YES,
		func = function( entity_perk_item, entity_who_picked, item_name )
			local impact_mult = tonumber(GlobalsGetValue("drone_impact_mult", "1"))
			impact_mult = impact_mult * 0.1
			GlobalsSetValue("drone_impact_mult", tostring(impact_mult))
		end,
		func_remove = function( entity_who_picked )
			GlobalsSetValue("drone_impact_mult", "1")
		end,
	},
	["STRONG_KICK"] = {
		id = "HEAVY_WIND",
		ui_name = "$perk_drone_heavy_wind",
		ui_description = "$perk_drone_heavy_wind_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/strong_kick.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/strong_kick.png",
		stackable = STACKABLE_YES,
		func = function( entity_perk_item, entity_who_picked, item_name )
			local wind_mult = tonumber(GlobalsGetValue("drone_wind_mult", "0"))
			wind_mult = math.max(wind_mult + 0.5, 1)
			GlobalsSetValue("drone_wind_mult", tostring(wind_mult))
		end,
		func_remove = function( entity_who_picked )
			GlobalsSetValue("drone_wind_mult", "0")
		end,
	},
	["NO_MORE_KNOCKBACK"] = {
		id = "NO_MORE_KNOCKBACK_DRONE",
		ui_name = "$perk_no_more_knockback",
		ui_description = "$perk_drone_no_knockback_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/no_more_knockback.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/no_more_knockback.png",
		stackable = STACKABLE_NO,
		game_effect = "KNOCKBACK_IMMUNITY",
		func = function( entity_perk_item, entity_who_picked, item_name )
			GameAddFlagRun("drone_no_knockback")
		end,
		func_remove = function( entity_who_picked )
			GameRemoveFlagRun("drone_no_knockback")
		end,
	},
	["LEVITATION_TRAIL"] = {
		id = "MAGICAL_GUST",
		ui_name = "$perk_drone_magical_gust",
		ui_description = "$perk_drone_magical_gust_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/levitation_trail.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/levitation_trail.png",
		stackable = STACKABLE_YES,
		stackable_is_rare = true,
		max_in_perk_pool = 2,
		func = function( entity_perk_item, entity_who_picked, item_name )
			local levitation_trail_stacks = tonumber(GlobalsGetValue("drone_levitation_trail_stacks", "0"))
			levitation_trail_stacks = levitation_trail_stacks + 1
			GlobalsSetValue("drone_levitation_trail_stacks", tostring(levitation_trail_stacks))
		end,
		func_remove = function( entity_who_picked )
			GlobalsSetValue("drone_levitation_trail_stacks", "0")
		end,
	},
	["ANGRY_LEVITATION"] = {
		id = "ANGRY_STABILIZATION",
		ui_name = "$perk_drone_angry_stabilization",
		ui_description = "$perk_drone_angry_stabilization_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/angry_levitation.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/angry_levitation.png",
		stackable = STACKABLE_NO,
		func = function( entity_perk_item, entity_who_picked, item_name )
			
			EntityAddComponent( entity_who_picked, "LuaComponent", 
			{
				_tags = "perk_component",
				script_source_file = "data/scripts/perks/angry_levitation.lua",
				execute_every_n_frame = "20",
			} )
		end,
	},
}

local RENAMES = {
	["ATTACK_FOOT"] = {
		id = "MECHANICAL_LEGS",
		ui_name = "$perk_drone_mechanical_legs",
		description = "$perk_drone_mechanical_legs_desc",
		ui_icon = "mods/evaisa.drone/files/icons/perk_ui/attack_foot.png",
		perk_icon = "mods/evaisa.drone/files/icons/perk_world/attack_foot.png",
	},
	--[[TELEPORTITIS = 	{
		id = "TELEPORTITIS",
		ui_icon = "data/ui_gfx/perk_icons/teleportitis.png",
		perk_icon = "data/items_gfx/perks/teleportitis.png",
		stackable = STACKABLE_NO,
		usable_by_enemies = false,
		run_on_clients = false,
		func = function( entity_perk_item, entity_who_picked, item_name )
			GameAddFlagRun( "teleportitis" )
		end,
		func_remove = function( entity_who_picked )
			GameRemoveFlagRun( "teleportitis" )
		end,
	},]]
}

for i = 1, #perk_list do
	local entry = perk_list[i]
	if(REPLACEMENTS[entry.id or ""])then
		perk_list[i] = REPLACEMENTS[entry.id]
	end
	if(RENAMES[entry.id or ""])then
		for i2, v2 in pairs(RENAMES[entry.id])do
			perk_list[i][i2] = v2
		end
	end
end