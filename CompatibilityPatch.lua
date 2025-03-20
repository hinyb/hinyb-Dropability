HookSystem.clean_hook()
local drifter_scarp_bar_list = {}
CompatibilityPatch = {}
HookSystem.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drifter_scarp_bar_list = {}
end)
SkillPickup.add_pre_local_drop_func(function(inst, skill)
    local skill_id = skill.skill_id
    if skill_id ~= 68 and skill_id ~= 69 then
        return
    end
    local drone = gm.call("gml_Script__survivor_sniper_find_drone", inst, inst, inst)
    if type(drone) ~= "number" then
        drone:instance_destroy_sync()
        gm.instance_destroy(drone)
    end
end)
HookSystem.post_script_hook(gm.constants._survivor_sniper_find_drone, function(self, other, result, args)
    if result.value == -4 then
        local player = args[1].value
        local drone = gm.instance_create(player.x, player.y, gm.constants.oSniperDrone)
        drone.master = player.id
        result.value = drone
    end
end)
-- It seems like _survivor_miner_find_heat_bar's args can't get id correctly.
-- Maybe I did somewhere wrong in create_heat_bar.
HookSystem.pre_script_hook(gm.constants._survivor_miner_find_heat_bar, function(self, other, result, args)
    if type(args[1].value) ~= "number" then
        args[1].value = args[1].value.id
    end
end)
local miner_heat_bar_flag = false
HookSystem.post_script_hook(gm.constants._survivor_miner_find_heat_bar, function(self, other, result, args)
    if miner_heat_bar_flag then
        return
    end
    if result.value ~= -4 and result.value ~= 0 then
        return
    end
    local player = gm.CInstance.instance_id_to_CInstance[args[1].value]
    if player.dead then
        return
    end
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
end)
HookSystem.pre_script_hook(gm.constants._survivor_miner_create_heat_bar, function(self, other, result, args)
    miner_heat_bar_flag = true
end)
HookSystem.post_script_hook(gm.constants._survivor_miner_create_heat_bar, function(self, other, result, args)
    miner_heat_bar_flag = false
    InstanceExtManager.add_skill_bullet_callback(self, 0, "miner_heat_bar_fix", "hit", function()
        local skill = gm.array_get(self.skills, 0).active_skill
        if skill.skill_id ~= 57 and skill.skill_id ~= 62 then
            Utils.miner_heat_add_sync(self, 5)
        end
    end)
end)
-- So weird, it seems like 'self' must be a skill, but in gml_Script__survivor_drifter_create_scrap_bar, it pass an oP. This is really confusing.
-- And gm.call can't pass 'self' as a YYObjectBase*, might have to use memory.dynamic_cal. So, I decided not to replace the result.
local drifter_scrap_bar_flag = false
HookSystem.post_script_hook(gm.constants._survivor_drifter_find_scrap_bar, function(self, other, result, args)
    if drifter_scrap_bar_flag then
        return
    end
    if result.value ~= -4 and result.value ~= 0 then
        return
    end
    if args[1].value.dead ~= 1 then
        local player = args[1].value
        gm.call("gml_Script__survivor_drifter_create_scrap_bar", player, player)
        drifter_scarp_bar_list[args[1].value.id] = true
    end
end)
HookSystem.pre_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = true
end)
HookSystem.post_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = false
    InstanceExtManager.add_skill_bullet_callback(self, 0, "drifter_scrap_bar_fix", "attack",
        function(attack_info, hit_list)
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
    if target[member] == nil then
        target[member] = target.sprite_index
    end
    if target[member .. "_half"] == nil or gm.array_length(target[member .. "_half"]) == 0 then
        target[member .. "_half"] = gm.array_create(num, 0)
        for i = 0, num - 1 do
            gm.array_set(target[member .. "_half"], i, target[member])
        end
    end
end
CompatibilityPatch.set_compat = function(actor)
    InstanceExtManager.add_callback(actor, "pre_skill_activate", "need_target_skill_fix", function(actor, slot_index)
        if actor.object_index ~= gm.constants.oP then
            return
        end
        local skill = actor:actor_get_skill_active(slot_index)
        if not Utils.is_skill_need_target(skill.skill_id) then
            return
        end
        local target = gm.find_target_nearest(actor.x, actor.y, actor.team)
        if actor:distance_to_object(target) <= 400 then -- copy from gml_Script_alarm_ai_default_do_targetting
            actor.target = target
            return
        end
        actor.target = -4
        return false
    end)
    initialize_number(actor, "charged")
    initialize_number(actor, "_miner_charged_elder_kill_count")
    initialize_number(actor, "sniper_bonus")
    initialize_number(actor, "dash_timer")
    initialize_number(actor, "ydisp")
    initialize_number(actor, "dive")
    initialize_number(actor, "_hand_sawmerang_kill_count")
    initialize_number(actor, "dash_again")
    initialize_number(actor, "above_50_health", true)
    initialize_number(actor, "above_60_health", true)
    initialize_number(actor, "spd")
    initialize_array(actor, "sprite_idle", 3)
    initialize_array(actor, "sprite_fall", 3)
    initialize_array(actor, "sprite_jump_peak", 3)
    initialize_array(actor, "sprite_jump", 3)
    initialize_array(actor, "sprite_walk", 4)
    initialize_number(actor, "spat", -4) -- SpitterZ
    initialize_number(actor, "totem_spawn_id", gm.array_create(0, 0)) -- monsterShamGX
    --[[
    hp / maxhp * 2 < armor_buff and armor_buff ~= 1 and hp ~= 0
    armor_buff -=1
    apply_buff
    skill_combo +=1
    ]]
    initialize_number(actor, "armor_buff", 2) -- for boss skills
    initialize_number(actor, "combo", 0)
    initialize_number(actor, "skill_count_primary", 0)
    initialize_number(actor, "skill_count_primary_bursts", 0)
    initialize_number(actor, "skill_count_1", 0)
    initialize_number(actor, "skill_count_2", 0)
    initialize_number(actor, "skill_combo", 0)

    ---- for monster ----
    initialize_number(actor, "input_player_index")
    initialize_number(actor, "bunker")
    initialize_number(actor, "aiming")
    initialize_number(actor, "is_local", not Net.is_client())
    initialize_number(actor, "pause")
    initialize_number(actor, "menu_typing")
    initialize_number(actor, "class")
    initialize_number(actor, "sprite_palette")
    initialize_number(actor, "skin_current")
    ---- for drone ----
end
CompatibilityPatch.has_scrap_bar = function(actor)
    if actor.class == 14 or drifter_scarp_bar_list[actor.id] then
        return true
    else
        return false
    end
end
HookSystem.post_script_hook(gm.constants.init_class, function(self, other, result, args)
    CompatibilityPatch.set_compat(self)
end)

-- For monsterShamGX
HookSystem.post_script_hook(100561, function(self, other, result, args)
    if math.abs(self.image_index - 6) > 1e-5 then
        return
    end
    local mobs = Array.wrap(args[1].value.totem_spawn_id)
    for i = 0, mobs:size() - 1 do
        local mob_warrped = Instance.wrap(mobs:get(i))
        if args[1].value.team == 1 then
            if not mob_warrped:callback_exists("draw_hp_bar_ally") then
                mob_warrped:add_callback("onPostDraw", "draw_hp_bar_ally", function(actor)
                    actor.hud_health_color = 6804360.0
                    actor:draw_hp_bar_ally()
                end)
            end
            mob_warrped.is_character_enemy_targettable = 1.0
        end
        mob_warrped:actor_team_set(mob_warrped, args[1].value.team)
    end
end)

---- monster ----
HookSystem.post_script_hook(gm.constants.set_state_gml_Object_oArtiSnap_Create_0, function(self, other, result, args)
    if self.team == 2.0 then
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)
memory.dynamic_hook_mid("tentacle_hp_color_fix", {"rdi", "r12"}, {"RValue*", "RValue*"}, 0,
    gm.get_script_function_address(101568):add(1845), function(args)
        if args[1].value ~= 1.0 then
            Instance.wrap(args[2].value):add_callback("onPostStatRecalc", "tentacle_hp_color_fix", function(actor)
                actor.hud_health_color = 5032411.0
            end)
        end
    end)
HookSystem.post_code_execute("gml_Object_oEngiTurretB_Alarm_3", function(self, other, result, args)
    if self.team ~= 1.0 then
        Instance.wrap(self):add_callback("onStatRecalc", "hud_health_color_reset", function(actor)
            actor.hud_health_color = 5032411.0
        end)
        gm.actor_queue_dirty(self)
    end
    if self.team == 2.0 then
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)
HookSystem.post_code_execute("gml_Object_oEngiTurret_Alarm_3", function(self, other, result, args)
    if self.team ~= 1.0 then
        Instance.wrap(self):add_callback("onStatRecalc", "hud_health_color_reset", function(actor)
            actor.hud_health_color = 5032411.0
        end)
        gm.actor_queue_dirty(self)
    end
    if self.team == 2.0 then
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
HookSystem.pre_code_execute("gml_Object_oHuntressTrirang_Destroy_0", function(self, other)
    if self.parent_skill then
        self.parent_skill.total_trirang = self.parent_skill.total_trirang - 1
    end
end)
Initialize(function()
    local huntressX2 = Skill.find("ror", "huntressX2")
    huntressX2:onStep(function(actor, struct, slot)
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
        local actor = Utils.get_inst_safe(args[2].parent)
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
        local actor = Utils.get_inst_safe(args[1].parent)
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
HookSystem.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    local drone_type = Utils.get_handy_drone_type(skill.skill_id)
    if drone_type then
        self.last_use_hand_drone_type = drone_type
    end
end)

-- monsterBossV
HookSystem.post_script_hook(gm.constants.instance_create, function(self, other, result, args)
    -- have to use this, because in monsterBossV, one instance_create just doesn't have enough room for the hook.
    if args[3].value == gm.constants.oBossSkill2 then
        result.value.parent = other
    end
end)
memory.dynamic_hook_mid("monsterBossV_targetting_fix", {"rsp+460h-418h", "[rbp+360h+10h]"}, {"RValue*", "CInstance*"},
    0, gm.get_script_function_address(104065):add(4114), function(args)
        local team = args[2].team
        if team == 2 then
            return
        end
        if team == 1 then
            args[1].value = gm.constants.pEnemy
            return
        end
        args[1].value = gm.constants.pActor
    end)
-- There may have some issues.
memory.dynamic_hook_mid("monsterBossV_team_fix", {"rax", "[rbp+240h-1D0h]", "[rbp+240h+10h]"},
    {"RValue*", "RValue*", "CInstance*"}, 0, gm.get_object_function_address("gml_Object_oBossSkill2_Step_2"):add(3066),
    function(args)
        local parent = args[3].parent
        -- didn't check it.
        if parent.object_index ~= gm.constants.oBoss2 then
            args[2].value = 2
            args[1].value = parent.id
        end
    end)


-- monsterBossFinalX
memory.dynamic_hook_mid("monsterBossFinalX_team_fix", {"[rbp+450h+10h]"}, {"CInstance*"}, 0,
    gm.get_script_function_address(104088):add(9814), function(args)
        args[1].team = args[1].parent.team
    end)
memory.dynamic_hook_mid("monsterBossFinalX_targetting_fix", {"[rbp+310h-220h]", "[rbp+310h+10h]"},
    {"RValue*", "CInstance*"}, 0, gm.get_object_function_address("gml_Object_oEfBoss4SliceDoT_Alarm_1"):add(2047),
    function(args)
        local team = args[2].team
        if team == 2 then
            return
        end
        if team == 1 then
            args[1].value = gm.constants.pEnemy
            return
        end
        args[1].value = gm.constants.pActor
    end)
return CompatibilityPatch
