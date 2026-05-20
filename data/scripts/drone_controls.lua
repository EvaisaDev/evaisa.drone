drone = drone or {
	angular_velocity = 0,
	contact_normals  = {},
	vx = nil,
	vy = nil,
}

DEBUG_DRAW = false

ARM_LENGTH = 6
ANGLE_THRUST = 0.95
THRUST = 30
GRAVITY = 15
ANGULAR_DAMPING = 0.99
UPRIGHT_STRENGTH = 5
IMPACT_DAMAGE_SCALE    = 0.0002
IMPACT_DAMAGE_MIN_VEL  = 10
CRUSH_DAMAGE_PER_TICK  = 0.01

local COLLIDER_POINTS = {
	{ 0,  -3 },
	{ -5, -1 },
	{  5, -1 },
	{ -3,  3 },
	{  3,  3 },
}

local EDGES = { {1,3}, {3,5}, {5,4}, {4,2}, {2,1} }

local function rotate_point(px, py, angle)
	local c, s = math.cos(angle), math.sin(angle)
	return px * c - py * s, px * s + py * c
end

local entity = GetUpdatedEntityID()
local controls_comp = EntityGetFirstComponentIncludingDisabled(entity, "ControlsComponent")
local jetpack_left = EntityGetFirstComponentIncludingDisabled(entity, "ParticleEmitterComponent", "thruster_left")
local jetpack_right = EntityGetFirstComponentIncludingDisabled(entity, "ParticleEmitterComponent", "thruster_right")
local sprite_comp = EntityGetFirstComponentIncludingDisabled(entity, "SpriteComponent", "player")

local audio_comps  = EntityGetComponentIncludingDisabled(entity,"AudioLoopComponent")

local fly_sound = nil
local alarm_sound = nil
local grind_sound = nil

for i, v in ipairs(audio_comps or {})do
	local event = ComponentGetValue2(v, "event_name")
	if(event == "drone/fly")then
		fly_sound = v
	elseif(event == "drone/alarm")then
		alarm_sound = v
	elseif(event == "drone/grind")then
		grind_sound = v		
	end
end

was_stunned = was_stunned or false
local is_stunned = false
for i, v in ipairs(EntityGetAllChildren(entity) or {})do
	local sprite_component = EntityGetFirstComponentIncludingDisabled(v, "SpriteComponent")
	if(sprite_component)then
		local image = ComponentGetValue2(sprite_component, "image_file")
		if(image == "data/particles/knockback_star_spinning.xml")then
			is_stunned = true
		end
	end
end


if(not was_stunned and is_stunned)then
	drone.angular_velocity = drone.angular_velocity + Random(-20, 20)
	was_stunned = true
elseif(not is_stunned)then
	was_stunned = false
end

if(not entity or not controls_comp or not jetpack_left or not jetpack_right)then
	return
end


local left = ComponentGetValue2(controls_comp, "mButtonDownLeft")
local right = ComponentGetValue2(controls_comp, "mButtonDownRight")
local up = ComponentGetValue2(controls_comp, "mButtonDownUp")
local down = ComponentGetValue2(controls_comp, "mButtonDownDown")

local vel_x = drone.vx or 0
local vel_y = drone.vy or 0

local thrust_left = 0
local thrust_right = 0
local delta = 1 / 60

local x, y, r = EntityGetTransform(entity)

recording = recording or false
recording_log = recording_log or {}
if InputIsKeyJustDown(16) then
	recording = not recording
	if recording then
		table.insert(recording_log, "=== RECORDING START frame=" .. GameGetFrameNum() .. " ===")
	else
		print(table.concat(recording_log, "\n"))
		recording_log = {}
	end
end

if(up and not down)then
	thrust_left = THRUST
	thrust_right = THRUST
end

if(left and not down)then
	thrust_left = thrust_left * ANGLE_THRUST
end
if(right and not down)then
	thrust_right = thrust_right * ANGLE_THRUST
end

local tilt = r - math.pi * 2 * math.floor(r / (math.pi * 2) + 0.5)

local any_contact = next(drone.contact_normals) ~= nil

if not any_contact and not down then
	if(not was_stunned)then
		local correction = tilt * UPRIGHT_STRENGTH / ARM_LENGTH
		if(up)then
			correction = correction * 0.5
		end
		thrust_left  = math.max(0, thrust_left  - correction * 0.5)
		thrust_right = math.max(0, thrust_right + correction * 0.5)
	end
	ComponentSetValue2(jetpack_left, "is_emitting", true)
	ComponentSetValue2(jetpack_right, "is_emitting", true)
else
	ComponentSetValue2(jetpack_left, "is_emitting", false)
	ComponentSetValue2(jetpack_right, "is_emitting", false)
end

local torque = (thrust_left - thrust_right) * ARM_LENGTH
drone.angular_velocity = drone.angular_velocity * ANGULAR_DAMPING + torque * delta

local new_r = r + drone.angular_velocity * delta

local up_x = math.sin(new_r)
local up_y = -math.cos(new_r)

local total_thrust = thrust_left + thrust_right

local frame_gravity = GRAVITY
if(up_y > 0 and not any_contact)then
	frame_gravity = frame_gravity + (60 * (up_y * up_y))
elseif(down)then
	frame_gravity = frame_gravity + 100
end

vel_x = vel_x + up_x * total_thrust * delta
vel_y = vel_y + up_y * total_thrust * delta + frame_gravity * delta

local new_x = x + vel_x * delta
local new_y = y + vel_y * delta

local WHITE = "mods/evaisa.drone/pixel_white.png"
local RED   = "mods/evaisa.drone/pixel_red.png"

local snap_x, snap_y = 0, 0
local new_contact_normals = {}
local log_contacts = {}

for ei, edge in ipairs(EDGES) do
	local prev_alx, prev_aly = rotate_point(COLLIDER_POINTS[edge[1]][1], COLLIDER_POINTS[edge[1]][2], r)
	local prev_blx, prev_bly = rotate_point(COLLIDER_POINTS[edge[2]][1], COLLIDER_POINTS[edge[2]][2], r)
	local cur_alx,  cur_aly  = rotate_point(COLLIDER_POINTS[edge[1]][1], COLLIDER_POINTS[edge[1]][2], new_r)
	local cur_blx,  cur_bly  = rotate_point(COLLIDER_POINTS[edge[2]][1], COLLIDER_POINTS[edge[2]][2], new_r)

	local prev_ax, prev_ay = x + prev_alx, y + prev_aly
	local prev_bx, prev_by = x + prev_blx, y + prev_bly
	local cur_ax,  cur_ay  = new_x + cur_alx, new_y + cur_aly
	local cur_bx,  cur_by  = new_x + cur_blx, new_y + cur_bly

	local cur_dx, cur_dy = cur_bx - cur_ax, cur_by - cur_ay
	local flen = math.sqrt(cur_dx * cur_dx + cur_dy * cur_dy)
	local fnx, fny = cur_dy / flen, -cur_dx / flen

	local steps    = math.ceil(flen)
	local face_hit = false
	local contact_cx = (cur_ax + cur_bx) * 0.5 - new_x
	local contact_cy = (cur_ay + cur_by) * 0.5 - new_y
	local best_pen = 0
	local contact_source = "none"

	for i = 0, steps do
		local t = i / math.max(steps, 1)

		local prev_px = prev_ax + (prev_bx - prev_ax) * t
		local prev_py = prev_ay + (prev_by - prev_ay) * t
		local cur_px  = cur_ax  + (cur_bx  - cur_ax)  * t
		local cur_py  = cur_ay  + (cur_by  - cur_ay)  * t

		if DEBUG_DRAW then
			GameCreateSpriteForXFrames(WHITE, prev_px, prev_py, true, 0, 0, 1, true)
			GameCreateSpriteForXFrames(WHITE, cur_px,  cur_py,  true, 0, 0, 1, true)
		end

		local move_x = cur_px - prev_px
		local move_y = cur_py - prev_py

		local move_len_sq = move_x * move_x + move_y * move_y
		if move_len_sq > 0.0001 then
			local hit, hx, hy = RaytracePlatforms(prev_px, prev_py, cur_px, cur_py)
			if hit then
				if DEBUG_DRAW then GameCreateSpriteForXFrames(RED, hx, hy, true, 0, 0, 1, true) end

				local pen = (cur_px - hx) * fnx + (cur_py - hy) * fny
				if pen > 0 then
					local cx = -fnx * pen
					local cy = -fny * pen
					if cx * cx + cy * cy > snap_x * snap_x + snap_y * snap_y then
						snap_x = cx
						snap_y = cy
					end
					if pen > best_pen then
						best_pen = pen
						contact_cx = hx - new_x
						contact_cy = hy - new_y
						contact_source = "ray"
					end
				end

				face_hit = true
			end
		end
	end

	if not face_hit then
		local sum_cx, sum_cy, count = 0, 0, 0
		for pi = 0, steps do
			local pt = pi / math.max(steps, 1)
			local px = cur_ax + (cur_bx - cur_ax) * pt
			local py = cur_ay + (cur_by - cur_ay) * pt
			local phit, phx, phy = RaytracePlatforms(px - fnx, py - fny, px + fnx * 2, py + fny * 2)
			if phit then
				local d = (phx - px) * fnx + (phy - py) * fny
				if d < 1.5 then
					sum_cx = sum_cx + phx
					sum_cy = sum_cy + phy
					count = count + 1
					if d < 0.1 then
						local pen = 0.1 - d
						local cx = -fnx * pen
						local cy = -fny * pen
						if cx * cx + cy * cy > snap_x * snap_x + snap_y * snap_y then
							snap_x = cx
							snap_y = cy
						end
					end
					face_hit = true
				end
			end
		end
		if count > 0 then
			contact_cx = sum_cx / count - new_x
			contact_cy = sum_cy / count - new_y
			contact_source = "sweep"
		end
	end

	local cnx, cny = fnx, fny
	if face_hit then
		local found, nx, ny = GetSurfaceNormal(new_x + contact_cx, new_y + contact_cy, 4, 6)
		if found then cnx, cny = nx, ny end
	end

	local vel_dot_n = vel_x * cnx + vel_y * cny
	local r_cross_n = contact_cx * cny - contact_cy * cnx

	if face_hit then
		new_contact_normals[ei] = true
	end

	if (ei == 1 or ei == 5) then
		local v_n_impact = vel_dot_n + drone.angular_velocity * r_cross_n
		if face_hit and v_n_impact > IMPACT_DAMAGE_MIN_VEL then
			local damage = v_n_impact * v_n_impact * IMPACT_DAMAGE_SCALE
			EntityInflictDamage(entity, damage, "DAMAGE_PHYSICS_BODY_DAMAGED", "Impact", "DISINTEGRATED", 0, 0, entity, new_x, new_y)
		end
		if (face_hit or drone.contact_normals[ei]) and total_thrust > 0 then
			EntityInflictDamage(entity, CRUSH_DAMAGE_PER_TICK, "DAMAGE_PHYSICS_BODY_DAMAGED", "Impact", "DISINTEGRATED", 0, 0, entity, new_x, new_y)
		end
	end

	if face_hit or drone.contact_normals[ei] then
		local v_n = vel_dot_n + drone.angular_velocity * r_cross_n
		local J = 0
		if v_n > 0 then
			if v_n > 1.0 then
				J = -v_n / (1 + r_cross_n * r_cross_n)
				drone.angular_velocity = drone.angular_velocity + J * r_cross_n
			else
				J = -vel_dot_n
			end
			vel_x = vel_x + J * cnx
			vel_y = vel_y + J * cny
			if recording then
				table.insert(log_contacts, string.format("  edge%d[%s]: fn=(%.2f,%.2f) cn=(%.2f,%.2f) rcn=%.2f vn=%.3f J=%.3f contact=(%.2f,%.2f)", ei, contact_source, fnx, fny, cnx, cny, r_cross_n, v_n, J, contact_cx, contact_cy))
			end
		end

		if cny > 0.5 then
			local tx, ty = -cny, cnx
			local v_t = vel_x * tx + vel_y * ty
			local normal_est = math.max(math.abs(J), GRAVITY * cny * delta)
			local friction_limit = 1.5 * normal_est
			local J_fric = math.max(-friction_limit, math.min(friction_limit, -v_t))
			vel_x = vel_x + J_fric * tx
			vel_y = vel_y + J_fric * ty
		end
	end
end

if next(new_contact_normals) ~= nil then
	drone.angular_velocity = drone.angular_velocity * 0.88
end

drone.contact_normals = new_contact_normals

new_x = new_x + snap_x
new_y = new_y + snap_y
EntitySetTransform(entity, new_x, new_y, new_r)

drone.vx = vel_x
drone.vy = vel_y

if recording then
	local upright_active = not any_contact and not down and not was_stunned
	table.insert(recording_log, string.format("[%d] pos=(%.2f,%.2f) rot=%.3f tilt=%.3f | vel=(%.2f,%.2f) omega=%.4f | snap=(%.3f,%.3f) | thrust=(%.2f,%.2f) | any_contact=%s upright=%s",
		GameGetFrameNum(), new_x, new_y, new_r, tilt, vel_x, vel_y, drone.angular_velocity, snap_x, snap_y, thrust_left, thrust_right, tostring(any_contact), tostring(upright_active)))
	for _, s in ipairs(log_contacts) do
		table.insert(recording_log, s)
	end
end

local velocity_mult_left = math.max(0.5, thrust_left / 20)
local velocity_mult_right = math.max(0.5, thrust_right / 20)

local last_animation = ComponentGetValue2(sprite_comp, "rect_animation")

local function switch_animation(comp, _, animation)
	if(last_animation ~= animation)then
		ComponentSetValue2(comp, "rect_animation", animation)
		--EntityRefreshSprite(entity, sprite_comp)
	end
end
local left_thrust = 0
local right_thrust = 0

if(thrust_left < thrust_right)then
	ComponentSetValue2(jetpack_left, "y_vel_min", math.floor(10 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "y_vel_max", math.floor(40 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_min", math.floor(1 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_max", math.floor(2 * velocity_mult_left))

	ComponentSetValue2(jetpack_right, "y_vel_min", math.floor(40 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "y_vel_max", math.floor(100 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_min", math.floor(3 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_max", math.floor(7 * velocity_mult_right))	

	switch_animation(sprite_comp, "rect_animation", "thrust_right")

	left_thrust = 0.4 * velocity_mult_left
	right_thrust = 1 * velocity_mult_right



elseif(thrust_right < thrust_left)then



	ComponentSetValue2(jetpack_left, "y_vel_min", math.floor(40 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "y_vel_max", math.floor(100 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_min", math.floor(3 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_max", math.floor(7 * velocity_mult_left))

	ComponentSetValue2(jetpack_right, "y_vel_min", math.floor(10 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "y_vel_max", math.floor(40 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_min", math.floor(1 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_max", math.floor(2 * velocity_mult_right))

	switch_animation(sprite_comp, "rect_animation", "thrust_left")

	left_thrust = 1 * velocity_mult_left
	right_thrust = 0.4 * velocity_mult_right

elseif(thrust_left == 0 and thrust_right == 0 and not any_contact and not down)then
	ComponentSetValue2(jetpack_left, "y_vel_min", math.floor(2 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "y_vel_max", math.floor(10 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_min", math.floor(1 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_max", math.floor(2 * velocity_mult_left))

	ComponentSetValue2(jetpack_right, "y_vel_min", math.floor(2 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "y_vel_max", math.floor(10 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_min", math.floor(1 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_max", math.floor(2 * velocity_mult_right))	


	left_thrust = 0.2* velocity_mult_left
	right_thrust = 0.2 * velocity_mult_right

	switch_animation(sprite_comp, "rect_animation",  "idle")
elseif(thrust_left == 0 and thrust_right == 0 and (any_contact or down))then
	switch_animation(sprite_comp, "rect_animation",  "off")
else
	ComponentSetValue2(jetpack_left, "y_vel_min", math.floor(40 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "y_vel_max", math.floor(100 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_min", math.floor(3 * velocity_mult_left))
	ComponentSetValue2(jetpack_left, "count_max", math.floor(7 * velocity_mult_left))

	ComponentSetValue2(jetpack_right, "y_vel_min", math.floor(40 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "y_vel_max", math.floor(100 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_min", math.floor(3 * velocity_mult_right))
	ComponentSetValue2(jetpack_right, "count_max", math.floor(7 * velocity_mult_right))	

	switch_animation(sprite_comp, "rect_animation",  "thrust_both")

	left_thrust = 1 * velocity_mult_left
	right_thrust = 1 * velocity_mult_right
end

fly_sound_initialized = fly_sound_initialized or false

if(fly_sound)then
	if(not fly_sound_initialized)then
		ComponentSetValue2(fly_sound, "m_volume", 0.001)
		fly_sound_initialized = true
	end
	local current_fly_volume = ComponentGetValue2(fly_sound, "m_volume")
	local fly_volume_lerp = 0.01
	local volume_target = 0

	local average_vol = (math.min(1.0, ((thrust_left + thrust_right) / 2) / 20)) * 0.4

	if(thrust_left > 0 or thrust_right > 0)then
		--EntitySetComponentIsEnabled(entity, fly_sound, true)
		if(average_vol < 0.2)then
			volume_target = 0.2
		else
			volume_target = average_vol
		end
	else
		--EntitySetComponentIsEnabled(entity, fly_sound, false)
		if(any_contact or down)then
			volume_target = 0.001
		else
			volume_target = 0.2
		end
	end
	if(current_fly_volume < volume_target)then
		current_fly_volume = current_fly_volume + fly_volume_lerp
	else
		current_fly_volume = current_fly_volume - fly_volume_lerp
	end


	ComponentSetValue2(fly_sound, "m_volume", math.max(math.min(current_fly_volume, 1), 0.001))
end

last_alarm = last_alarm or -100

initialized = initialized or false


if(alarm_sound)then
	if(not initialized)then
		ComponentSetValue2(alarm_sound, "m_volume", 0.001)
		initialized = true
	end
	local current_alarm_volume = ComponentGetValue2(alarm_sound, "m_volume")
	local alarm_volume_lerp = 0.1
	local alarm_sustain = 150
	volume_target3 = volume_target3 or 0.001

	if(up_y > 0 and volume_target3 ~= 0.8)then
		volume_target3 = 0.8
		last_alarm = GameGetFrameNum()

	elseif(up_y <= 0 and GameGetFrameNum() > last_alarm + alarm_sustain and volume_target3 ~= 0.001)then
		volume_target3 = 0.001
	end


	if(current_alarm_volume < volume_target3)then
		current_alarm_volume = current_alarm_volume + alarm_volume_lerp
	else
		current_alarm_volume = current_alarm_volume - alarm_volume_lerp
	end

	ComponentSetValue2(alarm_sound, "m_volume", math.max(math.min(current_alarm_volume, 1), 0.001))
end



local right_dir_x = up_y
local right_dir_y = -up_x

local left_arm_x = new_x - right_dir_x * 10
local left_arm_y = new_y - right_dir_y * 10
local right_arm_x = new_x + right_dir_x * 10
local right_arm_y = new_y + right_dir_y * 10

local hit_left_propeller = RaytraceSurfaces(left_arm_x, left_arm_y, left_arm_x + (up_x * 4), left_arm_y + (up_y * 4))
local hit_right_propeller = RaytraceSurfaces(right_arm_x, right_arm_y, right_arm_x + (up_x * 4), right_arm_y + (up_y * 4))

if(DEBUG_DRAW)then
	GameCreateSpriteForXFrames(WHITE, left_arm_x, left_arm_y, true, 0, 0, 1, true)
	GameCreateSpriteForXFrames(WHITE, right_arm_x, right_arm_y, true, 0, 0, 1, true)
end

last_grind = last_grind or -100
initialized2 = initialized2 or false
if grind_sound and not initialized2 then
	ComponentSetValue2(grind_sound, "m_volume", 0.001)
	initialized2 = true
end

local air_ray_steps = 10
for i = 0, air_ray_steps do
	if(thrust_left == 0 and thrust_right == 0)then
		return
	end
	local t = i / air_ray_steps
	local ray_x = left_arm_x + (right_arm_x - left_arm_x) * t
	local ray_y = left_arm_y + (right_arm_y - left_arm_y) * t

	-- mult is lerped from left_thrust to right_thrust as we go from left arm to right arm
	local mult = 0
	if thrust_left > 0 or thrust_right > 0 then
		mult = (1 - t) * left_thrust + t * right_thrust
		mult = math.max(mult, 0.01)
	end

	local proj = EntityLoad("mods/evaisa.drone/wind.xml", ray_x, ray_y)
	local projectile_comp = EntityGetFirstComponentIncludingDisabled(proj, "ProjectileComponent")
	if(projectile_comp)then
		ComponentSetValue2(projectile_comp, "lifetime", 10 * mult)
	end
	GameShootProjectile(entity, ray_x, ray_y, ray_x + (up_x * -50 * mult), ray_y + (up_y * -50 * mult), proj, true)

	local hit, hx, hy = RaytraceSurfacesAndLiquiform(ray_x, ray_y, ray_x + (up_x * -20), ray_y + (up_y * -20))

	if DEBUG_DRAW then
		GameCreateSpriteForXFrames(WHITE, ray_x + (up_x * -20), ray_y + (up_y * -20), true, 0, 0, 1, true)
		if hit then GameCreateSpriteForXFrames(RED, hx, hy, true, 0, 0, 1, true) end
	end

	if hit and not any_contact then
		local air = EntityLoad("mods/evaisa.drone/ground_air_particles.xml", hx, hy)

		local a = ray_x - hx
		local b = ray_y - hy
		local dist = math.max(0.01, math.sqrt(a * a + b * b))
		local mult = 1 / (1.05^dist)

		local particle_emitter = EntityGetFirstComponentIncludingDisabled(air, "ParticleEmitterComponent")

		if particle_emitter then
			ComponentSetValue2(particle_emitter, "x_vel_min", -40 * mult)
			ComponentSetValue2(particle_emitter, "x_vel_max", 40 * mult)
			ComponentSetValue2(particle_emitter, "y_vel_min", -20 * mult)
			ComponentSetValue2(particle_emitter, "y_vel_max", 5 * mult)
			ComponentSetValue2(particle_emitter, "count_min", 1 * mult)
			ComponentSetValue2(particle_emitter, "count_max", 4 * mult)
		end
	end
end

local hit_any_propeller = (hit_right_propeller and (thrust_right > 0)) or (hit_left_propeller and (thrust_left > 0))

if(grind_sound)then
	local current_grind_volume = ComponentGetValue2(grind_sound, "m_volume")
	local grind_volume_lerp = 0.04
	local grind_sustain = 30
	volume_target2 = volume_target2 or 0


	if(hit_any_propeller and volume_target2 ~= 0.4)then
		volume_target2 = 0.4
		last_grind = GameGetFrameNum()
	elseif(GameGetFrameNum() > last_grind + grind_sustain and volume_target2 ~= 0.001)then
		volume_target2 = 0.001
	end


	if(current_grind_volume < volume_target2)then
		current_grind_volume = current_grind_volume + grind_volume_lerp
	else
		current_grind_volume = current_grind_volume - grind_volume_lerp
	end

	ComponentSetValue2(grind_sound, "m_volume", math.max(math.min(current_grind_volume, 1), 0.001))
end



if(hit_left_propeller and thrust_left > 0)then
	local air = EntityLoad("mods/evaisa.drone/sparks.xml", left_arm_x, left_arm_y)

	EntitySetTransform(air, left_arm_x, left_arm_y, new_r)
end

if(hit_right_propeller and thrust_right > 0)then
	local air = EntityLoad("mods/evaisa.drone/sparks.xml", right_arm_x, right_arm_y)

	EntitySetTransform(air, right_arm_x, right_arm_y, new_r)
end