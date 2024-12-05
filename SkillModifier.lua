SkillModifier = {}
-- Maybe it's better to use object-oriented approach.
-- I used to think it was very easy to develop. Now it is absolutely a disaster.
local modifiers_add_func = {}
local modifiers_remove_func = {}
local modifiers_info_func = {}
local modifiers_params_func = {}
local modifiers_weight = {}
local total_weight = 0
local skills_data = {}
SkillModifier.get_random_modifier = function()
    local rand = Utils.get_random() * total_weight
    local sum_weight = 0
    for name, weight in pairs(modifiers_weight) do
        sum_weight = sum_weight + weight
        if rand <= sum_weight then
            return name
        end
    end
end
SkillModifier.change_attr = function(skill, attr_str, modifier_data, new_value)
    if modifier_data["skills_attr"] == nil then
        modifier_data["skills_attr"] = {}
    end
    if type(new_value) == "boolean" then
        modifier_data["skills_attr"][attr_str] = new_value
    else
        modifier_data["skills_attr"][attr_str] = new_value - skill[attr_str]
    end
    skill[attr_str] = new_value
end
SkillModifier.change_attr_func = function(skill, attr_str, modifier_data, new_value)
    if modifier_data["skills_attr"] == nil then
        modifier_data["skills_attr"] = {}
    end
    modifier_data["skills_attr"][attr_str] = new_value
    skill[attr_str] = new_value(skill[attr_str])
end
SkillModifier.restore_attr = function(skill, attr_str, modifier_data, new_value)
    modifier_data["skills_attr"][attr_str] = nil
    skill[attr_str] = new_value
    if new_value == nil then
        gm.get_script_ref(102397)(skill, skill.parent)
    end
end
SkillModifier.add_modifier_param = function(skill_params, modifier_name, ...)
    local fake_skill = Utils.warp_skill(skill_params.skill_id)
    if skill_params.ctm_arr_modifiers == nil then
        skill_params.ctm_arr_modifiers = {}
    end
    local modifier_data = {modifier_name}
    if select("#", ...) > 0 then
        for _, param in ipairs({...}) do
            table.insert(modifier_data, param)
        end
    else
        local params = modifiers_params_func[modifier_name] and
                           table.pack(modifiers_params_func[modifier_name](fake_skill)) or {}
        if #params > 0 then
            for _, param in ipairs(params) do
                table.insert(modifier_data, param)
            end
        end
    end
    table.insert(skill_params.ctm_arr_modifiers, modifier_data)
end
SkillModifier.add_modifier = function(skill, modifier_name, ...)
    if select("#", ...) > 0 then
        SkillModifier.add_modifier_internal(skill, modifier_name, ...)
    else
        local params =
            modifiers_params_func[modifier_name] and table.pack(modifiers_params_func[modifier_name](skill)) or {}
        SkillModifier.add_modifier_internal(skill, modifier_name, table.unpack(params), ...)
    end
end
SkillModifier.add_modifier_internal = function(skill, modifier_name, ...)
    if modifiers_add_func[modifier_name] == nil then
        log.error("Can't add the modifier to skill " .. modifier_name)
    end
    if not skill.ctm_arr_modifiers then
        skill.ctm_arr_modifiers = gm.array_create(0, 0)
    end
    local modifier = gm.array_create(1, modifier_name)
    for i = 1, select("#", ...) do
        gm.array_push(modifier, select(i, ...))
    end
    gm.array_push(skill.ctm_arr_modifiers, modifier)
    modifiers_add_func[modifier_name](skill, SkillModifier.get_and_create_modifier_data(skill), ...)
end
SkillModifier.remove_modifier = function(skill, modifier_index, modifier_name)
    modifiers_remove_func[modifier_name](skill, skills_data[memory.get_usertype_pointer(skill)][modifier_index])
    skills_data[memory.get_usertype_pointer(skill)][modifier_index] = nil
end
SkillModifier.register_modifier = function(modifier_name, weight, add_func, remove_func, info_func, params_func)
    if modifiers_add_func[modifier_name] ~= nil then
        log.warn("Seems some modifiers have the same name", modifier_name)
    end
    modifiers_weight[modifier_name] = weight or 500
    total_weight = total_weight + modifiers_weight[modifier_name]
    modifiers_add_func[modifier_name] = add_func
    modifiers_remove_func[modifier_name] = remove_func
    modifiers_info_func[modifier_name] = info_func
    modifiers_params_func[modifier_name] = params_func
end
SkillModifier.add_on_activate_callback = function(modifier_data, func)
    if modifier_data["on_activate_funcs"] == nil then
        modifier_data["on_activate_funcs"] = {}
    end
    table.insert(modifier_data["on_activate_funcs"], func)
end
SkillModifier.remove_on_activate_callback = function(modifier_data)
    modifier_data["on_activate_funcs"] = nil
end
SkillModifier.add_on_stop_callback = function(modifier_data, func)
    if modifier_data["on_stop_funcs"] == nil then
        modifier_data["on_stop_funcs"] = {}
    end
    table.insert(modifier_data["on_stop_funcs"], func)
end
SkillModifier.remove_on_stop_callback = function(modifier_data)
    modifier_data["on_stop_funcs"] = nil
end
SkillModifier.add_on_can_activate_callback = function(modifier_data, func)
    if modifier_data["on_can_activate_funcs"] == nil then
        modifier_data["on_can_activate_funcs"] = {}
    end
    table.insert(modifier_data["on_can_activate_funcs"], func)
end
SkillModifier.remove_on_can_activate_callback = function(modifier_data)
    modifier_data["on_can_activate_funcs"] = nil
end
SkillModifier.get_and_create_modifier_data = function(skill, modifier_index)
    local address = memory.get_usertype_pointer(skill)
    if modifier_index == nil then
        modifier_index = gm.array_length(skill.ctm_arr_modifiers)
    end
    if skills_data[address] == nil then
        skills_data[address] = {}
    end
    if skills_data[address][modifier_index] == nil then
        skills_data[address][modifier_index] = {}
    end
    return skills_data[address][modifier_index]
end
gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skills_data[memory.get_usertype_pointer(skill)] then
        local skill_data = skills_data[memory.get_usertype_pointer(skill)]
        local flag = true
        for i = 1, #skill_data do
            local modifier_data = skill_data[i]
            if modifier_data["on_activate_funcs"] then
                for j = 1, #modifier_data["on_activate_funcs"] do
                    if modifier_data["on_activate_funcs"][j](skill) == false then
                        flag = false
                    end
                end
            end
        end
        return flag
    end
end)
gm.post_script_hook(gm.constants.skill_can_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skills_data[memory.get_usertype_pointer(skill)] then
        local skill_data = skills_data[memory.get_usertype_pointer(skill)]
        for i = 1, #skill_data do
            local modifier_data = skill_data[i]
            if modifier_data["on_can_activate_funcs"] then
                for j = 1, #modifier_data["on_can_activate_funcs"] do
                    modifier_data["on_can_activate_funcs"][j](skill, result)
                end
            end
        end
    end
end)
gm.post_script_hook(102397, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    local skill_data = skills_data[memory.get_usertype_pointer(skill)]
    if skill_data then
        local flag = true
        for i = 1, #skill_data do
            local modifier_data = skill_data[i]
            if modifier_data and modifier_data["skills_attr"] then
                for str, value in pairs(modifier_data["skills_attr"]) do
                    if type(value) == "boolean" then
                        skill[str] = value
                    elseif type(value) == "function" then
                        skill[str] = value(skill[str])
                    else
                        skill[str] = skill[str] + value
                    end
                end
            end
        end
        return flag
    end
end)
gm.post_script_hook(102401, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.stock == 0 then
        local skill_data = skills_data[memory.get_usertype_pointer(skill)]
        if skill_data then
            local flag = true
            for i = 1, #skill_data do
                local modifier_data = skill_data[i]
                if modifier_data and modifier_data["on_stop_funcs"] then
                    for j = 1, #modifier_data["on_stop_funcs"] do
                        if modifier_data["on_stop_funcs"][j](skill) == false then
                            flag = false
                        end
                    end
                end
            end
            return flag
        end
    end
end)
-- gml_Script_scribble_set_starting_format may be useful
memory.dynamic_hook_mid("hud_draw_skill_info", {"rax", "rsp+200h-188h"}, {"RValue*", "RValue*"}, 0, {},
    gm.get_script_function_address(gm.constants.hud_draw_skill_info):add(836), function(args)
        if args[2].value.ctm_arr_modifiers ~= nil then
            local modifiers = Array.wrap(args[2].value.ctm_arr_modifiers)
            for i = 0, modifiers:size() - 1 do
                local modifier = modifiers:get(i)
                local modifier_info = modifiers_info_func[modifier:get(0)]
                if modifier_info then
                    local modifier_args = {}
                    for j = 1, modifier:size() - 1 do
                        table.insert(modifier_args, modifier:get(j))
                    end
                    args[1].value = modifier_info(args[1].value, args[2].value, table.unpack(modifier_args))
                else
                    args[1].value = Language.translate_token("skill_modifier." .. modifier:get(0) .. ".name") .. ": " ..
                                        Language.translate_token("skill_modifier." .. modifier:get(0) .. ".description") ..
                                        "\n" .. args[1].value
                end
            end
        end
    end)
