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
    local drone = inst:_survivor_sniper_find_drone(inst)
    if lua_type(drone) ~= "number" then
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
    if lua_type(args[1].value) ~= "number" then
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
    player:_survivor_miner_create_heat_bar()
    if player.class ~= 6.0 then
        gm.event_hook_post_add(player, gm.constants.ev_step, 2, "miner_heat_bar_fix", function(inst)
            local cache_class = inst.class
            inst.class = 6.0
            inst["anon@5631@anon@3473@scr_ror_init_survivor_miner@scr_ror_init_survivor_miner"](inst, inst)
            inst.class = cache_class
        end)
    end
    result.value = player:_survivor_miner_find_heat_bar(args[1].value)
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
        player:_survivor_drifter_create_scrap_bar()
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
            if not Net.client then
                local attack_info_ = AttackInfo.wrap(attack_info)
                attack_info_:set_flag(AttackFlag.DRIFTER_SCRAP_BIT1, true)
            end
        end)
end)
memory.dynamic_hook_mid("gml_Object_oDrifterRec_Collision_oP", { "rdx", "[rbp+57h+18h]" }, { "RValue*", "CInstance*" }, 0,
    gm.get_object_function_address("gml_Object_oDrifterRec_Collision_oP"):add(457), function(args)
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
    initialize_number(actor, "spat", -4)                              -- SpitterZ
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
    initialize_number(actor, "is_local", not Net.client)
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
        local mob = mobs:get(i)
        if Instance.exists(mob) then
            if args[1].value.team == 1 then
                if not gm.event_hook_post_has(mob, gm.constants.ev_draw, 0, "draw_hp_bar_ally") then
                    gm.event_hook_post_add(mob, gm.constants.ev_draw, 0, "draw_hp_bar_ally", function(actor)
                        actor.hud_health_color = 6804360.0
                        actor:draw_hp_bar_ally()
                    end)
                end
                mob.is_character_enemy_targettable = 1.0
            end
            mob:actor_team_set(mob, args[1].value.team)
        end
    end
end)

---- monster ----
HookSystem.post_script_hook(gm.constants["set_state@gml_Object_oArtiSnap_Create_0"], function(self, other, result, args)
    if self.team == 2.0 then
        self.is_character_enemy_targettable = 0.0
        self:__actor_update_target_marker()
    end
end)
memory.dynamic_hook_mid("tentacle_hp_color_fix", { "[rbp+90h-58h]", "[rbp+90h-60h]" }, { "RValue*", "RValue*" }, 0,
    gm.get_script_function_address(gm.constants["anon@900@anon@30@scr_ror_items_init_boss@scr_ror_items_init_boss"]):add(2096), function(args)
        if args[1].value ~= 1.0 then
            InstanceExtManager.add_callback(args[2].value, "post_recalculate_stats", "tentacle_hp_color_fix", function(actor)
                actor.hud_health_color = 5032411.0
            end)
        end
    end)
local function apply_turret_team_settings(self)
    if self.team ~= 1.0 then
        InstanceExtManager.add_callback(self, "post_recalculate_stats", "hud_health_color_reset", function (actor)
            actor.hud_health_color = 5032411.0
        end)
        gm.actor_queue_dirty(self)
    end
    if self.team == 2.0 then
        self.is_character_enemy_targettable = 0.0
        self:__actor_update_target_marker()
    end
end
HookSystem.post_code_execute("gml_Object_oEngiTurretB_Alarm_3", function(self, other, result, args)
    apply_turret_team_settings(self)
end)
HookSystem.post_code_execute("gml_Object_oEngiTurret_Alarm_3", function(self, other, result, args)
    apply_turret_team_settings(self)
end)

-- oHuntressTrirang skill
memory.dynamic_hook_mid("huntressX2fix", { "rax", "[rbp+300h+18h]" }, { "RValue*", "YYObjectBase*" }, 0,
    gm.get_script_function_address(gm.constants["anon@5987@anon@5879@anon@28@scr_ror_init_survivor_huntress_alts@scr_ror_init_survivor_huntress_alts"]):add(3299), function(args)
        args[2].total_trirang = (args[2].total_trirang or 0) + 1
        args[1].value.parent_skill = args[2]
    end)
HookSystem.pre_code_execute("gml_Object_oHuntressTrirang_Destroy_0", function(self, other)
    if self.parent_skill then
        self.parent_skill.total_trirang = self.parent_skill.total_trirang - 1
    end
end)
Initialize.add_hotloadable(function()
    local huntressX2 = Skill.find("huntressX2", "ror")
    Global.class_callback:get(huntressX2.on_step):set(0, 1)
    Callback.add(huntressX2.on_step, function(actor, struct, slot)
        local total_trirang = struct.total_trirang
        if total_trirang and total_trirang > 0 then
            struct.freeze_cooldown(struct, struct)
        end
    end)
end)
local huntress_step = gm.get_script_function_address(gm.constants["anon@3705@anon@1622@scr_ror_init_survivor_huntress@scr_ror_init_survivor_huntress"]):add(533)
huntress_step:add(1):patch_byte(0x30):apply()

-- handX
do
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
    memory.dynamic_hook_mid("handX_fix_actor_death", { "rdx", "[rbp+2880h+18h]" }, { "int", "CInstance*" }, 0,
        gm.get_script_function_address(gm.constants.actor_death):add(38550), function(args)
            local skills = args[2].skills
            local total_num = get_hand_skill_num(skills)
            for i = 0, gm.array_length(skills) - 1 do
                local before_num = get_hand_skill_num(skills, i)
                local skill = gm.array_get(skills, i).active_skill
                if Utils.get_handy_drone_type(skill.skill_id) then
                    local drone = gm.instance_create(args[2].x, args[2].y, gm.constants.oHANDBaby)
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
            args[1]:set(-1)
        end)
    memory.dynamic_hook_mid("handX_fix_find_skill", { "rbp+0AD0h-AB0h", "[rbp+0AD0h+10h]" }, { "RValue*", "CInstance*" },
        0,
        gm.get_object_function_address("gml_Object_oHANDBaby_Step_2"):add(5841), function(args)
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
    local target = gm.get_script_function_address(gm.constants._survivor_hand_x_skill_find_drone):add(1034)
    memory.dynamic_hook_mid("handX_fix_find_drone", { "[rbp+80h+10h]" }, { "CInstance*" }, 0,
        gm.get_script_function_address(gm.constants._survivor_hand_x_skill_find_drone):add(628), function(args)
            local actor = Utils.get_inst_safe(args[1].parent)
            if actor.last_use_hand_drone_type ~= args[1].drone_type then
                return target
            end
        end)
    memory.dynamic_hook_mid("handX_fix_angle", { "rbp+AD0h-510h", "[rbp+AD0h+10h]" }, { "RValue*", "CInstance*" }, 0,
        gm.get_object_function_address("gml_Object_oHANDBaby_Step_2"):add(8012), function(args)
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
end

-- monsterBossV
HookSystem.post_script_hook(gm.constants.instance_create, function(self, other, result, args)
    -- have to use this, because in monsterBossV, one instance_create just doesn't have enough room for the hook.
    if args[3].value == gm.constants.oBossSkill2 then
        result.value.parent = other
    end
end)
memory.dynamic_hook_mid("monsterBossV_targetting_fix", { "rsp+610h-5D8h", "rbp+510h+10h" }, { "RValue*", "CInstance*" },
    0, gm.get_script_function_address(gm.constants["anon@12263@anon@11972@anon@30@scr_skills_enemy_boss1@scr_skills_enemy_boss1"]):add(4980), function(args)
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
do
    local boss_list = {
        [gm.constants.oBoss1] = true,
        [gm.constants.oBoss2Clone] = true,
        [gm.constants.oBoss3] = true,
        [gm.constants.oBoss4] = true
    }
    memory.dynamic_hook_mid("monsterBossV_team_fix", { "rax", "[rbp+2A0h-140h]", "[rbp+2A0h+10h]" },
        { "RValue*", "RValue*", "CInstance*" }, 0,
        gm.get_object_function_address("gml_Object_oBossSkill2_Step_2"):add(3860),
        function(args)
            local parent = Utils.get_inst_safe(args[3].parent.parent)
            if not boss_list[parent.object_index] then
                args[2].value = 2
                args[1].value = parent.id
            end
        end)
end

-- monsterBossFinalX
memory.dynamic_hook_mid("monsterBossFinalX_team_fix", { "[rbp+4A0h+10h]" }, { "CInstance*" }, 0,
    gm.get_script_function_address(gm.constants["anon@28770@anon@30@scr_skills_enemy_boss1@scr_skills_enemy_boss1"]):add(12742), function(args)
        args[1].team = args[1].parent.team
    end)
memory.dynamic_hook_mid("monsterBossFinalX_team_fix2", { "[rbp+2F0h+10h]" }, { "CInstance*" }, 0,
    gm.get_script_function_address(gm.constants["anon@31017@anon@30@scr_skills_enemy_boss1@scr_skills_enemy_boss1"]):add(8795), function(args)
        args[1].team = args[1].parent.team
    end)
memory.dynamic_hook_mid("monsterBossFinalX_targetting_fix", { "[rbp+2D0h-160h]", "[rbp+2D0h+10h]" },
    { "RValue*", "CInstance*" }, 0, gm.get_object_function_address("gml_Object_oEfBoss4SliceDoT_Alarm_1"):add(2367),
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
