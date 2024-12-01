SkillModifier = {}
local modifiers_pre_func = {}
local modifiers_post_func = {}
local modifiers_info_func = {}
-- this change will be reset when skill_recalculate_stats
SkillModifier.change_attr = function(inst, slot_index, attr_str, new_value)
    local skill = gm.array_get(inst.skills, slot_index).active_skill
    skill[attr_str] = new_value
end
SkillModifier.add_modifier = function(inst, slot_index, modifier_name, ...)
    if modifiers_pre_func[modifier_name] == nil and modifiers_post_func[modifier_name] == nil then
        log.error("Can't add the modifier to skill", modifier_name)
    end
    local skill = gm.array_get(inst.skills, slot_index).active_skill
    if not skill.ctm_arr_activate then
        skill.ctm_arr_activate = gm.array_create(0, 0)
        skill.ctm_arr_activate_data = gm.array_create(0, 0)
    end
    local modifier = gm.array_create(1, modifier_name)
    for i = 1, select("#", ...) do
        gm.array_push(modifier, select(i, ...))
    end
    gm.array_push(skill.ctm_arr_activate, modifier)
    gm.array_push(skill.ctm_arr_activate_data, gm.array_create(0, 0))
end
SkillModifier.register_modifier = function(modifier_name, prefunc, postfunc, info_func)
    if modifiers_pre_func[modifier_name] ~= nil or modifiers_post_func[modifier_name] ~= nil then
        log.warn("Seems some modifiers have the same name")
    else
        modifiers_pre_func[modifier_name] = prefunc
        modifiers_post_func[modifier_name] = postfunc
        modifiers_info_func[modifier_name] = info_func
    end
end
gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_activate ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_activate)
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            if modifiers_pre_func[modifier:get(0)] then
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    table.insert(modifier_args, modifier:get(j))
                end
                modifiers_pre_func[modifier:get(0)](skill, gm.array_get(skill.ctm_arr_activate_data, i), table.unpack(modifier_args))
            end
        end
    end
end)
gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_activate ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_activate)
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            if modifiers_post_func[modifier:get(0)] then
                local modifier_args = {}
                for j = 1, modifier:size() - 1 do
                    table.insert(modifier_args, modifier:get(j))
                end
                modifiers_post_func[modifier:get(0)](skill, gm.array_get(skill.ctm_arr_activate_data, i), table.unpack(modifier_args))
            end
        end
    end
end)
-- gml_Script_scribble_set_starting_format may be useful
memory.dynamic_hook_mid("hud_draw_skill_info", {"rax", "rsp+200h-188h"}, {"RValue*", "RValue*"}, 0, {},
    gm.get_script_function_address(gm.constants.hud_draw_skill_info):add(836), function(args)
        if args[2].value.ctm_arr_activate ~= nil then
            local modifiers = Array.wrap(args[2].value.ctm_arr_activate)
            for i = 0, modifiers:size() - 1 do
                local modifier = modifiers:get(i)
                if modifiers_info_func[modifier:get(0)] then
                    local modifier_args = {}
                    for j = 1, modifier:size() - 1 do
                        table.insert(modifier_args, modifier:get(j))
                    end
                    args[1].value = modifiers_info_func[modifier:get(0)](args[1].value, args[2].value, table.unpack(modifier_args))
                else
                    args[1].value = Language.translate_token("skill_modifier." .. modifier:get(0) .. ".name") .. ": " ..
                                    Language.translate_token("skill_modifier." .. modifier:get(0) .. ".description") ..
                                    "\n" .. args[1].value
                end
            end
        end
    end)
--[[
-- may hook ActorSkill is a better way
gm.pre_script_hook(102386, function(self, other, result, args)
    args[1].value.ctm_sprite = 0
    args[1].value.ctm_arr_activate = gm.array_create(0, 0)
end)
]]
