dofile("mods/evaisa.drone/files/teleportitis.lua")
last_teleportitis_trigger = last_teleportitis_trigger or 0

function damage_about_to_be_received( damage, x, y, entity_thats_responsible, critical_hit_chance )
    local entity_id = GetUpdatedEntityID()	
    if(GameHasFlagRun( "teleportitis" ) and damage > 0)then
        if(GameGetFrameNum() - last_teleportitis_trigger > 60)then
            damage = damage * 0.8
            trigger(entity_id)
            last_teleportitis_trigger = GameGetFrameNum()
        end
    end

	return damage, critical_hit_chance
end