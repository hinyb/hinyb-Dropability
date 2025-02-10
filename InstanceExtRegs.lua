local function table_to_string(tbl)
    local result = "{"
    local count = 1
    for k, v in pairs(tbl) do
        local key = k
        local value = v
        if type(k) ~= "string" then
            key = v
            value = "args[" .. tostring(count) .. "].value"
            count = count + 1
        end
        result = result .. value .. ", "
        -- result = result .. key .. " = " .. value .. ", "
    end
    result = string.sub(result, 1, -3)
    result = result .. "}"
    return result
end
local function compile_parser(table)
    local code = "return function(self, other, result, args) return " .. table[1] .. ".id, " ..
                     table_to_string(table[2]) .. " end)"
    return load(code)()
end

local parse_rules = {
    skill_activate = {"self", {
        actor = "self",
        "slot_index"
    }},
    damager_attack_process_client = {"self",
                                     {"hit_effect", "attack_flags", "victim", "tracer_kind", "tracer_col", "proc",
                                      "critical", "damage", "damage_color", "xscale", "x", 'y', "rng_seed",
                                      'percent_hp', "team", 'climb'}},
    actor_set_dead = {"type(args[1].value) == \"number\" and args[1].value or args[1].value", {"actor", "dead"}},
    actor_activity_set = {"type(args[1].value) == \"number\" and args[1].value or args[1].value",
                          {"actor", "activity", "activity_type", "handler_lua", "handler_gml", "auto_end"}},
    other_fire_bullet = {"other", {
        true_parent = "self",
        parent = "other",
        bullet = "gm.variable_global_get(\"attack_bullet\")"
    }},
    other_fire_direct = {"other", {
        true_parent = "self",
        parent = "other",
        bullet = "gm.variable_global_get(\"attack_bullet\")"
    }},
    other_fire_explosion = {"other", {
        true_parent = "self",
        parent = "other",
        bullet = "gm.variable_global_get(\"attack_bullet\")"
    }},
    attack_collision_resolve = {"self", {
        bullet = "self",
        "target"
    }}
}
InstanceExtManager.register_script_callback(gm.constants.skill_activate, "skill_activate",
    compile_parser(parse_rules.skill_activate))
InstanceExtManager.register_script_callback(gm.constants.damager_attack_process_client, "damager_attack_process_client",
    compile_parser(parse_rules.damager_attack_process_client))
InstanceExtManager.register_script_callback(gm.constants.fire_bullet, "other_fire_bullet",
    compile_parser(parse_rules.other_fire_bullet))
InstanceExtManager.register_script_callback(gm.constants.fire_direct, "other_fire_direct",
    compile_parser(parse_rules.other_fire_direct))
InstanceExtManager.register_script_callback(gm.constants.fire_explosion, "other_fire_explosion",
    compile_parser(parse_rules.other_fire_explosion))
