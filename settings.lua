dofile("data/scripts/lib/mod_settings.lua") 

local mod_id = "evaisa.drone" -- This should match the name of your mod's folder.
mod_settings_version = 1 -- This is a magic global that can be used to migrate settings to new mod versions. call mod_settings_get_version() before mod_settings_update() to get the old value. 
mod_settings = 
{
	{
		category_id = "default_settings",
		ui_name = "",
		ui_description = "",
		settings = {
			{
				id = "manual_controls",
				ui_name = "Manual Controls",
				ui_description = "I drive this baby MANUAL.",
				value_default = false,
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "thrust_volume",
				ui_name = "Thrust Volume",
				ui_description = "Volume of the sound created by thrusting",
				value_default = 1.0,
				value_min = 0.0,
				value_max = 1.0,
				value_display_multiplier = 100,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},
			{
				id = "alarm_volume",
				ui_name = "Alarm Volume",
				ui_description = "Volume of upside down alarm sound",
				value_default = 1.0,
				value_min = 0.0,
				value_max = 1.0,
				value_display_multiplier = 100,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},			
			{
				id = "grind_volume",
				ui_name = "Grind Volume",
				ui_description = "Volume of propeller grinding sound",
				value_default = 1.0,
				value_min = 0.0,
				value_max = 1.0,
				value_display_multiplier = 100,
				value_display_formatting = " $0%",
				scope = MOD_SETTING_SCOPE_RUNTIME,
			},						
		},
	},
}

function ModSettingsUpdate( init_scope )
	local old_version = mod_settings_get_version( mod_id ) 
	mod_settings_update( mod_id, mod_settings, init_scope )
end

function ModSettingsGuiCount()
	return 1
end


function ModSettingsGui( gui, in_main_menu )
	mod_settings_gui( mod_id, mod_settings, gui, in_main_menu )

end

