local modifier_pool = {}
local default_weight = 500
local skills_data = {}
local total_weight = 0
SkillModifierManager = {}
---@param modifier_name string The name of modifier being registered. This should be a unique identifier for the modifier.
---@param weight number? The weight of the modifier being registered. The default weight is 500.
SkillModifierManager.register_modifier = function(modifier_name, weight)
    total_weight = total_weight + weight or default_weight
    local modifier = SkillModifier.new(modifier_name, weight or default_weight)
    if not modifier_pool[modifier_name] then
        log.warning("Seems some modifiers have the same name", modifier_name)
    end
    modifier_pool[modifier_name] = modifier
    return modifier
end
SkillModifierManager.get_modifier = function(modifier_name)
    local modifier = modifier_pool[modifier_name]
    if not modifier then
        log.warning("Try to get a non-existent modifier", modifier_name)
    end
    return modifier
end
SkillModifierManager.add_modifier_params = function(skill_params, modifier_name, ...)
    local modifier = SkillModifierManager.get_modifier(modifier_name)
    if not modifier.check_func(skill_params) then
        log.error("Can't add the modifier to this skill" .. modifier_name, 2)
    end
    local params = {...}
    params = #params > 0 and params or {modifier.default_params_func(skill_params)}
    skill_params.ctm_arr_modifiers = skill_params.ctm_arr_modifiers or {}
    table.insert(skill_params.ctm_arr_modifiers, {modifier_name, table.unpack(params)})
end
-- here may cause memory leak, need to solve.
SkillModifierManager.add_modifier = function(skill, modifier_name, ...)
    local modifier = SkillModifierManager.get_modifier(modifier_name)
    if not modifier.check_func(skill) then
        log.error("Can't add the modifier to this skill" .. modifier_name, 2)
    end
    local params = {...}
    params = #params > 0 and params or {modifier.default_params_func(skill)}
    skill.ctm_arr_modifiers = skill.ctm_arr_modifiers or gm.array_create(0, 0)
    local arr_modifier = gm.array_create(1, modifier_name)
    for i = 1, #params do
        gm.array_push(arr_modifier, params[i])
    end
    gm.array_push(skill.ctm_arr_modifiers, arr_modifier)
    local modifier_index = gm.array_length(skill.ctm_arr_modifiers) - 1
    local data = SkillModifierManager.get_or_create_modifier_data(skill, modifier_index)
    modifier.add_func(data, modifier_index, table.unpack(params))
end
SkillModifierManager.remove_modifier = function(skill, modifier_name, modifier_index)
    local modifier = SkillModifierManager.get_modifier(modifier_name)
    local data = SkillModifierManager.get_or_create_modifier_data(skill, modifier_index)
    modifier.remove_func(data, modifier_index)
    SkillModifierManager.clear_modifier_data(skill, modifier_index)
end
SkillModifierManager.get_or_create_modifier_data = function(skill, modifier_index)
    local address = memory.get_usertype_pointer(skill)
    skills_data[address] = skills_data[address] or {}
    skills_data[address][modifier_index] = skills_data[address][modifier_index] or SkillModifierData.new(skill)
    return skills_data[address][modifier_index]
end
SkillModifierManager.clear_modifier_data = function(skill, modifier_index)
    skills_data[memory.get_usertype_pointer(skill)][modifier_index] = nil
end
SkillModifierManager.get_random_modifier_name = function()
    local rand = Utils.get_random(0, total_weight)
    local sum_weight = 0
    for name, modifier in pairs(modifier_pool) do
        sum_weight = sum_weight + modifier.weight
        if rand <= sum_weight then
            return name
        end
    end
end
SkillModifierManager.count_modifier = function(skill, modifier_name)
    local stack = 0
    if skill.ctm_arr_modifiers ~= nil then
        if type(skill) == "table" then
            for _, modifier_data in ipairs(skill.ctm_arr_modifiers) do
                if modifier_data[1] == modifier_name then
                    stack = stack + 1
                end
            end
        elseif type(skill) == "userdata" then
            for i = 0, gm.array_length(skill.ctm_arr_modifiers) - 1 do
                if gm.array_get(gm.array_get(skill.ctm_arr_modifiers, i), 0) == modifier_name then
                    stack = stack + 1
                end
            end
        else
            log.error("Can't count the skill's modifiers" .. modifier_name, 2)
        end
    end
    return stack
end
SkillModifierManager.get_random_modifier_name_with_check = function(skill)
    local random_modifier_name = SkillModifierManager.get_random_modifier_name()
    local random_modifier = modifier_pool[random_modifier_name]
    return random_modifier.check_func(skill) and random_modifier_name or
               SkillModifierManager.get_random_modifier_name_with_check(skill)
end
memory.dynamic_hook_mid("hud_draw_skill_info", {"rax", "rsp+200h-188h"}, {"RValue*", "RValue*"}, 0, {},
    gm.get_script_function_address(gm.constants.hud_draw_skill_info):add(836), function(args)
        if args[2].value.ctm_arr_modifiers ~= nil then
            local modifiers = Array.wrap(args[2].value.ctm_arr_modifiers)
            for i = 0, modifiers:size() - 1 do
                local modifier = modifiers:get(i)
                local modifier_name = modifier:get(0)
                local info_func = SkillModifierManager.get_modifier(modifier_name).info_func
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    modifier_args[j] = modifier:get(j)
                end
                local data = SkillModifierManager.get_or_create_modifier_data(args[2].value, i)
                args[1].value = info_func(args[1].value, data, table.unpack(modifier_args))
            end
        end
    end)
gm.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    skills_data = {}
end)
