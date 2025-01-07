local drifter_scarp_bar_list = {}
CompatibilityPatch = {}
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drifter_scarp_bar_list = {}
end)
SkillPickup.add_pre_local_drop_func(function(inst, skill)
    if skill.skill_id == 68 or skill.skill_id == 69 then
        local drone = gm.call("gml_Script__survivor_sniper_find_drone", inst, inst, inst)
        if type(drone) ~= "number" then
            drone:instance_destroy_sync()
            gm.instance_destroy(drone)
        end
    end
end)
gm.post_script_hook(gm.constants._survivor_sniper_find_drone, function(self, other, result, args)
    if result.value == -4 then
        local player = args[1].value
        local drone = gm.instance_create(player.x, player.y, gm.constants.oSniperDrone)
        drone.master = player.id
        result.value = drone
    end
end)
-- It seems like _survivor_miner_find_heat_bar's args can't get id correctly.
-- Maybe I did somewhere wrong in create_heat_bar.
gm.pre_script_hook(gm.constants._survivor_miner_find_heat_bar, function(self, other, result, args)
    if type(args[1].value) ~= "number" then
        args[1].value = args[1].value.id
    end
end)
local miner_heat_bar_flag = false
gm.post_script_hook(gm.constants._survivor_miner_find_heat_bar, function(self, other, result, args)
    if not miner_heat_bar_flag then
        if result.value == -4 or result.value == 0 then
            local player = gm.CInstance.instance_id_to_CInstance[args[1].value]
            if not player.dead then
                gm.call("gml_Script__survivor_miner_create_heat_bar", player, player)
                if player.class ~= 6.0 then
                    local actor = Instance.wrap(player)
                    actor:add_callback("onPostStep", "miner_heat_bar_fix", function(inst)
                        local cache_class = inst.class
                        inst.class = 6.0
                        gm.get_script_ref(102162)(inst.value, inst.value, inst.value)
                        inst.class = cache_class
                    end)
                end
                result.value = gm.call("gml_Script__survivor_miner_find_heat_bar", player, player, args[1].value)
            end
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_miner_create_heat_bar, function(self, other, result, args)
    miner_heat_bar_flag = true
end)
gm.post_script_hook(gm.constants._survivor_miner_create_heat_bar, function(self, other, result, args)
    miner_heat_bar_flag = false
    -- I think this is safe to use.
    -- But it may have issues, if anything happens, please let me know.
    Instance_ext.add_skill_bullet_fake_hit_actually_attack(self, 0, "miner_heat_bar_fix",
        function(attack_info, hit_target)
            local skill = gm.array_get(self.skills, 0).active_skill
            if skill.skill_id ~= 57 and skill.skill_id ~= 62 then
                gm.call("gml_Script__survivor_miner_heat_add", self, self, self, 5)
            end
        end)
end)
-- So weird, it seems like 'self' must be a skill, but in gml_Script__survivor_drifter_create_scrap_bar, it pass an oP. This is really confusing.
-- And gm.call can't pass 'self' as a YYObjectBase*, might have to use memory.dynamic_cal. So, I decided not to replace the result.
local drifter_scrap_bar_flag = false
gm.post_script_hook(gm.constants._survivor_drifter_find_scrap_bar, function(self, other, result, args)
    if not drifter_scrap_bar_flag then
        if result.value == -4 or result.value == 0 then
            if args[1].value.dead ~= 1 then
                local player = args[1].value
                gm.call("gml_Script__survivor_drifter_create_scrap_bar", player, player)
                drifter_scarp_bar_list[args[1].value.id] = true
            end
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = true
end)
gm.post_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = false
    Instance_ext.add_skill_bullet_callback(self, 0, "drifter_scrap_bar_fix", "attack", function(attack_info, hit_list)
        if not Net.is_client() then
            local attack_info_ = Attack_Info.wrap(attack_info)
            attack_info_:set_attack_flags(Attack_Info.ATTACK_FLAG.drifter_scrap_bit1, true)
        end
    end)
end)
memory.dynamic_hook_mid("gml_Object_oDrifterRec_Collision_oP", {"rdx", "[rbp+57h+18h]"}, {"RValue*", "CInstance*"}, 0,
    gm.get_object_function_address("gml_Object_oDrifterRec_Collision_oP"):add(480), function(args)
        if drifter_scarp_bar_list[args[2].id] then
            args[1].value = args[2].class
        end
    end)
local function initialize_number(target, member, value)
    if target[member] == nil then
        target[member] = value or false
    end
end
local function initialize_array(target, member, num)
    if target[member .. "_half"] == nil or gm.array_length(target[member .. "_half"]) == 0 then
        target[member .. "_half"] = gm.array_create(num, 0.0)
        gm.array_set(target[member .. "_half"], 0, target[member])
        gm.array_set(target[member .. "_half"], 1, target[member])
    end
end
CompatibilityPatch.set_compat = function(self)
    initialize_number(self, "charged")
    initialize_number(self, "_miner_charged_elder_kill_count")
    initialize_number(self, "sniper_bonus")
    initialize_number(self, "dash_timer")
    initialize_number(self, "ydisp")
    initialize_number(self, "dive")
    initialize_number(self, "_hand_sawmerang_kill_count")
    initialize_number(self, "dash_again")
    initialize_number(self, "above_50_health", true)
    initialize_number(self, "above_60_health", true)
    initialize_number(self, "spd")
    initialize_array(self, "sprite_idle", 3)
    initialize_array(self, "sprite_fall", 3)
    initialize_array(self, "sprite_jump_peak", 3)
    initialize_array(self, "sprite_jump", 3)
    initialize_array(self, "sprite_walk", 4)
    self.spat = -4 -- SpitterZ
    self.totem_spawn_id = gm.array_create(0, 0) -- monsterShamGX
    ---- for monster ----
    initialize_number(self, "input_player_index")
    initialize_number(self, "bunker")
    initialize_number(self, "aiming")
    initialize_number(self, "is_local", not Net.is_client())
    initialize_number(self, "pause")
    initialize_number(self, "menu_typing")
    initialize_number(self, "class")
end
CompatibilityPatch.has_scrap_bar = function(actor)
    if actor.class == 14 or drifter_scarp_bar_list[actor.id] then
        return true
    else
        return false
    end
end
gm.post_script_hook(gm.constants.init_class, function(self, other, result, args)
    CompatibilityPatch.set_compat(self)
end)

-- For monsterShamGX
gm.post_script_hook(100561, function(self, other, result, args)
    if math.abs(self.image_index - 6) <= 1e-5 then
        local mobs = Array.wrap(args[1].value.totem_spawn_id)
        for i = 0, mobs:size() - 1 do
            local mob_warrped = Instance.wrap(mobs:get(i))
            if not mob_warrped:callback_exists("draw_hp_bar_ally") then
                mob_warrped:add_callback("onPostDraw", "draw_hp_bar_ally", function(actor)
                    actor.hud_health_color = 6804360.0
                    actor:draw_hp_bar_ally()
                end)
                mob_warrped:actor_team_set(mob_warrped, args[1].value.team)
            end
        end
    end
end)

---- monster ----
gm.post_script_hook(gm.constants.set_state_gml_Object_oArtiSnap_Create_0, function(self, other, result, args)
    if self.team ~= 1.0 then
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)
-- I think I should use less mid-funcion hook.
-- So I choose to hook the draw event.
gm.pre_code_execute("gml_Object_oImpFriend_Draw_0", function(self, other)
    if self.team ~= 1.0 then
        self.hud_health_color = 5032411.0
    end
end)
gm.post_code_execute("gml_Object_oEngiTurretB_Alarm_3", function(self, other, result, args)
    if self.team ~= 1.0 then
        Instance.wrap(self):add_callback("onStatRecalc", "hud_health_color_reset", function(actor)
            actor.hud_health_color = 5032411.0
        end)
        GM.actor_queue_dirty(self)
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)
gm.post_code_execute("gml_Object_oEngiTurret_Alarm_3", function(self, other, result, args)
    if self.team ~= 1.0 then
        Instance.wrap(self):add_callback("onStatRecalc", "hud_health_color_reset", function(actor)
            actor.hud_health_color = 5032411.0
        end)
        GM.actor_queue_dirty(self)
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)

-- oHuntressTrirang skill
memory.dynamic_hook_mid("huntressX2fix", {"rax", "[rbp+2C0h+18h]"}, {"RValue*", "YYObjectBase*"}, 0,
    gm.get_script_function_address(100387):add(2805), function(args)
        args[2].total_trirang = (args[2].total_trirang or 0) + 1
        args[1].value.parent_skill = args[2]
    end)
gm.pre_code_execute("gml_Object_oHuntressTrirang_Destroy_0", function(self, other)
    if self.parent_skill then
        self.parent_skill.total_trirang = self.parent_skill.total_trirang - 1
    end
end)
Initialize(function()
    local huntressX2 = Skill.find("ror", "huntressX2")
    huntressX2:onPostStep(function(actor, struct, slot)
        local total_trirang = struct.total_trirang
        if total_trirang and total_trirang > 0 then
            struct.freeze_cooldown(struct, struct)
        end
    end)
end)
local huntress_step = gm.get_script_function_address(102094):add(526)
huntress_step:patch_byte(0xE9):apply()
huntress_step:add(1):patch_byte(0x13):apply()
huntress_step:add(2):patch_byte(0x02):apply()
huntress_step:add(3):patch_byte(0x00):apply()
huntress_step:add(4):patch_byte(0x00):apply()
huntress_step:add(5):patch_byte(0x90):apply()

-- handX 
local get_hand_skill_num = function(skills, slot_index)
    local num = 0
    for i = 0, (slot_index or gm.array_length(skills)) - 1 do
        local skill = gm.array_get(skills, i).active_skill
        if Utils.get_handy_drone_type(skill.skill_id) then
            num = num + 1
        end
    end
    return num
end
memory.dynamic_hook_mid("handX_fix_actor_death", {"rdx", "[rbp+0x1F88]"}, {"int", "CInstance*"}, 0,
    gm.get_script_function_address(gm.constants.actor_death):add(38162), function(args)
        local skills = args[2].skills
        local total_num = get_hand_skill_num(skills)
        for i = 0, gm.array_length(skills) - 1 do
            local before_num = get_hand_skill_num(skills, i)
            local skill = gm.array_get(skills, i).active_skill
            if Utils.get_handy_drone_type(skill.skill_id) then
                local drone = gm.instance_create(args[2].x, args[2].y, 685)
                drone.parent = args[2].id
                drone.team = args[2].team
                drone.set_type(drone, args[2], Utils.get_handy_drone_type(skill.skill_id))
                if total_num == 1 then
                    drone.angle_offsest = 0
                else
                    local step = 270 / (total_num - 1)
                    drone.angle_offsest = (before_num - (total_num - 1) / 2) * step
                end
            end
        end
        args[1]:set(-1) -- to override original, hope this may not break something
    end)
memory.dynamic_hook_mid("handX_fix_find_skill", {"rbp+410h-340h", "[rbp+410h+10h+8h]"}, {"RValue*", "CInstance*"}, 0,
    gm.get_object_function_address("gml_Object_oHANDBaby_Step_2"):add(4676), function(args)
        local actor = type(args[2].parent) == "number" and gm.CInstance.instance_id_to_CInstance[args[2].parent] or
                          args[2].parent
        local skills = actor.skills
        for i = 0, gm.array_length(skills) - 1 do
            local skill = gm.array_get(skills, i).active_skill
            local drone_type = Utils.get_handy_drone_type(skill.skill_id)
            if drone_type and args[2].drone_type == drone_type then
                args[1].value = skill
            end
        end
    end)
local target = gm.get_script_function_address(gm.constants._survivor_hand_x_skill_find_drone):add(1018)
memory.dynamic_hook_mid("handX_fix_find_drone", {"[rbp+70h+10h]"}, {"CInstance*"}, 0,
    gm.get_script_function_address(gm.constants._survivor_hand_x_skill_find_drone):add(614), function(args)
        local actor = type(args[1].parent) == "number" and gm.CInstance.instance_id_to_CInstance[args[1].parent] or
                          args[1].parent
        if actor.last_use_hand_drone_type ~= args[1].drone_type then
            return target
        end
    end)
memory.dynamic_hook_mid("handX_fix_angle", {"rbp+410h-438h", "[rbp+410h+10h]"}, {"RValue*", "CInstance*"}, 0,
    gm.get_object_function_address("gml_Object_oHANDBaby_Step_2"):add(6545), function(args)
        if args[2].angle_offsest then
            args[1].value = args[1].value + args[2].angle_offsest
        end
    end)
gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    local drone_type = Utils.get_handy_drone_type(skill.skill_id)
    if drone_type then
        self.last_use_hand_drone_type = drone_type
    end
end)

return CompatibilityPatch
