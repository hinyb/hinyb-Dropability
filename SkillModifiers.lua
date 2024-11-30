SkillModifiers = {}
local modifiers_pre_func = {}
local modifiers_post_func = {}
SkillModifiers.change_attr = function(player, slot_index, attr_str, new_value)
    local skill = gm.array_get(player.skills, slot_index).active_skill
    skill[attr_str] = new_value
end
SkillModifiers.add_modifier = function(player, slot_index, modifier_name)
    local skill = gm.array_get(player.skills, slot_index).active_skill
    if not skill.ctm_arr_activate then
        skill.ctm_arr_activate = gm.array_create(0, 0)
    end
    gm.array_push(skill.ctm_arr_activate, modifier_name)
end
SkillModifiers.register_modifier = function(modifier_name, prefunc, postfunc)
    if modifiers_pre_func[modifier_name] ~= nil then
        log.warn("Seems some modifiers have the same name")
    else
        modifiers_pre_func[modifier_name] = prefunc
        modifiers_post_func[modifier_name] = postfunc
    end
end
gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_activate ~= nil then
        local modifier_names = Array.wrap(skill.ctm_arr_activate)
        for i = 0, modifier_names.size() - 1 do
            if modifiers_pre_func[modifier_names:get(i)] then
                modifiers_pre_func[modifier_names:get(i)](self)
            end
        end
    end
end)
gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_activate ~= nil then
        local modifier_names = Array.wrap(skill.ctm_arr_activate)
        for i = 0, modifier_names.size() - 1 do
            if modifiers_post_func[modifier_names:get(i)] then
                modifiers_post_func[modifier_names:get(i)](self)
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