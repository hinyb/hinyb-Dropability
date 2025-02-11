InstanceExtRegs = {}
local function table_to_params(t)
    local result = ""
    local count = 1
    local keys_table = t.key
    local params_table = t.value
    for i = 1, #keys_table do
        local value = params_table[i]
        if value == nil then
            value = "args[" .. tostring(count) .. "].value"
            count = count + 1
        end
        result = result .. value .. ", "
    end
    result = string.sub(result, 1, -3)
    return result
end
local callbacks = InstanceExtManager.callbacks
local function compile_parser(t, code_table, callback_name)
    code_table[2] = t[1]
    code_table[4] = callback_name
    code_table[6] = table_to_params(t[2])
    return load(table.concat(code_table), nil, "t", {
        callbacks = callbacks,
        type = type,
        pairs = pairs
    })()
end
local script_code_table = {[[return
    function(self, other, result, args)
        local id = ]], nil, [[.id
        local actor_callbacks = callbacks[id]
        if not actor_callbacks then
            return
        end
        local need_to_interrupt = false
        local callbacks = actor_callbacks.]], nil, [[
        if not callbacks then
            return
        end
        for _, callback in pairs(callbacks) do
            local flag, result_ = callback(]], nil, [[)
            need_to_interrupt = need_to_interrupt or flag == false
            if result_ then
                result.value = result_
            end
        end
        return not need_to_interrupt
    end
    ]]}
local code_code_table = {[[return
    function(self, other)
        local id = ]], nil, [[.id
        local actor_callbacks = callbacks[id]
        if not actor_callbacks then
            return
        end
        local need_to_interrupt = false
        local callbacks = actor_callbacks.]], nil, [[
        if not callbacks then
            return
        end
        for _, callback in pairs(callbacks) do
            local flag = callback(]], nil, [[)
            need_to_interrupt = need_to_interrupt or flag == false
        end
        return not need_to_interrupt
    end
    ]]}

local script_parse_rules = {
    skill_activate = {"self", {
        key = {"actor", "slot_index"},
        value = {"self"}
    }},
    damager_attack_process_client = {"type(args[2].value) == \"number\" and args[2].value or args[2].value", {
        key = {"hit_effect", "attack_flags", "victim", "tracer_kind", "tracer_col", "proc", "critical", "damage",
               "damage_color", "xscale", "x", "y", "rng_seed", "percent_hp", "team", "climb"},
        value = {}
    }},
    actor_set_dead = {"type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "dead"},
        value = {"gm.CInstance.instance_id_to_CInstance[id]"}
    }},
    actor_activity_set = {"type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "activity", "activity_type", "handler_lua", "handler_gml", "auto_end"},
        value = {}
    }},
    other_fire_bullet = {"other", {
        key = {"true_parent", "parent", "bullet"},
        value = {"self", "other", "gm.variable_global_get(\"attack_bullet\")"}
    }},
    other_fire_direct = {"other", {
        key = {"true_parent", "parent", "bullet"},
        value = {"self", "other", "gm.variable_global_get(\"attack_bullet\")"}
    }},
    other_fire_explosion = {"other", {
        key = {"true_parent", "parent", "bullet"},
        value = {"self", "other", "gm.variable_global_get(\"attack_bullet\")"}
    }},
    attack_collision_resolve = {"self", {
        key = {"bullet", "target"},
        value = {"self"}
    }}
}

HookSystem.clean_hook()
function InstanceExtRegs.register_script_callback(script_index, callback_name, is_pre, t)
    local hook_fn = is_pre and HookSystem.pre_script_hook or HookSystem.post_script_hook
    local callback_name_ = (is_pre and "pre_" or "post_") .. callback_name
    InstanceExtManager.enable_callback(callback_name_)
    hook_fn(script_index, compile_parser(t or script_parse_rules[callback_name], script_code_table, callback_name_))
end
InstanceExtRegs.register_script_callback(gm.constants.skill_activate, "skill_activate", true)
InstanceExtRegs.register_script_callback(gm.constants.skill_activate, "skill_activate", false)
InstanceExtRegs.register_script_callback(gm.constants.damager_attack_process_client, "damager_attack_process_client",
    true)
InstanceExtRegs.register_script_callback(gm.constants.fire_bullet, "other_fire_bullet", false)
InstanceExtRegs.register_script_callback(gm.constants.fire_direct, "other_fire_direct", false)
InstanceExtRegs.register_script_callback(gm.constants.fire_explosion, "other_fire_explosion", false)
InstanceExtRegs.register_script_callback(gm.constants.actor_set_dead, "actor_set_dead", true)
InstanceExtRegs.register_script_callback(gm.constants.actor_activity_set, "actor_activity_set", true)
InstanceExtRegs.register_script_callback(gm.constants.attack_collision_resolve, "attack_collision_resolve", true)

local code_parse_rules = {
    -- gml_Object_oP_Other_15 --
    player_level_up = {"self", {
        key = {"actor"},
        value = {"self"}
    }}
}

function InstanceExtRegs.register_code_callback(code_name, callback_name, is_pre, t)
    local hook_fn = is_pre and HookSystem.pre_code_execute or HookSystem.post_code_execute
    local callback_name_ = (is_pre and "pre_" or "post_") .. callback_name
    InstanceExtManager.enable_callback(callback_name_)
    hook_fn(code_name, compile_parser(t or code_parse_rules[callback_name], code_code_table, callback_name_))
end
InstanceExtRegs.register_code_callback("gml_Object_oP_Other_15", "player_level_up", true)
