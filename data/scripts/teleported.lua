function teleported( from_x, from_y, to_x, to_y, portal_teleport )
	--local a = from_x - to_x
	--local b = from_y - to_y
	--local distance = math.sqrt(a * a + b * b)

	GlobalsSetValue("drone_player_teleported_x", tostring(to_x))
	GlobalsSetValue("drone_player_teleported_y", tostring(to_y))

end