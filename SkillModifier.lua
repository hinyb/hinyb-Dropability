SkillModifier = {}
SkillModifier.__index = SkillModifier
SkillModifier.add_func = function()
end
SkillModifier.remove_func = function()
end
SkillModifier.default_params_func = function()
end
SkillModifier.check_func = function()
    return true
end
function SkillModifier.new(modifer_name, weight)
    local self = setmetatable({}, SkillModifier)
    self.modifier_name = modifer_name
    self.weight = weight
    self.info_func = function(ori_desc)
        return Language.translate_token("skill_modifier." .. modifer_name .. ".name") .. ": " ..
                   Language.translate_token("skill_modifier." .. modifer_name .. ".description") .. "\n" .. ori_desc
    end
    return self
end
---@param fn function(modifier_data, modifier_index, ...) The function will be called when adding modifier.
function SkillModifier:set_add_func(fn)
    self.add_func = fn
end
---@param fn function(modifier_data, modifier_index) The function will be called when removing modifier.
function SkillModifier:set_remove_func(fn)
    self.remove_func = fn
end
---@param fn function(origin_description, data, ...) The function used to update modifier's infomation.
function SkillModifier:set_info_func(fn)
    self.info_func = fn
end
-- be careful the param maybe table skill_params(table) or skill(YYObjectBase*)
---@param fn function(skill) The function used to set default paramaters,
function SkillModifier:set_default_params_func(fn)
    self.default_params_func = fn
end
-- be careful the param maybe table skill_params(table) or skill(YYObjectBase*)
---@param fn function(skill) The function used to check if the modifier can be added.
function SkillModifier:set_check_func(fn)
    self.check_func = fn
end
-- be careful the param maybe table skill_params(table) or skill(YYObjectBase*)
---@param fn function(skill) The function used to check if the modifier can be added.
function SkillModifier:set_monster_check_func(fn)
    self.monster_check_func = fn
end