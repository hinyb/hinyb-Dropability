Instance_ext = {}
local callbacks = {}
local callbacks_check_table = {
    pre_destroy = true,
    post_local_drop = true,
    post_local_pickup = true,
    pre_damager_attack_process = true,
    pre_actor_death_after_hippo = true,
    pre_actor_set_dead = true,
    pre_skill_activate = true,
    post_skill_activate = true,
    pre_actor_activity_set = true,
    post_other_fire_explosion = true,
    post_other_fire_direct = true,
    post_other_fire_bullet = true,
    post_bullet_kill_proc = true,
    pre_damager_hit_process = true,
    pre_player_level_up = true
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

-- This might be unnecessary.
-- But since I've already written it, I'll keep it.
local skill_captrue_callbacks = {}
function Instance_ext.add_skill_instance_captrue(actor, slot_index, name, deal_func, pre_func, post_func)
    local new_to_create_flag = false
    if skill_captrue_callbacks[actor.id] == nil then
        skill_captrue_callbacks[actor.id] = {}
        new_to_create_flag = true
    end
    if skill_captrue_callbacks[actor.id][slot_index] == nil then
        skill_captrue_callbacks[actor.id][slot_index] = {}
        new_to_create_flag = true
    end
    skill_captrue_callbacks[actor.id][slot_index][name] = {
        deal_func = deal_func,
        pre_func = pre_func,
        post_func = post_func
    }
    if new_to_create_flag then
        Instance_ext.add_skill_instance_captrue_internal(actor, slot_index)
    end
end
function Instance_ext.remove_skill_instance_captrue(actor, slot_index, name)
    if name then
        skill_captrue_callbacks[actor.id][slot_index][name] = nil
    else
        skill_captrue_callbacks[actor.id][slot_index] = {}
    end
    if Utils.table_get_length(skill_captrue_callbacks[actor.id][slot_index]) == 0 then
        skill_captrue_callbacks[actor.id][slot_index] = nil
        local name = "skill_instance_captrue" .. Utils.to_string_with_floor(slot_index)
        Instance_ext.remove_callback(actor, "pre_skill_activate", name)
        Instance_ext.remove_callback(actor, "post_skill_activate", name)
        if Utils.table_get_length(skill_captrue_callbacks[actor.id]) == 0 then
            skill_captrue_callbacks[actor.id] = nil
        end
    end
end
function Instance_ext.add_skill_instance_captrue_internal(actor, slot_index)
    local last_activity_state = 0
    local name = "skill_instance_captrue" .. Utils.to_string_with_floor(slot_index)
    local callback_packs = skill_captrue_callbacks[actor.id][slot_index]
    local deal_func = function(inst)
        for _, callback_pack in pairs(callback_packs) do
            callback_pack.deal_func(inst)
        end
    end
    local pre_func = function(actor, slot_index)
        local do_skip = false
        for _, callback_pack in pairs(callback_packs) do
            if callback_pack.pre_func then
                do_skip = do_skip or callback_pack.pre_func(actor, slot_index) == false
            end
        end
        return not do_skip
    end
    local post_func = function(actor, slot_index)
        for _, callback_pack in pairs(callback_packs) do
            if callback_pack.post_func then
                callback_pack.post_func(actor, slot_index)
            end
        end
    end
    Instance_ext.add_callback(actor, "pre_skill_activate", name, function(actor, slot_index_)
        if slot_index_ ~= slot_index then
            return
        end
        Utils.hook_instance_create({gm.constants.oActorTargetEnemy, gm.constants.oActorTargetPlayer})
        last_activity_state = actor.__activity_handler_state
        return pre_func(actor, slot_index)
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
                Callable_call.add_capture_instance(script_name, name .. Utils.to_string_with_floor(actor.id), deal_func,
                    check_func)
                Instance_ext.add_callback(actor, "pre_actor_activity_set", name, function()
                    Callable_call.remove_capture_instance(script_name, name .. Utils.to_string_with_floor(actor.id))
                    Instance_ext.remove_callback(actor, "pre_actor_activity_set", name)
                end)
            end
        end
        local state_array = Class.Actor_State:get(actor.actor_state_current_id)
        if state_array then
            local check_func = function(self, other, result, args)
                return args[2].value == actor
            end
            local name = name .. Utils.to_string_with_floor(actor.id)
            Callback_ext.add_capture_instance(state_array:get(2), name, deal_func, check_func)
            Callback_ext.add_capture_instance(state_array:get(4), name, deal_func, check_func)
            Callback_ext.add_capture_instance(state_array:get(3), name, deal_func, check_func, nil, function()
                Callback_ext.remove_capture_instance(state_array:get(2), name)
                Callback_ext.remove_capture_instance(state_array:get(4), name)
                Callback_ext.remove_capture_instance(state_array:get(3), name)
            end)
        end
        post_func(actor, slot_index)
    end)
    Instance_ext.add_callback(actor, "pre_destroy", name, function(actor)
        skill_captrue_callbacks[actor.id] = nil
    end)
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

local attack_info_callbacks = {}
local attack_info_table_order = {"attack", "hit", "kill"}
local attack_info_table = {}
for i = 1, #attack_info_table_order do
    attack_info_table[attack_info_table_order[i]] = true
end
local function attack_info_add_callback(attack_info, type, name)
    if attack_info["attack_info_callbacks_" .. type] == nil then
        attack_info["attack_info_callbacks_" .. type] = gm.array_create(0, 0)
    end
    gm.array_push(attack_info["attack_info_callbacks_" .. type], name)
end
function Instance_ext.add_skill_bullet_captrue_local(actor, slot_index, name, deal_func, pre_func, post_func)
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

-- damager_attack_process client_send_message proc_server damager_attack_process damager_hit_process
-- bullet only sync attack_info

-- this function need to be called at all sides, and only trigger at host side.
function Instance_ext.add_skill_bullet_callback(actor, slot_index, name, callback_id, deal_func, pre_func, post_func)
    if not attack_info_table[callback_id] then
        log.error("try to add a non-existed skill_bullet_callback", 2)
    end
    Instance_ext.add_skill_bullet_captrue_local(actor, slot_index, name .. callback_id, function(attack)
        attack_info_add_callback(attack.attack_info, callback_id, name)
    end, pre_func, post_func)
    Instance_ext.add_callback(actor, "pre_destroy", name, function(attack)
        attack_info_callbacks[name] = nil
    end)
    if attack_info_callbacks[name] == nil then
        attack_info_callbacks[name] = {}
    end
    attack_info_callbacks[name][callback_id] = deal_func
end

function Instance_ext.remove_skill_bullet_callback(actor, slot_index, name, callback_id)
    if callback_id == nil then
        attack_info_callbacks[name] = nil
        Instance_ext.remove_skill_instance_captrue(actor, slot_index)
    else
        if not attack_info_table[callback_id] then
            log.error("try to remove a non-existed skill_bullet_callback", 2)
        end
        Instance_ext.remove_skill_instance_captrue(actor, slot_index, name .. callback_id)
        attack_info_callbacks[name][callback_id] = nil
        if Utils.table_get_length(attack_info_callbacks[name]) == 0 then
            attack_info_callbacks[name] = nil
        end
    end
end

-- just copied the damager_attack_process, I'm not sure if it will work.
-- this is both sides.
function Instance_ext.add_skill_bullet_fake_hit_actually_attack(actor, slot_index, name, deal_func, pre_func, post_func)
    Instance_ext.add_skill_bullet_callback(actor, slot_index, name, "attack", function(attack_info, hit_list)
        for i = 0, gm.ds_list_size(hit_list) - 1, 3 do
            local hit_target = gm.ds_list_find_value(hit_list, i)
            if type(hit_target) ~= "number" then
                if Instance.exists(hit_target) then
                    if hit_target:hit_should_count_towards_total_hit_number_client_and_server() then
                        if gm.call("gml_Script_object_is", hit_target, hit_target, hit_target, 344) then
                            if hit_target:attack_collision_resolve() ~= -4 then
                                deal_func(attack_info, hit_target)
                            end
                        else
                            deal_func(attack_info, hit_target)
                        end
                    end
                end
            end
        end
    end, pre_func, post_func)
end

function Instance_ext.add_callback(self, callback, name, fn)
    if not callbacks_check_table[callback] then
        log.error("Can't add Instance_ext callback", 2)
    end
    if callback == "pre_player_level_up" then
        if self.object_index ~= gm.constants.oP then
            log.error("Can't add a player callback to non-player", 2)
        end
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

gm.post_script_hook(gm.constants.write_attackinfo, function(self, other, result, args)
    local attack_info = args[1].value
    for i = 1, #attack_info_table_order do
        local type = attack_info_table_order[i]
        local attack_info_callbacks_ = attack_info["attack_info_callbacks_" .. type]
        if attack_info_callbacks_ then
            self:writesign(true)
            local table = Utils.create_table_from_array(attack_info_callbacks_)
            self:writestring(Utils.simple_table_to_string(table))
        else
            self:writesign(false)
        end
    end
end)

gm.post_script_hook(gm.constants.read_attackinfo, function(self, other, result, args)
    for i = 1, #attack_info_table_order do
        local type = attack_info_table_order[i]
        local sign = self:readsign()
        if sign ~= 0 then
            local table = Utils.simple_string_to_table(self:readstring())
            result.value["attack_info_callbacks_" .. type] = Utils.create_array_from_table(table)
        end
    end
end)

gm.pre_script_hook(gm.constants.damager_attack_process, function(self, other, result, args)
    local attack_info_callbacks_attack = args[1].value.attack_info_callbacks_attack
    if attack_info_callbacks_attack then
        log.info(args[1].value.attack_info_callbacks_hit, "attack")
        local callbacks_warpped = Array.wrap(attack_info_callbacks_attack)
        local flag = true
        for i = 0, callbacks_warpped:size() - 1 do
            local attack_info_callbacks_ = attack_info_callbacks[callbacks_warpped:get(i)]
            if attack_info_callbacks_ and attack_info_callbacks_["attack"] then
                if attack_info_callbacks_["attack"](args[1].value, args[2].value) == false then
                    flag = false
                end
            end
        end
        return flag
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
    local attack_info_callbacks_hit = args[1].value.attack_info_callbacks_hit
    if attack_info_callbacks_hit then
        local callbacks_warpped = Array.wrap(attack_info_callbacks_hit)
        local flag = true
        for i = 0, callbacks_warpped:size() - 1 do
            local attack_info_callbacks_ = attack_info_callbacks[callbacks_warpped:get(i)]
            if attack_info_callbacks_ and attack_info_callbacks_["hit"] then
                if attack_info_callbacks_["hit"](args[1].value, args[2].value) == false then
                    flag = false
                end
            end
        end
        args[6].value = args[1].value.damage
        args[7].value = args[1].value.critical
        return flag
    end
end)

memory.dynamic_hook_mid("post_bullet_kill_proc_hook", {"[rbp+9D0h-A10h]", "rsp+0AD0h-A60h"}, {"RValue**", "RValue*"}, 0,
    gm.get_script_function_address(gm.constants.damager_attack_process):add(27333), function(args)
        local victim = args[2].value
        if callbacks[victim.id] and callbacks[victim.id]["post_be_kill_proc"] then
            callbacks[victim.id]["post_be_kill_proc"] = nil
        end
        local attack_info = memory.resolve_pointer_to_type(args[1]:deref():get_address(), "RValue*").value
        local attack_info_callbacks_kill = attack_info.attack_info_callbacks_kill
        if attack_info_callbacks_kill then
            if callbacks[victim.id] == nil then
                callbacks[victim.id] = {}
            end
            if callbacks[victim.id]["post_be_kill_proc"] == nil then
                callbacks[victim.id]["post_be_kill_proc"] = {}
            end
            local callbacks_warpped = Array.wrap(attack_info_callbacks_kill)
            for i = 0, callbacks_warpped:size() - 1 do
                local attack_info_callbacks_ = attack_info_callbacks[callbacks_warpped:get(i)]
                if attack_info_callbacks_ and attack_info_callbacks_["kill"] then
                    table.insert(callbacks[victim.id]["post_be_kill_proc"], attack_info_callbacks_["kill"])
                end
            end
        end
    end)
Callback_ext.add_post_callback(40, "on_all_KillProc_callback", function(self, other, result, args)
    local victim = args[2].value
    if callbacks[victim.id] and callbacks[victim.id]["post_be_kill_proc"] then
        for _, func in pairs(callbacks[victim.id]["post_be_kill_proc"]) do
            func(victim, args[3].value)
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
gm.pre_code_execute("gml_Object_oP_Other_15", function(self, other)
    local player = self
    if callbacks[player.id] and callbacks[player.id]["pre_player_level_up"] then
        local flag = true
        for _, func in pairs(callbacks[player.id]["pre_player_level_up"]) do
            if func(player) == false then
                flag = false
            end
        end
        return flag
    end
end)

gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    callbacks = {}
end)
