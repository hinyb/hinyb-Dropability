local drifter_scarp_bar_list = {}
local miner_heat_bar_list = {}
CompatibilityPatch = {}
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drifter_scarp_bar_list = {}
    miner_heat_bar_list = {}
end)
SkillPickup.add_pre_local_drop_func(function(inst, skill)
    if skill.skill_id == 68 or skill.skill_id == 69 then
        local drone = gm.call("gml_Script__survivor_sniper_find_drone", inst, inst, inst)
        drone:instance_destroy_sync()
        gm.instance_destroy(drone)
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
            if not player.dead and player.object_index == gm.constants.oP then
                gm.call("gml_Script__survivor_miner_create_heat_bar", player, player)
                miner_heat_bar_list[self.id] = true
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
end)
gm.post_code_execute("gml_Object_oP_Step_2", function(self, other)
    if self.class ~= 6 and miner_heat_bar_list[self.id] and self.activity_type ~= 4.0 then
        local cache_class = self.class
        self.class = 6.0
        gm.call("gml_Script__survivor_miner_update_sprites", self, self, self)
        gm.get_script_ref(102162)(self, self, self.id)
        self.class = cache_class
    end
end)
-- So weird, it seems like 'self' must be a skill, but in gml_Script__survivor_drifter_create_scrap_bar, it pass an oP. This is really confusing.
-- And gm.call can't pass 'self' as a YYObjectBase*, might have to use memory.dynamic_cal. So, I decided not to replace the result.
local drifter_scrap_bar_flag = false
gm.post_script_hook(gm.constants._survivor_drifter_find_scrap_bar, function(self, other, result, args)
    if not drifter_scrap_bar_flag then
        if result.value == -4 or result.value == 0 then
            if self.dead ~= 1 then
                gm.call("gml_Script__survivor_drifter_create_scrap_bar", args[1].value, args[1].value)
                drifter_scarp_bar_list[self.id] = true
            end
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = true
end)
gm.post_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = false
end)
memory.dynamic_hook_mid("gml_Object_oDrifterRec_Collision_oP", {"rdx", "[rbp+57h+18h]"}, {"RValue*", "CInstance*"}, 0,
    gm.get_object_function_address("gml_Object_oDrifterRec_Collision_oP"):add(480), function(args)
        if drifter_scarp_bar_list[args[2].id] then
            args[1].value = args[2].class
        end
    end)
local function defalut_nil(target, member, value)
    if target[member] == nil then
        target[member] = value or false
    end
end
local function nilcreate(target, member, num)
    if target[member .. "_half"] == nil or gm.array_length(target[member .. "_half"]) == 0 then
        target[member .. "_half"] = gm.array_create(num, 0.0)
        gm.array_set(target[member .. "_half"], 0, target[member])
        gm.array_set(target[member .. "_half"], 1, target[member])
    end
end
CompatibilityPatch.set_compat = function(self)
    defalut_nil(self, "charged")
    defalut_nil(self, "_miner_charged_elder_kill_count")
    defalut_nil(self, "sniper_bonus")
    defalut_nil(self, "dash_timer")
    defalut_nil(self, "ydisp")
    defalut_nil(self, "dive")
    defalut_nil(self, "_hand_sawmerang_kill_count")
    defalut_nil(self, "dash_again")
    defalut_nil(self, "above_50_health", true)
    defalut_nil(self, "above_60_health", true)
    defalut_nil(self, "spd")
    nilcreate(self, "sprite_idle", 3)
    nilcreate(self, "sprite_fall", 3)
    nilcreate(self, "sprite_jump_peak", 3)
    nilcreate(self, "sprite_jump", 3)
    nilcreate(self, "sprite_walk", 4)
    self.spat = -4 -- SpitterZ
    self.totem_spawn_id = gm.array_create(0, 0) -- monsterShamGX
    ---- for monster ----
    defalut_nil(self, "aiming")
    defalut_nil(self, "is_local")
    defalut_nil(self, "pause")
    defalut_nil(self, "menu_typing")
    defalut_nil(self, "class")
end
CompatibilityPatch.has_scrap_bar = function (actor)
    if actor.class == 14 or drifter_scarp_bar_list[actor.id] then
        return true
    else
        return false
    end
end
gm.post_script_hook(gm.constants.init_class, function(self, other, result, args)
    CompatibilityPatch.set_compat(self)
end)
-- still have some issues
memory.dynamic_hook_mid("actor_death", {"rdx", "[rbp+0x1F88]"}, {"int", "CInstance*"}, 0,
    gm.get_script_function_address(gm.constants.actor_death):add(38162), function(args)
        local skills = args[2].skills
        for i = 0, #skills - 1 do
            local skill_id = gm.array_get(skills, i).active_skill.skill_id
            if Utils.get_handy_drone_type(skill_id) then
                local drone = gm.instance_create(args[2].x, args[2].y, 685)
                drone.parent = args[2].id
                drone.team = args[2].team
                drone.set_type(drone, args[2], Utils.get_handy_drone_type(skill_id))
            end
        end
        args[1]:set(-1) -- to override original, hope this may not break something
    end)

-- For monsterShamGX
local sham_list = {
    [gm.constants.oShamL] = true,
    [gm.constants.oShamP] = true,
    [gm.constants.oShamB] = true,
    [gm.constants.oShamG] = true
}
gm.pre_script_hook(gm.constants.find_target, function(self, other, result, args)
    if self.team == 1 and sham_list[self.object_index] then
        result.value = 0
        local list = gm.ds_list_create();
        gm.collision_circle_list(self.x, self.y, self.target_range, gm.constants.oActorTargetEnemy, false, false, list,
            true);
        for i = 0, gm.ds_list_size(list) - 1 do
            local target = gm.ds_list_find_value(list, i)
            if target.parent.team ~= self.team then
                self.target = target
                break
            end
        end
        gm.ds_list_destroy(list);
        return false
    end
end)
gm.post_script_hook(100561, function(self, other, result, args)
    if math.abs(self.image_index - 6) <= 1e-5 then
        local mobs = Array.wrap(args[1].value.totem_spawn_id)
        for i = 0, mobs:size() - 1 do
            mobs:get(i).team = args[1].value.team
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
gm.post_code_execute("gml_Object_oEngiTurretB_Alarm_3", function(self, other, result, args)
    if self.team ~= 1.0 then
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)
gm.post_code_execute("gml_Object_oEngiTurret_Alarm_3", function(self, other, result, args)
    if self.team ~= 1.0 then
        self.is_character_enemy_targettable = 0.0
        gm.call("gml_Script___actor_update_target_marker", self, self)
    end
end)

return CompatibilityPatch