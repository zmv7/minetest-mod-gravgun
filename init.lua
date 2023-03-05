local grabbing = {}
local range = {}

local special_nodes = { --to prevent duping. Use RegExp.
	"itemframe",
}

local function is_sneak(player)
	local ctrl = player and player:get_player_control()
	if ctrl and ctrl.sneak then
		return true
	else
		return false
	end
end

local function freeze(itemstack, player, pointed_thing)
	local name = player and player:get_player_name()
	if not name then return end
	local sneak = is_sneak(player)
	if sneak then
		return
	end
	grabbing[name] = nil
	range[name] = nil
end

core.register_globalstep(function(dtime)
	for _,player in ipairs(core.get_connected_players()) do
		local witem = player and player:get_wielded_item()
		local name = player and player:get_player_name()
		if name and witem then
			if witem:get_name() == "gravgun:gravgun" then
				if grabbing[name] then
					range[name] = range[name] or 4
					local sneak = is_sneak(player)
					if sneak then
						local ctrl = player:get_player_control()
						if ctrl and ctrl.dig then
							range[name] = range[name] + 0.1
						end
						if ctrl and ctrl.place then
							range[name] = range[name] - 0.1
						end
					end
					local obj = grabbing[name]
					local ppos = player:get_pos()
					local props = player:get_properties()
					ppos.y = ppos.y + props.eye_height
					local dir = player:get_look_dir()
					local opos = {x=ppos.x + range[name]*dir.x,y=ppos.y + range[name]*dir.y,z=ppos.z + range[name]*dir.z}
					obj:move_to(opos, true)
					obj:set_physics_override({gravity=0})
					obj:set_acceleration({x=0,y=0,z=0})
					obj:set_velocity({x=0,y=0,z=0})
				end
			else
				if grabbing[name] then
					local obj = grabbing[name]
					obj:set_physics_override({gravity=1})
					obj:set_acceleration({x=0,y=-10,z=0})
					grabbing[name] = nil
					range[name] = nil
				end
			end
		end
	end
end)

core.register_tool("gravgun:gravgun",{
  description = "Gravity Gun",
  inventory_image = "gravgun.png",
  on_use = function(itemstack, player, pointed_thing)
	local name = player and player:get_player_name()
	if not (name and pointed_thing) then return end
	local sneak = is_sneak(player)
	if sneak then
		return
	end
	if grabbing[name] then
		local obj = grabbing[name]
		obj:set_physics_override({gravity=1})
		obj:set_acceleration({x=0,y=-10,z=0})
		local ctrl = player and player:get_player_control()
		if ctrl and ctrl.aux1 then
			local dir = player:get_look_dir()
			obj:add_velocity({x=dir.x*30,y=dir.y*30,z=dir.z*30})
		end
		grabbing[name] = nil
		range[name] = nil
		return
	end
	if pointed_thing.type == "object" then
		local obj = pointed_thing.ref
		if obj:is_player() then
			if not core.check_player_privs(name,{gravgun_op=true}) then
				return
			end
		end
		grabbing[name] = obj
	end
	if pointed_thing.type == "node" then
		local pos = pointed_thing.under
		if core.is_protected(pos,name) then return end
		local node = core.get_node(pos)
		for i,nname in ipairs(special_nodes) do
			if node.name:match(nname) and not core.check_player_privs(name,{gravgun_op=true}) then
				core.chat_send_player(name, "You're not allowed to grab this!")
				return itemstack
			end
		end
		local fnode = core.spawn_falling_node(pos)
		if fnode then
			local objs = core.get_objects_inside_radius(pos, 0)
			if objs then
				for _,obj in ipairs(objs) do
					local entity = obj and obj:get_luaentity()
					if entity and entity.name == "__builtin:falling_node" then
						entity.owner = name
						grabbing[name] = obj
					end
				end
			end
		end
	end
  end,
  on_place = freeze,
  on_secondary_use = freeze
})

core.register_privilege("gravgun_op",{description="Allows to grab players and special nodes with gravgun",give_to_singleplayer=false})
