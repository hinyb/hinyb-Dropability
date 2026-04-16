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
    local env = setmetatable({
        callbacks = callbacks
    }, {
        __index = envy.getfenv()
    })
    code_table[2] = t[3] or ""
    code_table[4] = t[1]
    code_table[6] = callback_name
    code_table[8] = table_to_params(t[2])
    return load(table.concat(code_table), nil, "t", env)()
end
local script_code_table = {[[return
    function(self, other, result, args)
        ]], nil, [[
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
        ]], nil, [[
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
    }, "if not self then return end"},
    damager_attack_process_client = {"lua_type(args[3].value) == \"number\" and args[3].value or args[3].value", {
        key = {"hit_effect", "attack_flags", "victim", "tracer_kind", "tracer_col", "proc", "critical", "damage",
               "damage_color", "xscale", "x", "y", "rng_seed", "percent_hp", "team", "climb"},
        value = {}
    }},
    actor_set_dead = {"lua_type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "dead"},
        value = {"gm.CInstance.instance_id_to_CInstance[id]"}
    }},
    actor_activity_set = {"lua_type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "activity", "activity_type", "handler_lua", "handler_gml", "auto_end"},
        value = {}
    }},
    other_fire_bullet = {"other", {
        key = {"true_parent", "parent", "bullet"},
        value = {"self", "other", "gm.variable_global_get(\"attack_bullet\")"}
    }, "if not other then return end"},
    other_fire_direct = {"other", {
        key = {"true_parent", "parent", "bullet"},
        value = {"self", "other", "gm.variable_global_get(\"attack_bullet\")"}
    }, "if not other then return end"},
    other_fire_explosion = {"other", {
        key = {"true_parent", "parent", "bullet"},
        value = {"self", "other", "gm.variable_global_get(\"attack_bullet\")"}
    }, "if not other then return end"},
    attack_collision_resolve = {"self", {
        key = {"bullet", "target"},
        value = {"self"}
    }, "if not self then return end"},
    actor_phy_move = {"self", {
        key = {"actor"},
        value = {"self"}
    }, "if not self then return end"},
    damage_inflict_raw = {"lua_type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"target", "hit_info"},
        value = {}
    }},
    actor_skill_set = {"lua_type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "slot_index", "skill_id"},
        value = {}
    }},
    -- I can't find a better way to solve it.
    -- maybe just interrupt it, and recall it.
    damage_inflict_internal_deduct_hp = {"self", {
        key = {"victim", "source", "damage", "doEffects"},
        value = {"self", "other", "args[1], args[2]"}
    }, "if not self then return end"},
    recalculate_stats = {"self", {
        key = {"actor"},
        value = {"self"}
    }, "if not self then return end"},
    apply_buff = {"lua_type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "buff_id", "time", "stack_value"},
        value = {}
    }},
    actor_set_state = {"lua_type(args[1].value) == \"number\" and args[1].value or args[1].value", {
        key = {"actor", "state_id"},
        value = {}
    }}
}
--[[
damage_inflict
0 target 0
1 damage 0
2 some_flags 0
-- 1<<0 ignore_armor
-- 1<<1 non-faltal
-- 1<<2 break_shield
-- 1<<3 ignore_invincibility
3 kill_parent -4
4 x 0
5 y 0
6 damage_true damage
7 draw_damage_networked arg6  0
8 damage_color 0xffffff
9 critical 0
10 attack_info_x x
11 attack_info_y y
12 sparks_sprite -1
]]
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
InstanceExtRegs.register_script_callback(gm.constants.actor_phy_move, "actor_phy_move", false)
InstanceExtRegs.register_script_callback(gm.constants.damage_inflict_raw, "damage_inflict_raw", true)
InstanceExtRegs.register_script_callback(gm.constants.actor_skill_set, "actor_skill_set", false)
InstanceExtRegs.register_script_callback(gm.constants.damage_inflict_internal_deduct_hp,
    "damage_inflict_internal_deduct_hp", true)
InstanceExtRegs.register_script_callback(gm.constants.recalculate_stats, "recalculate_stats", false)
InstanceExtRegs.register_script_callback(gm.constants.apply_buff, "apply_buff", true)
InstanceExtRegs.register_script_callback(gm.constants.actor_set_state, "actor_set_state", true)


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
