SkillModifier = {}
local modifiers_add_func = {}
local modifiers_remove_func = {}
local modifiers_info_func = {}

local skills_attr = {}
SkillModifier.change_attr = function(skill, attr_str, new_value)
    if skills_attr[skill.parent.id] == nil then
        skills_attr[skill.parent.id] = {}
        if skills_attr[skill.parent.id][skill.slot_index] == nil then
            skills_attr[skill.parent.id][skill.slot_index] = {}
        end
    end
    if type(new_value) == "boolean" then
        skills_attr[skill.parent.id][skill.slot_index][attr_str] = new_value
    else
        skills_attr[skill.parent.id][skill.slot_index][attr_str] = new_value - skill[attr_str]
    end
    skill[attr_str] = new_value
end
SkillModifier.change_attr_func = function(skill, attr_str, new_value)
    if skills_attr[skill.parent.id] == nil then
        skills_attr[skill.parent.id] = {}
        if skills_attr[skill.parent.id][skill.slot_index] == nil then
            skills_attr[skill.parent.id][skill.slot_index] = {}
        end
    end
    skills_attr[skill.parent.id][skill.slot_index][attr_str] = new_value
    skill[attr_str] = new_value(skill[attr_str])
end
SkillModifier.restore_attr = function(skill, attr_str, new_value)
    skills_attr[skill.parent.id][skill.slot_index][attr_str] = nil
    skill[attr_str] = new_value
    if new_value == nil then
        gm.get_script_ref(102397)(skill, skill.parent)
    end
end
SkillModifier.add_modifier = function(skill, modifier_name, ...)
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
    modifiers_add_func[modifier_name](skill, ...)
end
SkillModifier.remove_modifier = function(skill, modifier_name)
    modifiers_remove_func[modifier_name](skill)
end
SkillModifier.register_modifier = function(modifier_name, add_func, remove_func, info_func)
    if modifiers_add_func[modifier_name] ~= nil then
        log.warn("Seems some modifiers have the same name", modifier_name)
    end
    modifiers_add_func[modifier_name] = add_func
    modifiers_remove_func[modifier_name] = remove_func
    modifiers_info_func[modifier_name] = info_func
end
SkillModifier.get_modifier_data = function(skill, index)
    if skill.ctm_arr_modifiers_data == nil then
        skill.ctm_arr_modifiers_data = gm.array_create(0, 0)
    end
    for i = gm.array_length(skill.ctm_arr_modifiers_data), index + 1 do
        gm.array_push(skill.ctm_arr_modifiers_data, gm.array_create(0, 0))
    end
    return gm.array_get(skill.ctm_arr_modifiers_data, index)
end
local on_activate_funcs = {}
SkillModifier.add_on_activate_callback = function(skill, func)
    if on_activate_funcs[skill.parent.id] == nil then
        on_activate_funcs[skill.parent.id] = {}
    end
    on_activate_funcs[skill.parent.id][skill.slot_index] = func
end
SkillModifier.remove_on_activate_callback = function(skill)
    if on_activate_funcs[skill.parent.id] == nil or on_activate_funcs[skill.parent.id][skill.slot_index] == nil then
        log.error("Try to remove a invaild on_activate_callback")
    end
    on_activate_funcs[skill.parent.id][skill.slot_index] = nil
end
gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    if on_activate_funcs[self.id] ~= nil and on_activate_funcs[self.id][args[1].value] ~= nil then
        local skill = gm.array_get(self.skills, args[1].value).active_skill
        if on_activate_funcs[self.id][args[1].value](skill) == false then
            return false
        end
    end
end)
gm.post_script_hook(102397, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skills_attr[skill.parent.id] and skills_attr[skill.parent.id][skill.slot_index] then
        for str, value in pairs(skills_attr[skill.parent.id][skill.slot_index]) do
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
local on_stop_funcs = {}
SkillModifier.add_on_stop_callback = function(skill, func)
    if on_stop_funcs[skill.parent.id] == nil then
        on_stop_funcs[skill.parent.id] = {}
    end
    on_stop_funcs[skill.parent.id][skill.slot_index] = func
end
SkillModifier.remove_on_stop_callback = function(skill)
    if on_stop_funcs[skill.parent.id] == nil or on_stop_funcs[skill.parent.id][skill.slot_index] == nil then
        log.error("Try to remove a invaild on_stop_callback")
    end
    on_stop_funcs[skill.parent.id][skill.slot_index] = nil
end
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