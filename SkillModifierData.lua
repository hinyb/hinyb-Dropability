SkillModifierData = {}
SkillModifierData.__index = SkillModifierData
-- may need improve 
function SkillModifierData.new(skill)
    local self = setmetatable({}, SkillModifierData)
    self.skill = skill
    self.skill_attr_changes = {}
    self.parent_attr_changes = {}
    self.pre_activate_funcs = {}
    self.post_activate_funcs = {}
    self.post_remove_stock_funcs = {}
    self.pre_actor_death_after_hippo_funcs = {}
    self.pre_can_activate_funcs = {}
    self.post_can_activate_funcs = {}
    return self
end
---@param attr_str string The name of attribute.
---@param fn function The function(origin_value, modifier_data) The function used to change attribute.
function SkillModifierData:add_skill_attr_change(attr_str, fn)
    if self.skill[attr_str] == nil then
        log.error("Try to change a non-existent attribute", 2)
    else
        self.skill[attr_str] = fn(self.skill[attr_str])
        self.skill_attr_changes[attr_str] = self.skill_attr_changes[attr_str] or {}
        table.insert(self.skill_attr_changes[attr_str], fn)
    end
end
-- parent are used to call update_skill_for_stopwatch
-- auto_restock
---@param attr_str string The name of attribute.
function SkillModifierData:restore_skill_attr_change(attr_str)
    self.skill_attr_changes[attr_str] = {}
    gm.get_script_ref(102397)(self.skill, self.skill.parent)
end
-- It maybe useless, can use Toolkit's Instance add_callback replace.
---@param attr_str string The name of attribute.
---@param fn function The function(origin_value, modifier_data) The function used to change attribute.
function SkillModifierData:add_parent_attr_change(attr_str, fn)
    if self.skill[attr_str] == nil then
        log.error("Try to change a non-existent attribute", 2)
    else
        self.skill[attr_str] = fn(self.skill[attr_str])
        table.insert(self.parent_attr_changes[attr_str], fn)
    end
end
---@param attr_str string The name of attribute.
function SkillModifierData:restore_parent_attr_change(attr_str)
    self.parent_attr_changes[attr_str] = {}
    gm.call("gml_Script_recalculate_stats", self.skill.parent, self.skill.parent)
end

---@param fn function The function(modifier_data)
function SkillModifierData:add_pre_activate_callback(fn)
    table.insert(self.pre_activate_funcs, fn)
end
function SkillModifierData:remove_pre_activate_callback()
    self.pre_activate_funcs = nil
end
---@param fn function The function(modifier_data)
function SkillModifierData:add_post_activate_callback(fn)
    table.insert(self.post_activate_funcs, fn)
end
function SkillModifierData:remove_post_activate_callback()
    self.post_activate_funcs = nil
end

---@param fn function The function(modifier_data)
function SkillModifierData:add_post_remove_stock_callback(fn)
    table.insert(self.post_activate_funcs, fn)
end
function SkillModifierData:remove_post_remove_stock_callback()
    self.post_activate_funcs = nil
end

---@param fn function The function(modifier_data)
function SkillModifierData:add_pre_actor_death_after_hippo_callback(fn)
    table.insert(self.pre_actor_death_after_hippo_funcs, fn)
end
function SkillModifierData:remove_pre_actor_death_after_hippo_callback()
    self.pre_actor_death_after_hippo_funcs = nil
end

function SkillModifierData:add_pre_can_activate_callback(fn)
    table.insert(self.pre_can_activate_funcs, fn)
end
function SkillModifierData:remove_pre_can_activate_callback()
    self.pre_can_activate_funcs = nil
end
function SkillModifierData:add_post_can_activate_callback(fn)
    table.insert(self.post_can_activate_funcs, fn)
end
function SkillModifierData:remove_post_can_activate_callback()
    self.post_can_activate_funcs = nil
end

gm.post_script_hook(102397, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for i = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_or_create_modifier_data(skill, i)
            for name, funcs in pairs(data.skill_attr_changes) do
                for j = 1, #funcs do
                    skill[name] = funcs[j](skill[name], data)
                end
            end
        end
    end
end)

-- It might be better to bind the instance instead of skill. But I can't extend Instance.
gm.post_script_hook(gm.constants.recalculate_stats, function(self, other, result, args)
    for i = 0, gm.array_length(self.skills) - 1 do
        local skill = gm.array_get(self.skills, i).active_skill
        if skill.ctm_arr_modifiers ~= nil then
            local modifiers = Array.wrap(skill.ctm_arr_modifiers)
            for j = 0, modifiers:size() - 1 do
                local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
                for name, funcs in pairs(data.parent_attr_changes) do
                    for k = 1, #funcs do
                        self[name] = funcs[k](self[name], data)
                    end
                end
            end
        end
    end
end)

gm.pre_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        local flag = true
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
            for i = 1, #data.pre_activate_funcs do
                if data.pre_activate_funcs[i](data) == false then
                    flag = false
                end
            end
        end
        return flag
    end
end)

gm.post_script_hook(gm.constants.skill_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
            for i = 1, #data.post_activate_funcs do
                data.post_activate_funcs[i](data)
            end
        end
    end
end)

gm.post_script_hook(102401, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
            for i = 1, #data.post_remove_stock_funcs do
                data.post_remove_stock_funcs[i](data)
            end
        end
    end
end)

-- It might be better to bind the instance instead of skill. But I can't extend Instance.
-- And Need more time to improve this.
gm.pre_script_hook(gm.constants.actor_death, function(self, other, result, args)
    if gm.array_get(self.inventory_item_stack, 76) == 0 then -- temporary solution.
        for i = 0, gm.array_length(self.skills) - 1 do
            local skill = gm.array_get(self.skills, i).active_skill
            if skill.ctm_arr_modifiers ~= nil then
                local modifiers = Array.wrap(skill.ctm_arr_modifiers)
                for j = 0, modifiers:size() - 1 do
                    local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
                    for i = 1, #data.pre_actor_death_after_hippo_funcs do
                        data.pre_actor_death_after_hippo_funcs[i](data)
                    end
                end
            end
        end
    end
end)
gm.pre_script_hook(gm.constants.skill_can_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        local flag = true
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
            for i = 1, #data.pre_can_activate_funcs do
                if data.pre_can_activate_funcs[i](data) == false then
                    flag = false
                end
            end
        end
        return flag
    end
end)
gm.post_script_hook(gm.constants.skill_can_activate, function(self, other, result, args)
    local skill = gm.array_get(self.skills, args[1].value).active_skill
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_or_create_modifier_data(skill, j)
            for i = 1, #data.post_can_activate_funcs do
                data.post_can_activate_funcs[i](data, result)
            end
        end
    end
end)

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
