-- This might be unnecessary.
-- But since I've already written it, I'll keep it.
-- need time to improve it.
-- hit can only change damage, damage_info should be changed at attack.
local skill_captrue_callbacks = {}
function InstanceExtManager.add_skill_instance_captrue(actor, slot_index, name, deal_func)
    local new_to_create_flag = false
    if skill_captrue_callbacks[actor.id] == nil then
        skill_captrue_callbacks[actor.id] = {}
        new_to_create_flag = true
    end
    if skill_captrue_callbacks[actor.id][slot_index] == nil then
        skill_captrue_callbacks[actor.id][slot_index] = {}
        new_to_create_flag = true
    end
    skill_captrue_callbacks[actor.id][slot_index][name] = deal_func
    if new_to_create_flag then
        InstanceExtManager.add_skill_instance_captrue_internal(actor, slot_index)
    end
end
function InstanceExtManager.remove_skill_instance_captrue(actor, slot_index, name)
    if name then
        skill_captrue_callbacks[actor.id][slot_index][name] = nil
    else
        skill_captrue_callbacks[actor.id][slot_index] = {}
    end
    if Utils.table_get_length(skill_captrue_callbacks[actor.id][slot_index]) == 0 then
        skill_captrue_callbacks[actor.id][slot_index] = nil
        local name = "skill_instance_captrue" .. Utils.to_string_with_floor(slot_index)
        InstanceExtManager.remove_callback(actor, "pre_skill_activate", name)
        InstanceExtManager.remove_callback(actor, "post_skill_activate", name)
        if Utils.table_get_length(skill_captrue_callbacks[actor.id]) == 0 then
            skill_captrue_callbacks[actor.id] = nil
        end
    end
end
function InstanceExtManager.add_skill_instance_captrue_internal(actor, slot_index)
    local last_activity_state = 0
    local name = "skill_instance_captrue" .. Utils.to_string_with_floor(slot_index)
    local callback_packs = skill_captrue_callbacks[actor.id][slot_index]
    local deal_func = function(inst)
        for _, deal_func in pairs(callback_packs) do
            deal_func(inst)
        end
    end
    InstanceExtManager.add_callback(actor, "pre_skill_activate", name, function(actor, slot_index_)
        if slot_index_ ~= slot_index then
            return
        end
        Utils.hook_instance_create({gm.constants.oActorTargetEnemy, gm.constants.oActorTargetPlayer})
        last_activity_state = actor.__activity_handler_state
    end)
    InstanceExtManager.add_callback(actor, "post_skill_activate", name, function(actor, slot_index_)
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
                InstanceExtManager.add_callback(actor, "pre_actor_activity_set", name, function()
                    Callable_call.remove_capture_instance(script_name, name .. Utils.to_string_with_floor(actor.id))
                    InstanceExtManager.remove_callback(actor, "pre_actor_activity_set", name)
                end)
            end
        end
        local state_array = Class.ActorState:get(actor.actor_state_current_id)
        if state_array then
            local check_func = function(self, other, result, args)
                return args[2].value == actor
            end
            local name = name .. Utils.to_string_with_floor(actor.id)
            -- For HuntressC2, which uses two states: HuntressC2Draw and HuntressC2Fire.
            InstanceExtManager.add_callback(actor, "pre_actor_set_state", "pre_actor_set_state_for_skill_bullet",
                function(actor, state_id)
                    local state_array = Class.ActorState:get(state_id)
                    if not state_array then
                        return
                    end
                    Callback_ext.add_capture_instance(state_array:get(2), name, deal_func, check_func)
                    Callback_ext.add_capture_instance(state_array:get(4), name, deal_func, check_func)
                    Callback_ext.add_capture_instance(state_array:get(3), name, deal_func, check_func, nil, function()
                        Callback_ext.remove_capture_instance(state_array:get(2), name)
                        Callback_ext.remove_capture_instance(state_array:get(4), name)
                        Callback_ext.remove_capture_instance(state_array:get(3), name)
                    end)
                end)
            Callback_ext.add_capture_instance(state_array:get(2), name, deal_func, check_func)
            Callback_ext.add_capture_instance(state_array:get(4), name, deal_func, check_func)
            Callback_ext.add_capture_instance(state_array:get(3), name, deal_func, check_func, nil, function()
                InstanceExtManager.remove_callback(actor, "pre_actor_set_state", "pre_actor_set_state_for_skill_bullet")
                Callback_ext.remove_capture_instance(state_array:get(2), name)
                Callback_ext.remove_capture_instance(state_array:get(4), name)
                Callback_ext.remove_capture_instance(state_array:get(3), name)
            end)
        end
    end)
    gm.event_hook_post_add(actor, gm.constants.ev_destroy, 0, name, function (actor)
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
-- Maybe the filtering logic should be separated.
function InstanceExtManager.add_skill_bullet_captrue_local(actor, slot_index, name, deal_func)
    InstanceExtManager.add_skill_instance_captrue(actor, slot_index, name, function(inst)
        if bullet_list[inst.object_index] then
            deal_func(inst)
            return
        end
        if black_list[inst.object_index] then
            return
        end
        if string.sub(inst.object_name, 1, 3) == "oEf" and inst.object_index ~= gm.constants.oEfAcidBubble then
            return
        end
        if not inst.parent then
            return
        end
        local inst_parent = Utils.get_inst_safe(inst.parent)
        if inst_parent.object_index == gm.constants.oP then
            InstanceExtManager.add_post_other_fire(inst, name, function(self, other, bullet)
                deal_func(bullet)
            end)
            return
        end
    end)
end

function InstanceExtManager.add_skill_instance_captrue_local_with_filter(actor, slot_index, name, deal_func)
    InstanceExtManager.add_skill_instance_captrue(actor, slot_index, name, function(inst)
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
            deal_func(inst)
        end
    end)
end

-- 
-- damager_attack_process client_send_message proc_server damager_attack_process damager_hit_process -- client
-- bullet only sync attack_info

-- this function need to be called at all sides, and only trigger at host side.
function InstanceExtManager.add_skill_bullet_callback(actor, slot_index, name, callback_id, deal_func)
    if not attack_info_table[callback_id] then
        log.error("try to add a non-existed skill_bullet_callback", 2)
    end
    local attack_info_name = Utils.to_string_with_floor(actor.id) .. name
    InstanceExtManager.add_skill_bullet_captrue_local(actor, slot_index, name .. callback_id, function(attack)
        attack_info_add_callback(attack.attack_info, callback_id, attack_info_name)
    end)
    gm.event_hook_post_add(actor, gm.constants.ev_destroy, 0, name, function(attack)
        attack_info_callbacks[attack_info_name] = nil
    end)
    if attack_info_callbacks[attack_info_name] == nil then
        attack_info_callbacks[attack_info_name] = {}
    end
    attack_info_callbacks[attack_info_name][callback_id] = deal_func
end

function InstanceExtManager.remove_skill_bullet_callback(actor, slot_index, name, callback_id)
    local attack_info_name = Utils.to_string_with_floor(actor.id) .. name
    if callback_id == nil then
        attack_info_callbacks[attack_info_name] = nil
        InstanceExtManager.remove_skill_instance_captrue(actor, slot_index)
    else
        if not attack_info_table[callback_id] then
            log.error("try to remove a non-existed skill_bullet_callback", 2)
        end
        InstanceExtManager.remove_skill_instance_captrue(actor, slot_index, name .. callback_id)
        attack_info_callbacks[attack_info_name][callback_id] = nil
        if Utils.table_get_length(attack_info_callbacks[attack_info_name]) == 0 then
            attack_info_callbacks[attack_info_name] = nil
        end
    end
end

-- just copied the damager_attack_process, I'm not sure if it will work.
-- This runs on both the client and server, but when the server's damager_attack_process changes, the client will be synced.
-- This should only call on local.
function InstanceExtManager.add_skill_bullet_fake_hit_actually_attack(actor, slot_index, name, deal_func)
    InstanceExtManager.add_skill_bullet_callback(actor, slot_index, name, "attack",
        function(attack_info, hit_list, max_index)
            for i = 0, max_index - 1, 3 do
                local hit_target = gm.ds_list_find_value(hit_list, i)
                if lua_type(hit_target) ~= "number" then
                    if Instance.exists(hit_target) then
                        if hit_target:hit_should_count_towards_total_hit_number_client_and_server() then
                            if hit_target:object_is(hit_target, 344) then
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
        end)
end

HookSystem.clean_hook()
HookSystem.post_script_hook(gm.constants.write_attackinfo, function(self, other, result, args)
    local attack_info = args[1].value
    local bit_array = 0
    for i = 1, #attack_info_table_order do
        local type = attack_info_table_order[i]
        local attack_info_callbacks_ = attack_info["attack_info_callbacks_" .. type]
        if attack_info_callbacks_ then
            bit_array = bit_array | (1 << (i - 1))
        end
    end
    self:writebyte(bit_array)
    for i = 1, #attack_info_table_order do
        local type = attack_info_table_order[i]
        local attack_info_callbacks_ = attack_info["attack_info_callbacks_" .. type]
        if attack_info_callbacks_ then
            local table = Utils.create_table_from_array(attack_info_callbacks_)
            self:writestring(Utils.simple_table_to_string(table))
        end
    end
end)

HookSystem.post_script_hook(gm.constants.read_attackinfo, function(self, other, result, args)
    local bit_array = self:readbyte()
    for i = 1, #attack_info_table_order do
        local sign = (bit_array >> (i - 1)) & 1
        if sign == 1 then
            local type = attack_info_table_order[i]
            local table = Utils.simple_string_to_table(self:readstring())
            result.value["attack_info_callbacks_" .. type] = Utils.create_array_from_table(table)
        end
    end
end)

HookSystem.pre_script_hook(gm.constants.damager_attack_process, function(self, other, result, args)
    local attack_info_callbacks_attack = args[1].value.attack_info_callbacks_attack
    if attack_info_callbacks_attack then
        local callbacks_wrapped = Array.wrap(attack_info_callbacks_attack)
        local flag = true
        for i = 0, callbacks_wrapped:size() - 1 do
            local attack_info_callbacks_ = attack_info_callbacks[callbacks_wrapped:get(i)]
            if attack_info_callbacks_ and attack_info_callbacks_["attack"] then
                local flag_, result_ = attack_info_callbacks_["attack"](args[1].value, args[2].value, args[3].value)
                if flag_ == false then
                    flag = false
                end
                if result_ then
                    result.value = result_
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
HookSystem.pre_script_hook(gm.constants.damager_hit_process, function(self, other, result, args)
    local attack_info_callbacks_hit = args[1].value.attack_info_callbacks_hit
    if attack_info_callbacks_hit then
        local callbacks_wrapped = Array.wrap(attack_info_callbacks_hit)
        local flag = true
        for i = 0, callbacks_wrapped:size() - 1 do
            local attack_info_callbacks_ = attack_info_callbacks[callbacks_wrapped:get(i)]
            if attack_info_callbacks_ and attack_info_callbacks_["hit"] then
                local flag_, result_ = attack_info_callbacks_["hit"](args[1].value, args[2].value)
                if flag_ == false then
                    flag = false
                end
                if result_ then
                    result.value = result_
                end
            end
        end
        args[6].value = args[1].value.damage
        args[7].value = args[1].value.critical
        return flag
    end
end)

local callbacks = InstanceExtManager.callbacks
memory.dynamic_hook_mid("post_bullet_kill_proc_hook", {"[r13]", "rbp+0B50h-BD0h"}, {"RValue*", "RValue*"}, 0,
    gm.get_script_function_address(gm.constants.damager_attack_process):add(31305), function(args)
        local victim = Utils.get_inst_safe(args[2].value)
        if not victim then
            return
        end
        if callbacks[victim.id] and callbacks[victim.id]["post_be_kill_proc"] then
            callbacks[victim.id]["post_be_kill_proc"] = nil
        end
        local attack_info = args[1].value
        local attack_info_callbacks_kill = attack_info.attack_info_callbacks_kill
        if attack_info_callbacks_kill then
            if callbacks[victim.id] == nil then
                callbacks[victim.id] = {}
            end
            if callbacks[victim.id]["post_be_kill_proc"] == nil then
                callbacks[victim.id]["post_be_kill_proc"] = {}
            end
            local callbacks_wrapped = Array.wrap(attack_info_callbacks_kill)
            for i = 0, callbacks_wrapped:size() - 1 do
                local attack_info_callbacks_ = attack_info_callbacks[callbacks_wrapped:get(i)]
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
