dofile_once("data/scripts/lib/utilities.lua")

function death( damage_type_bit_field, damage_message, entity_thats_responsible, drop_items )
	local entity_id    = GetUpdatedEntityID()
	local pos_x, pos_y = EntityGetTransform( entity_id )
	
	SetRandomSeed( GameGetFrameNum(), pos_x + pos_y + entity_id )
	
	local perk_flag = "PERK_PICKED_HOVER_BOOST"
	local pickup_count = tonumber( GlobalsGetValue( perk_flag .. "_PICKUP_COUNT", "0" ) ) + 1
	
	local player_id = 0
	
	local models = EntityGetComponent( entity_id, "VariableStorageComponent" )
	for i,v in ipairs( models ) do
		local name = ComponentGetValue2( v, "name" )
		if ( name == "angry_levitation" ) then
			player_id = ComponentGetValue2( v, "value_int" )
		end
	end
	
	if ( player_id ~= nil ) and ( player_id ~= NULL_ENTITY ) then
		local drone_limited_stabilizer_frames = tonumber(GlobalsGetValue("drone_limited_stabilizer_frames", "0"))
		drone_limited_stabilizer_frames = drone_limited_stabilizer_frames + 60
		GlobalsSetValue("drone_limited_stabilizer_frames", tostring(drone_limited_stabilizer_frames))
	end
end