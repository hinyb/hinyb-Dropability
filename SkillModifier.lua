SkillModifier = {}
local modifiers_pre_func = {{}, {}}
local modifiers_post_func = {{}, {}}
local modifiers_info_func = {{}, {}}
SkillModifier.TYPE = {
    ["Both"] = 0,
    ["Activate"] = 1,
    ["Stop"] = 2
}
-- this change will be reset when skill_recalculate_stats
SkillModifier.change_attr = function(inst, slot_index, attr_str, new_value)
    local skill = gm.array_get(inst.skills, slot_index).active_skill
    skill[attr_str] = new_value
end
SkillModifier.add_modifier = function(inst, slot_index, modifier_name, type, ...)
    if modifiers_pre_func[type][modifier_name] == nil and modifiers_post_func[type][modifier_name] == nil then
        log.error("Can't add the modifier to skill "..modifier_name)
    end
    local skill = gm.array_get(inst.skills, slot_index).active_skill
    if not skill.ctm_arr_modifiers then
        skill.ctm_arr_modifiers = gm.array_create(0, 0)
        gm.array_push(skill.ctm_arr_modifiers, gm.array_create(0, 0))
        gm.array_push(skill.ctm_arr_modifiers, gm.array_create(0, 0))
    end
    local modifier = gm.array_create(1, modifier_name)
    for i = 1, select("#", ...) do
        gm.array_push(modifier, select(i, ...))
    end
    gm.array_push(gm.array_get(skill.ctm_arr_modifiers, type - 1), modifier)
end
SkillModifier.register_modifier = function(modifier_name, type, prefunc, postfunc, info_func)
    if type == SkillModifier.TYPE.Both then
        SkillModifier.register_modifier(modifier_name, SkillModifier.TYPE.Activate, prefunc, postfunc, info_func)
        SkillModifier.register_modifier(modifier_name, SkillModifier.TYPE.Stop, prefunc, postfunc, info_func)
    else
        if modifiers_pre_func[type][modifier_name] ~= nil or modifiers_post_func[type][modifier_name] ~= nil then
            log.warn("Seems some modifiers have the same name", modifier_name)
        else
            modifiers_pre_func[type][modifier_name] = prefunc
            modifiers_post_func[type][modifier_name] = postfunc
            modifiers_info_func[type][modifier_name] = info_func
        end
    end
end


local function get_modifier_data(skill, type, index)
    if skill.ctm_arr_modifiers_data == nil then
        skill.ctm_arr_modifiers_data = gm.array_create(0, 0)
        gm.array_push(skill.ctm_arr_modifiers_data, gm.array_create(0, 0))
        gm.array_push(skill.ctm_arr_modifiers_data, gm.array_create(0, 0))
    end
    local modifiers_data = gm.array_get(skill.ctm_arr_modifiers_data, type - 1)
    for i = gm.array_length(modifiers_data), index + 1 do
        gm.array_push(modifiers_data, gm.array_create(0, 0))
    end
    return gm.array_get(modifiers_data, index)
end
gm.pre_script_hook(102401, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(gm.array_get(skill.ctm_arr_modifiers, SkillModifier.TYPE.Stop - 1))
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            if modifiers_pre_func[SkillModifier.TYPE.Stop][modifier:get(0)] then
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    table.insert(modifier_args, modifier:get(j))
                end
                modifiers_pre_func[SkillModifier.TYPE.Stop][modifier:get(0)](skill, get_modifier_data(skill, SkillModifier.TYPE.Stop, i),
                    table.unpack(modifier_args))
            end
        end
    end
end)
gm.post_script_hook(102401, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(gm.array_get(skill.ctm_arr_modifiers, SkillModifier.TYPE.Stop - 1))
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            if modifiers_post_func[SkillModifier.TYPE.Stop][modifier:get(0)] then
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    table.insert(modifier_args, modifier:get(j))
                end
                modifiers_post_func[SkillModifier.TYPE.Stop][modifier:get(0)](skill, get_modifier_data(skill, SkillModifier.TYPE.Stop, i),
                    table.unpack(modifier_args))
            end
        end
    end
end)
gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(gm.array_get(skill.ctm_arr_modifiers, SkillModifier.TYPE.Activate - 1))
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            if modifiers_pre_func[SkillModifier.TYPE.Activate][modifier:get(0)] then
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    table.insert(modifier_args, modifier:get(j))
                end
                modifiers_pre_func[SkillModifier.TYPE.Activate][modifier:get(0)](skill, get_modifier_data(skill, SkillModifier.TYPE.Activate, i),
                    table.unpack(modifier_args))
            end
        end
    end
end)
gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(gm.array_get(skill.ctm_arr_modifiers, SkillModifier.TYPE.Activate - 1))
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            if modifiers_post_func[SkillModifier.TYPE.Activate][modifier:get(0)] then
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    table.insert(modifier_args, modifier:get(j))
                end
                modifiers_post_func[SkillModifier.TYPE.Activate][modifier:get(0)](skill, get_modifier_data(skill, SkillModifier.TYPE.Activate, i),
                    table.unpack(modifier_args))
            end
        end
    end
end)
-- gml_Script_scribble_set_starting_format may be useful
memory.dynamic_hook_mid("hud_draw_skill_info", {"rax", "rsp+200h-188h"}, {"RValue*", "RValue*"}, 0, {},
    gm.get_script_function_address(gm.constants.hud_draw_skill_info):add(836), function(args)
        if args[2].value.ctm_arr_modifiers ~= nil then
            local arr_modifiers = Array.wrap(args[2].value.ctm_arr_modifiers)
            for modifier_type = 0, arr_modifiers:size() - 1 do
                local modifiers = arr_modifiers:get(modifier_type)
                for i = 0, modifiers:size() - 1 do
                    local modifier = modifiers:get(i)
                    local modifier_info = modifiers_info_func[modifier_type + 1][modifier:get(0)]
                    if modifier_info then
                        local modifier_args = {}
                        for j = 1, modifier:size() - 1 do
                            table.insert(modifier_args, modifier:get(j))
                        end
                        args[1].value = modifier_info(args[1].value, args[2].value, modifier_type + 1, table.unpack(modifier_args))
                    else
                        local type_str = ""
                        if modifier_type + 1 == SkillModifier.TYPE.Activate then
                            type_str = ", trigger when <y>activate</c>"
                        elseif modifier_type + 1 == SkillModifier.TYPE.Stop then
                            type_str = ", trigger when <y>stop</c>"
                        end
                        args[1].value = Language.translate_token("skill_modifier." .. modifier:get(0) .. ".name") ..
                                            ": " ..
                                            Language.translate_token(
                                "skill_modifier." .. modifier:get(0) .. ".description") .. type_str .. "\n" ..
                                            args[1].value
                    end
                end
            end
        end
    end)
--[[
-- may hook ActorSkill is a better way
gm.pre_script_hook(102386, function(self, other, result, args)
    args[1].value.ctm_sprite = 0
    args[1].value.ctm_arr_modifiers = gm.array_create(0, 0)
end)
]]
