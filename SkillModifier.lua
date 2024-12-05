SkillModifier = {}
local modifiers_add_func = {}
local modifiers_remove_func = {}
local modifiers_info_func = {}
local modifiers_params_func = {}
local skill_data = {}
SkillModifier.change_attr = function(skill, attr_str, new_value)
    if skill_data[memory.get_usertype_pointer(skill)]["skills_attr"] == nil then
        skill_data[memory.get_usertype_pointer(skill)]["skills_attr"] = {}
    end
    if type(new_value) == "boolean" then
        skill_data[memory.get_usertype_pointer(skill)]["skills_attr"][attr_str] = new_value
    else
        skill_data[memory.get_usertype_pointer(skill)]["skills_attr"][attr_str] = new_value - skill[attr_str]
    end
    skill[attr_str] = new_value
end
SkillModifier.change_attr_func = function(skill, attr_str, new_value)
    if skill_data[memory.get_usertype_pointer(skill)]["skills_attr"] == nil then
        skill_data[memory.get_usertype_pointer(skill)]["skills_attr"] = {}
    end
    skill_data[memory.get_usertype_pointer(skill)]["skills_attr"][attr_str] = new_value
    skill[attr_str] = new_value(skill[attr_str])
end
SkillModifier.restore_attr = function(skill, attr_str, new_value)
    skill_data[memory.get_usertype_pointer(skill)]["skills_attr"][attr_str] = nil
    skill[attr_str] = new_value
    if new_value == nil then
        gm.get_script_ref(102397)(skill, skill.parent)
    end
end
SkillModifier.add_modifier = function(skill, modifier_name, ...)
    local params = modifiers_params_func[modifier_name] and table.pack(modifiers_params_func[modifier_name](skill)) or
                       {}
    SkillModifier.add_modifier_internal(skill, modifier_name, table.unpack(params), ...)
end
SkillModifier.add_modifier_internal = function(skill, modifier_name, ...)
    skill_data[memory.get_usertype_pointer(skill)] = {}
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
    modifiers_add_func[modifier_name](skill, skill_data[memory.get_usertype_pointer(skill)], ...)
end
SkillModifier.remove_modifier = function(skill, modifier_name)
    modifiers_remove_func[modifier_name](skill, skill_data[memory.get_usertype_pointer(skill)])
    skill_data[memory.get_usertype_pointer(skill)] = nil
end
SkillModifier.register_modifier = function(modifier_name, add_func, remove_func, info_func, params_func)
    if modifiers_add_func[modifier_name] ~= nil then
        log.warn("Seems some modifiers have the same name", modifier_name)
    end
    modifiers_add_func[modifier_name] = add_func
    modifiers_remove_func[modifier_name] = remove_func
    modifiers_info_func[modifier_name] = info_func
    modifiers_params_func[modifier_name] = params_func
end
SkillModifier.get_skill_data = function(skill)
    return skill_data[memory.get_usertype_pointer(skill)]
end
local on_activate_funcs = {}
SkillModifier.add_on_activate_callback = function(skill, func)
    if skill_data[memory.get_usertype_pointer(skill)]["on_activate_funcs"] == nil then
        skill_data[memory.get_usertype_pointer(skill)]["on_activate_funcs"] = {}
    end
    table.insert(skill_data[memory.get_usertype_pointer(skill)]["on_activate_funcs"], func)
    return #skill_data[memory.get_usertype_pointer(skill)]["on_activate_funcs"]
end
SkillModifier.remove_on_activate_callback = function(skill, index)
    skill_data[memory.get_usertype_pointer(skill)]["on_activate_funcs"][index] = nil
end
local on_stop_funcs = {}
SkillModifier.add_on_stop_callback = function(skill, func)
    skill_data[memory.get_usertype_pointer(skill)]["on_stop_funcs"] = func
end
SkillModifier.remove_on_stop_callback = function(skill)
    skill_data[memory.get_usertype_pointer(skill)]["on_stop_funcs"] = nil
end
SkillModifier.remove_skill_data = function(skill)
    local skill_ptr = memory.get_usertype_pointer(skill)
    skills_attr[skill_ptr] = nil
    on_activate_funcs[skill_ptr] = nil
    on_stop_funcs[skill_ptr] = nil
end

gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill_data[memory.get_usertype_pointer(skill)]["on_activate_funcs"](skill) == false then
        return false
    end
end)
gm.post_script_hook(102397, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill_data[memory.get_usertype_pointer(skill)]["skills_attr"] then
        for str, value in pairs(skill_data[memory.get_usertype_pointer(skill)]["skills_attr"]) do
            if type(value) == "boolean" then
                skill[str] = value
            elseif type(value) == "function" then
                skill[str] = value(skill[str])
            else
                skill[str] = skill[str] + value
            end
        end
    end
end)
gm.post_script_hook(102401, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.stock == 0 then
        if on_stop_funcs[self.id] ~= nil and on_stop_funcs[self.id][args[1].value] ~= nil then
            local skill = gm.array_get(self.skills, args[1].value).active_skill
            on_stop_funcs[self.id][args[1].value](skill)
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
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    skills_attr = {}
    on_activate_funcs = {}
    on_stop_funcs = {}
end)
