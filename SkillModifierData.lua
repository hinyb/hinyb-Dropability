SkillModifierData = {}
SkillModifierData.__index = SkillModifierData
-- may need improve 
function SkillModifierData.new(skill, modifier_name)
    local self = setmetatable({}, SkillModifierData)
    self.skill = skill
    self.modifier_name = modifier_name
    return self
end
---@param modifier_index number If pass the modifier_index, the id will be an unique id.
function SkillModifierData:get_id(modifier_index)
    local id = self.modifier_name .. Utils.to_string_with_floor(self.skill.slot_index)
    id = modifier_index and id .. tostring(modifier_index) or id
    return id
end
---@param attr_str string The name of attribute.
---@param fn function (origin_value, modifier_data) the function used to change attribute.
function SkillModifierData:add_skill_attr_change(attr_str, fn)
    if self.skill[attr_str] == nil then
        log.error("Try to change a non-existent attribute", 2)
    else
        self.skill[attr_str] = fn(self.skill[attr_str], self)
        if self.skill_attr_changes == nil then
            self.skill_attr_changes = {}
        end
        self.skill_attr_changes[attr_str] = self.skill_attr_changes[attr_str] or {}
        table.insert(self.skill_attr_changes[attr_str], fn)
    end
end
-- parent are used to call update_skill_for_stopwatch
-- auto_restock
---@param attr_str string The name of attribute.
function SkillModifierData:restore_skill_attr_change(attr_str)
    self.skill_attr_changes[attr_str] = {}
    gm._mod_ActorSkill_recalculateStats(self.skill)
end
---@param fn function (modifier_data)
function SkillModifierData:add_pre_activate_callback(fn)
    if self.pre_activate_funcs == nil then
        self.pre_activate_funcs = {}
    end
    table.insert(self.pre_activate_funcs, fn)
end
function SkillModifierData:remove_pre_activate_callback()
    self.pre_activate_funcs = nil
end
---@param fn function (modifier_data)
function SkillModifierData:add_post_activate_callback(fn)
    if self.post_activate_funcs == nil then
        self.post_activate_funcs = {}
    end
    table.insert(self.post_activate_funcs, fn)
end
function SkillModifierData:remove_post_activate_callback()
    self.post_activate_funcs = nil
end

---@param fn function (modifier_data)
function SkillModifierData:add_post_remove_stock_callback(fn)
    if self.post_remove_stock_funcs == nil then
        self.post_remove_stock_funcs = {}
    end
    table.insert(self.post_remove_stock_funcs, fn)
end
function SkillModifierData:remove_post_remove_stock_callback()
    self.post_remove_stock_funcs = nil
end

---@param fn function (modifier_data)
function SkillModifierData:add_post_add_stock_callback(fn)
    if self.post_add_stock_funcs == nil then
        self.post_add_stock_funcs = {}
    end
    table.insert(self.post_add_stock_funcs, fn)
end
function SkillModifierData:remove_add_remove_stock_callback()
    self.post_add_stock_funcs = nil
end

---@param fn function (modifier_data)
function SkillModifierData:add_pre_local_can_activate_callback(fn)
    if self.pre_can_activate_funcs == nil then
        self.pre_can_activate_funcs = {}
    end
    table.insert(self.pre_can_activate_funcs, fn)
end
function SkillModifierData:remove_pre_local_can_activate_callback()
    self.pre_can_activate_funcs = nil
end
---@param fn function (modifier_data)
function SkillModifierData:add_post_local_can_activate_callback(fn)
    if self.post_can_activate_funcs == nil then
        self.post_can_activate_funcs = {}
    end
    table.insert(self.post_can_activate_funcs, fn)
end
function SkillModifierData:remove_post_local_can_activate_callback()
    self.post_can_activate_funcs = nil
end
function SkillModifierData:add_pre_local_drop_callback(fn)
    if self.pre_drop_funcs == nil then
        self.pre_drop_funcs = {}
    end
    table.insert(self.pre_drop_funcs, fn)
end
function SkillModifierData:remove_pre_local_drop_callback()
    self.pre_drop_funcs = nil
end
---@param fn function (actor, skill_params)
function SkillModifierData:add_post_local_drop_callback(fn)
    if self.post_drop_funcs == nil then
        self.post_drop_funcs = {}
    end
    table.insert(self.post_drop_funcs, fn)
end
function SkillModifierData:remove_post_local_drop_callback()
    self.post_drop_funcs = nil
end
local post_drop_callback = {}
SkillPickup.add_pre_local_drop_func(function(actor, skill)
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.pre_drop_funcs then
                    for i = 1, #data.pre_drop_funcs do
                        data.pre_drop_funcs[i](data)
                    end
                end
                if data.post_drop_funcs then
                    for i = 1, #data.post_drop_funcs do
                        table.insert(post_drop_callback, data.post_drop_funcs[i])
                    end
                end
            end
        end
    end
end)
SkillPickup.add_post_local_drop_func(function(actor, skill_params)
    for i = 1, #post_drop_callback do
        post_drop_callback[i](actor, skill_params)
    end
    post_drop_callback = {}
end)
gm.post_script_hook(102397, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for i = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_modifier_data(skill, i)
            if data then
                if data.skill_attr_changes then
                    for name, funcs in pairs(data.skill_attr_changes) do
                        for j = 1, #funcs do
                            skill[name] = funcs[j](skill[name], data)
                        end
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
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.pre_activate_funcs then
                    for i = 1, #data.pre_activate_funcs do
                        if data.pre_activate_funcs[i](data) == false then
                            flag = false
                        end
                    end
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
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.post_activate_funcs then
                    for i = 1, #data.post_activate_funcs do
                        data.post_activate_funcs[i](data)
                    end
                end
            end
        end
    end
end)
gm.post_script_hook(102400, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.post_add_stock_funcs then
                    for i = 1, #data.post_add_stock_funcs do
                        data.post_add_stock_funcs[i](data)
                    end
                end
            end
        end
    end
end)

gm.post_script_hook(102401, function(self, other, result, args)
    local skill = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    if skill.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for j = 0, modifiers:size() - 1 do
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.post_remove_stock_funcs then
                    for i = 1, #data.post_remove_stock_funcs do
                        data.post_remove_stock_funcs[i](data)
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
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.pre_can_activate_funcs then
                    for i = 1, #data.pre_can_activate_funcs do
                        if data.pre_can_activate_funcs[i](data) == false then
                            flag = false
                        end
                    end
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
            local data = SkillModifierManager.get_modifier_data(skill, j)
            if data then
                if data.post_can_activate_funcs then
                    for i = 1, #data.post_can_activate_funcs do
                        data.post_can_activate_funcs[i](data, result)
                    end
                end
            end
        end
    end
end)

memory.dynamic_hook_mid("hud_draw_skill_info", {"rax", "rsp+200h-188h"}, {"RValue*", "RValue*"}, 0,
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
                local data = SkillModifierManager.get_modifier_data(args[2].value, i)
                if data then
                    args[1].value = info_func(args[1].value, data, table.unpack(modifier_args))
                end
            end
        end
    end)
