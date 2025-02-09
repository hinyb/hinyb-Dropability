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
        result = result .. key .. " = " .. value .. ", "
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
                                      'percent_hp', "team", 'climb'}}
}
InstanceExtManager.register_script_callback(gm.constants.skill_activate, "skill_activate",
    compile_parser(parse_rules.skill_activate))
InstanceExtManager.register_script_callback(gm.constants.damager_attack_process_client, "damager_attack_process_client",
    compile_parser(parse_rules.damager_attack_process_client))