Instance_ext = {}
local callbacks = {}
local callbacks_check_table = {
    pre_destroy = true,
    post_local_drop = true,
    post_local_pickup = true,
    pre_damager_attack_process = true,
    pre_damager_attack_process_parent = true,
    pre_actor_death_after_hippo = true,
    pre_actor_set_dead = true,
    pre_skill_activate = true,
    post_skill_activate = true,
    pre_actor_activity_set = true,
    post_other_fire_explosion = true,
    post_other_fire_direct = true,
    post_other_fire_bullet = true,
    post_bullet_kill_proc = true,
    pre_damager_hit_process = true
}
function Instance_ext.add_on_anim_end(self, name, fn)
    name = name .. "on_anim_end"
    local inst = Instance.wrap(self)
    if not inst:callback_exists(name) then
        local flag
        inst:add_callback("onPostStep", name, function(actor)
            if flag == nil then
                flag = actor.state_strafe_half
            end
            if flag ~= 1.0 then
                local image_index = actor.image_index
                local image_number = actor.image_number
                if math.abs(image_index - image_number + 1) <= 0.0001 then
                    fn(inst)
                    actor:remove_callback(name)
                elseif image_index >= image_number - 1 then
                    fn(inst)
                    actor:remove_callback(name)
                end
            elseif actor.state_strafe_half ~= flag then
                fn(inst)
                actor:remove_callback(name)
            end
        end)
    end
end

function Instance_ext.add_post_other_fire(self, name, fn)
    Instance_ext.add_callback(self, "post_other_fire_explosion", name, fn)
    Instance_ext.add_callback(self, "post_other_fire_direct", name, fn)
    Instance_ext.add_callback(self, "post_other_fire_bullet", name, fn)
end

function Instance_ext.remove_post_other_fire(self, name)
    Instance_ext.remove_callback(self, "post_other_fire_explosion", name)
    Instance_ext.remove_callback(self, "post_other_fire_direct", name)
    Instance_ext.remove_callback(self, "post_other_fire_bullet", name)
end

function Instance_ext.add_skill_instance_captrue(actor, slot_index, name, deal_func, pre_func, post_func)
    local last_activity_state = 0
    local name = name .. tostring(slot_index)
    Instance_ext.add_callback(actor, "pre_skill_activate", name, function(actor, slot_index_)
        if slot_index_ ~= slot_index then
            return
        end
        Utils.hook_instance_create({gm.constants.oActorTargetEnemy, gm.constants.oActorTargetPlayer})
        last_activity_state = actor.__activity_handler_state
        if pre_func then
            return pre_func(actor, slot_index)
        end
    end)
    Instance_ext.add_callback(actor, "post_skill_activate", name, function(actor, slot_index_)
        if slot_index_ ~= slot_index then
            return
        end
        local list = Utils.get_tracked_instances()
        for i = 1, #list do
            deal_func(list[i])
        end
        Utils.unhook_instance_create()
        if actor.__activity_handler_state ~= last_activity_state then
            if actor.__activity_handler_func then
                local check_func = function(self, other, result, args)
                    return args[3].value == actor
                end
                local script_name = actor.__activity_handler_func.callable_value.script_name
                Callable_call.add_capture_instance(script_name, name .. tostring(actor.id), deal_func, check_func)
                Instance_ext.add_callback(actor, "pre_actor_activity_set", name, function()
                    Callable_call.remove_capture_instance(script_name, name .. tostring(actor.id))
                    Instance_ext.remove_callback(actor, "pre_actor_activity_set", name)
                end)
            end
        end
        local state_array = Class.Actor_State:get(actor.actor_state_current_id)
        if state_array then
            local check_func = function(self, other, result, args)
                return args[2].value == actor
            end
            local name = name .. tostring(actor.id)
            Callback_ext.add_capture_instance(state_array:get(2), name, deal_func, check_func)
            Callback_ext.add_capture_instance(state_array:get(4), name, deal_func, check_func)
            Callback_ext.add_capture_instance(state_array:get(3), name, deal_func, check_func, nil, function()
                Callback_ext.remove_capture_instance(state_array:get(2), name)
                Callback_ext.remove_capture_instance(state_array:get(4), name)
                Callback_ext.remove_capture_instance(state_array:get(3), name)
            end)
        end
        if post_func then
            post_func(actor, slot_index)
        end
    end)
end

function Instance_ext.remove_skill_captrue(actor, slot_index, name)
    local name = name .. tostring(slot_index)
    Instance_ext.remove_callback(actor, "pre_skill_activate", name)
    Instance_ext.remove_callback(actor, "post_skill_activate", name)
end

local black_list = {
    [gm.constants.oMinerDust] = true,
    [gm.constants.oSniperBar] = true,
    [gm.constants.oMinerBar] = true,
    [gm.constants.oCustomBar] = true,
    [gm.constants.oChefJar] = true,
    [gm.constants.oMinerDust] = true,
    [gm.constants.oHANDGauge] = true,
    [gm.constants.oMercAfterimageController] = true,
    [gm.constants.oConsHand] = true,
    [gm.constants.oPilotChute] = true,
    [gm.constants.oAcridDiseaseMaster] = true,
    [gm.constants.oSpiderBulletNoSync] = true, -- only particles and sounds
    [gm.constants.oPilotBullet] = true,
    [gm.constants.oGuardBulletNoSync] = true,
    [gm.constants.oScavengerBulletNoSync] = true
}

local bullet_list = {
    [gm.constants.oDirectAttack] = true,
    [gm.constants.oExplosionAttack] = true,
    [gm.constants.oBulletAttack] = true
}

function Instance_ext.add_skill_bullet_captrue(actor, slot_index, name, deal_func, pre_func, post_func)
    Instance_ext.add_skill_instance_captrue(actor, slot_index, name, function(inst)
        if bullet_list[inst.object_index] then
            deal_func(inst)
            return
        end
        if black_list[inst.object_index] then
            return
        end
        if string.sub(inst.object_name, 1, 3) == "oEf" then
            return
        end
        if not inst.parent then
            return
        end
        local inst_parent = Utils.get_inst_safe(inst.parent)
        if inst_parent.object_index == gm.constants.oP then
            Instance_ext.add_post_other_fire(inst, name, function(self, other, bullet)
                deal_func(bullet)
            end)
            return
        end
    end, pre_func, post_func)
end

function Instance_ext.add_skill_bullet_attack(actor, slot_index, name, deal_func, pre_func, post_func)
    Instance_ext.add_skill_bullet_captrue(actor, slot_index, name, function(attack)
        Instance_ext.add_callback(attack, "pre_damager_attack_process", name, deal_func)
    end, pre_func, post_func)
end

function Instance_ext.add_skill_bullet_hit(actor, slot_index, name, deal_func, pre_func, post_func)
    Instance_ext.add_skill_bullet_captrue(actor, slot_index, name, function(attack)
        Instance_ext.add_callback(attack, "pre_damager_hit_process", name, deal_func)
    end, pre_func, post_func)
end
function Instance_ext.add_skill_bullet_kill(actor, slot_index, name, deal_func, pre_func, post_func)
    Instance_ext.add_skill_bullet_captrue(actor, slot_index, name, function(attack)
        Instance_ext.add_callback(attack, "post_bullet_kill_proc", name, deal_func)
    end, pre_func, post_func)
end
function Instance_ext.add_callback(self, callback, name, fn)
    if not callbacks_check_table[callback] then
        log.error("Can't add Instance_ext callback", 2)
    end
    if callbacks[self.id] == nil then
        callbacks[self.id] = {}
    end
    if callbacks[self.id][callback] == nil then
        callbacks[self.id][callback] = {}
    end
    if callbacks[self.id][callback][name] then
        log.warning("try to override", callback, name)
    end
    callbacks[self.id][callback][name] = fn
end
function Instance_ext.remove_callback(self, callback, name)
    if callbacks[self.id] and callbacks[self.id][callback] and callbacks[self.id][callback][name] then
        callbacks[self.id][callback][name] = nil
    end
end
SkillPickup.add_post_local_drop_func(function(inst, skill)
    if callbacks[inst.id] and callbacks[inst.id]["post_local_drop"] then
        for _, func in pairs(callbacks[inst.id]["post_local_drop"]) do
            func(inst, skill)
        end
    end
end)
SkillPickup.add_post_local_pickup_func(function(inst, skill)
    if callbacks[inst.id] and callbacks[inst.id]["post_local_pickup"] then
        for _, func in pairs(callbacks[inst.id]["post_local_pickup"]) do
            func(inst, skill)
        end
    end
end)

-- Some Instance don't use instance_destroy, like bullet.
memory.dynamic_hook("pre_destroy_deep", "int64_t", {"CInstance*", "CInstance*", "int", "char", "char"},
    Dynamic.instance_destroy_deep_ptr, function(ret_val, a1, a2, a3, a4, a5)
        local execute_event_flag = a4:get()
        if execute_event_flag == 1 then
            local id = a3:get()
            if id == 4294967295 then -- here should be -1, but for some reasons it is 4294967295.
                id = a1.id
            end
            if callbacks[id] and callbacks[id]["pre_destroy"] then
                local flag = true
                for _, func in pairs(callbacks[id]["pre_destroy"]) do
                    if func(gm.CInstance.instance_id_to_CInstance[id]) == false then
                        flag = false
                    end
                end
                return flag
            end
        end
    end, function(ret_val, a1, a2, a3, a4, a5)
        local execute_event_flag = a4:get()
        if execute_event_flag == 1 then
            local id = a3:get()
            if id == 4294967295 then -- here should be -1, but for some reasons it is 4294967295.
                id = a1.id
            end
            callbacks[id] = nil
        end
    end)

gm.pre_script_hook(gm.constants.actor_death, function(self, other, result, args)
    if gm.array_get(self.inventory_item_stack, 76) == 0 then -- temporary solution.
        if callbacks[self.id] and callbacks[self.id]["pre_actor_death_after_hippo"] then
            for _, func in pairs(callbacks[self.id]["pre_actor_death_after_hippo"]) do
                func(self)
            end
        end
    end
end)
gm.pre_script_hook(gm.constants.actor_set_dead, function(self, other, result, args)
    local id = type(args[1].value) == "number" and args[1].value or args[1].value.id
    if callbacks[id] and callbacks[id]["pre_actor_set_dead"] then
        local flag = true
        for _, func in pairs(callbacks[id]["pre_actor_set_dead"]) do
            if func(gm.CInstance.instance_id_to_CInstance[id]) == false then
                flag = false
            end
        end
        return flag
    end
end)

gm.pre_script_hook(gm.constants.damager_attack_process, function(self, other, result, args)
    if callbacks[self.id] and callbacks[self.id]["pre_damager_attack_process"] then
        local flag = true
        for _, func in pairs(callbacks[self.id]["pre_damager_attack_process"]) do
            if func(self, args[1].value, args[2].value) == false then
                flag = false
            end
        end
        if flag == false then
            return flag
        end
    end
    local parent = args[1].value.parent
    if parent and type(parent) ~= "number" then
        if callbacks[parent.id] and callbacks[parent.id]["pre_damager_attack_process_parent"] then
            local flag = true
            for _, func in pairs(callbacks[parent.id]["pre_damager_attack_process_parent"]) do
                if func(args[1].value, args[2].value) == false then
                    flag = false
                end
            end
            return flag
        end
    end
end)
--[[
{ name = 'hit_info' },
{ name = 'target' },
{ name = 'target' },
{ name = 'target_x' },
{ name = 'target_y' },
{ name = 'damage' },
{ name = 'critical' },
{ name = 'hit_list_index' },
{ name = 'is_attack_authority' }
]]
gm.pre_script_hook(gm.constants.damager_hit_process, function(self, other, result, args)
    if self then
        if callbacks[self.id] and callbacks[self.id]["pre_damager_hit_process"] then
            local flag = true
            for _, func in pairs(callbacks[self.id]["pre_damager_hit_process"]) do
                if func(self, args[1].value, args[2].value) == false then
                    flag = false
                end
            end
            args[6].value = args[1].value.damage
            args[7].value = args[1].value.critical
            if flag == false then
                return flag
            end
        end
    end
end)

gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if callbacks[self.id] and callbacks[self.id]["pre_skill_activate"] then
        local flag = true
        for _, func in pairs(callbacks[self.id]["pre_skill_activate"]) do
            if func(self, args[1].value) == false then
                flag = false
            end
        end
        return flag
    end
end)

gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if callbacks[self.id] and callbacks[self.id]["post_skill_activate"] then
        for _, func in pairs(callbacks[self.id]["post_skill_activate"]) do
            -- actor, slot_index
            func(self, args[1].value)
        end
    end
end)

gm.post_script_hook(gm.constants.fire_bullet, function(self, other, result, args)
    if other then
        if callbacks[other.id] and callbacks[other.id]["post_other_fire_bullet"] then
            for _, func in pairs(callbacks[other.id]["post_other_fire_bullet"]) do
                func(self, other, gm.variable_global_get("attack_bullet"))
            end
        end
    end
end)

gm.post_script_hook(gm.constants.fire_direct, function(self, other, result, args)
    if other then
        if callbacks[other.id] and callbacks[other.id]["post_other_fire_direct"] then
            for _, func in pairs(callbacks[other.id]["post_other_fire_direct"]) do
                func(self, other, gm.variable_global_get("attack_bullet"))
            end
        end
    end
end)

gm.post_script_hook(gm.constants.fire_explosion, function(self, other, result, args)
    if other then
        if callbacks[other.id] and callbacks[other.id]["post_other_fire_explosion"] then
            for _, func in pairs(callbacks[other.id]["post_other_fire_explosion"]) do
                func(self, other, gm.variable_global_get("attack_bullet"))
            end
        end
    end
end)

gm.pre_script_hook(gm.constants.actor_activity_set, function(self, other, result, args)
    local player = args[1].value
    if callbacks[player.id] and callbacks[player.id]["pre_actor_activity_set"] then
        local flag = true
        for _, func in pairs(callbacks[player.id]["pre_actor_activity_set"]) do
            -- actor, activity, activity_type, handler_lua, handler_gml, auto_end
            if func(player, args[2].value, args[2].value, args[3].value, args[4].value, args[5].value, args[6].value) ==
                false then
                flag = false
            end
        end
        return flag
    end
end)
memory.dynamic_hook_mid("post_bullet_kill_proc_hook", {"rsp+0AD0h-A60h", "[rbp+9E8h]"}, {"RValue*", "CInstance*"}, 0,
    gm.get_script_function_address(gm.constants.damager_attack_process):add(27333), function(args)
        local bullet_callbacks = callbacks[args[2].id]
        if bullet_callbacks == nil or bullet_callbacks["post_bullet_kill_proc"] == nil then
            if callbacks[args[1].value.id] and callbacks[args[1].value.id]["post_be_kill_proc"] then
                callbacks[args[1].value.id]["post_be_kill_proc"] = nil
            end
            return
        end
        if callbacks[args[1].value.id] == nil then
            callbacks[args[1].value.id] = {}
        end
        callbacks[args[1].value.id]["post_be_kill_proc"] = bullet_callbacks["post_bullet_kill_proc"]
    end)
Callback_ext.add_post_callback(40, "on_all_KillProc_callback", function(self, other, result, args)
    if callbacks[args[2].value.id] and callbacks[args[2].value.id]["post_be_kill_proc"] then
        for _, func in pairs(callbacks[args[2].value.id]["post_be_kill_proc"]) do
            func(args[2].value, args[3].value)
        end
    end
end)

gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    callbacks = {}
end)
