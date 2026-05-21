local olddraw_action = draw_action

draw_action = function(...)

	local old_recoil = shot_effects.recoil_knockback

	local success = olddraw_action(...)
	
	if(reloading or not success)then
		shot_effects.recoil_knockback = old_recoil
	end
	local ws = GameGetWorldStateEntity()
	if(shot_effects and ws ~= 0 and ws ~= nil)then

		GlobalsSetValue("drone_shot_recoil", tostring(shot_effects.recoil_knockback))
	end

	return success
end