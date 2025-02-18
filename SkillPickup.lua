HookSystem.clean_hook()
SkillPickup = {}
-- Need to refactor
SkillPickup.skill_create = function(x, y, skill_params)
    log.error("skill_create hasn't been initialized")
end
local pre_local_drop_funcs = {}
---@param fn function (actor, skill)
SkillPickup.add_pre_local_drop_func = function(fn)
    pre_local_drop_funcs[#pre_local_drop_funcs + 1] = fn
end
local pre_local_drop_after_diff_funcs = {}
---@param fn function (actor, skill)
SkillPickup.add_pre_local_drop_after_diff_func = function(fn)
    pre_local_drop_after_diff_funcs[#pre_local_drop_after_diff_funcs + 1] = fn
end
local post_local_drop_funcs = {}
---@param fn function (actor, skill_params)
SkillPickup.add_post_local_drop_func = function(fn)
    post_local_drop_funcs[#post_local_drop_funcs + 1] = fn
end
local post_pickup_funcs = {}
---@param fn function (actor, skillPickup, skill)
SkillPickup.add_post_pickup_func = function(fn)
    post_pickup_funcs[#post_pickup_funcs + 1] = fn
end
local skill_drop_check_funcs = {}
---@param fn function (actor, skill) this function used to check if the skill can be dropped or picked up.
SkillPickup.add_skill_drop_check_func = function(fn)
    skill_drop_check_funcs[#skill_drop_check_funcs + 1] = fn
end
local skill_override_check_funcs = {}
---@param fn function (actor, skill) this function used to check if the skill can be overridden.
SkillPickup.add_skill_override_check_func = function(fn)
    skill_override_check_funcs[#skill_override_check_funcs + 1] = fn
end
SkillPickup.add_skill_override_check_func(function(actor, skill)
    return not Utils.check_random_skill(skill.skill_id)
end)
local function can_skill_override(actor, skill)
    for i = 1, #skill_override_check_funcs do
        if skill_override_check_funcs[i](actor, skill) then
            return true
        end
    end
end
SkillPickup.add_skill_drop_check_func(function(actor, skill)
    return Utils.check_random_skill(skill.skill_id)
end)
local skill_diff_table = {}
---@param fn function (skill_diff_table, skill) this function used to check if the skill can be overridden.
SkillPickup.add_skill_diff = function(name, fn)
    skill_diff_table[name] = fn
end
SkillPickup.get_active_skill_diff = function(skill)
    local result = {}
    result.skill_id = skill.skill_id
    result.slot_index = skill.slot_index
    result.stock = skill.stock
    --[[
    local default_skill = Class.SKILL:get(skill.skill_id)
    local diff_check_table = Utils.get_skill_diff_check_table()
    if skill.disable_stock_regen ~= not default_skill:get(10) then
        result["disable_stock_regen"] = skill.disable_stock_regen
    end
    for k, v in pairs(diff_check_table) do
        if skill[k] ~= default_skill:get(v) then
            result[k] = skill[k]
        end
    end]]
    for skill_diff_name, skill_diff_func in pairs(skill_diff_table) do
        if skill[skill_diff_name] ~= nil then
            skill_diff_func(result, skill)
        end
    end
    return result
end
SkillPickup.set_skill = function(actor, params, is_override)
    if params.skill_id ~= nil and params.slot_index ~= nil then
        local skill = gm.array_get(actor.skills, params.slot_index).active_skill
        if not is_override then
            if gm.bool(actor.is_local) and not can_skill_override(actor, skill) then
                SkillPickup.drop_skill(actor, skill)
            end
        end
        gm.actor_skill_set(actor, params.slot_index, params.skill_id)
        skill = gm.array_get(actor.skills, params.slot_index).active_skill
        if params.stock then
            skill.stock = params.stock
            gm._mod_ActorSkill_recalculateStats(skill)
        end
        for i = 1, #post_pickup_funcs do
            post_pickup_funcs[i](actor, params, skill)
        end
    else
        log.error("skill_pickup hasn't been initialized correctly", 2)
    end
end
SkillPickup.drop_skill = function(player, skill)
    for i = 1, #skill_drop_check_funcs do
        if skill_drop_check_funcs[i](player, skill) == false then
            return false
        end
    end
    for i = 1, #pre_local_drop_funcs do
        pre_local_drop_funcs[i](player, skill)
    end
    local skill_params = SkillPickup.get_active_skill_diff(skill)
    for i = 1, #pre_local_drop_after_diff_funcs do
        pre_local_drop_after_diff_funcs[i](player, skill)
    end
    gm.actor_skill_set(skill.parent, skill.slot_index, 0)
    local x, y = Utils.get_actual_position(player)
    SkillPickup.skill_create(x, y, skill_params)
    for i = 1, #post_local_drop_funcs do
        post_local_drop_funcs[i](player, skill_params)
    end
end
local pre_create_funcs = {}
SkillPickup.add_pre_create_func = function(fn)
    pre_create_funcs[#pre_create_funcs + 1] = fn
end
local post_create_funcs = {}
---@param fn function (skillPickup, skill_params, x, y)
SkillPickup.add_post_create_func = function(fn)
    post_create_funcs[#post_create_funcs + 1] = fn
end
SkillPickup.skillPickup_object_index = 0
local function init_skillPickup(target, skill_params, x, y)
    local default_skill = Class.SKILL:get(skill_params.skill_id)
    target.sprite_index = default_skill:get(4)
    target.image_index = default_skill:get(5)
    target.text = Language.translate_token(default_skill:get(2))
    for k, v in pairs(skill_params) do
        if type(v) == "table" then
            target[k] = Utils.create_array_from_table(v)
        else
            target[k] = v
            if k == "subimage" then
                target.image_index = v
            elseif k == "name" then
                target.text = Language.translate_token(v)
            end
        end
    end
    for i = 1, #post_create_funcs do
        post_create_funcs[i](target, skill_params, x, y)
    end
end
local function init()
    local function setup_skill(inst, actor)
        SkillPickup.set_skill(actor, inst)
        inst.activator = actor
    end
    local skillPickup = Object.new("hinyb", "skillPickup", Object.PARENT.interactable)
    SkillPickup.skillPickup_object_index = skillPickup.value
    skillPickup.obj_sprite = 114
    skillPickup.obj_depth = 5.0
    local pickup_skill_message_create
    HookSystem.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        local inst = args[1].value
        if inst.__object_index == skillPickup.value then
            local actor = args[2].value
            setup_skill(inst, actor)
            if Net.is_host() then
                pickup_skill_message_create(inst, actor):send_to_all()
            elseif Net.is_client() then
                pickup_skill_message_create(inst, actor):send_to_host()
            end
            gm.instance_destroy(inst.id)
            return false
        end
    end)
    local pickup_skill_packet = Packet.new()
    pickup_skill_packet:onReceived(function(message, player)
        local interactable = message:read_instance().value
        local activator = message:read_instance().value
        setup_skill(interactable, activator)
        if Net.is_host() then
            pickup_skill_message_create(interactable, activator):send_exclude(player)
        end
        gm.instance_destroy(interactable.id)
    end)
    pickup_skill_message_create = function(interactable, activator)
        local sync_message = pickup_skill_packet:message_begin()
        sync_message:write_instance(interactable)
        sync_message:write_instance(activator)
        return sync_message
    end
    local drop_skill_send
    local function drop_skill(x, y, skill_params)
        local skill = gm.instance_create(x - 20, y - 20, skillPickup.value)
        init_skillPickup(skill, skill_params, x - 20, y - 20)
        gm.call("gml_Script_interactable_sync", skill, skill)
        local sync_message = drop_skill_send(skill_params)
        sync_message:write_instance(skill)
        sync_message:send_to_all()
    end
    local drop_skill_packet = Packet.new()
    drop_skill_packet:onReceived(function(message, player)
        local skill_id = message:read_int()
        local slot_index = message:read_int()
        local ext_num = message:read_int()
        local skill_params = {}
        skill_params.skill_id = skill_id
        skill_params.slot_index = slot_index
        for _ = 1, ext_num do
            local mem = message:read_string()
            local val = message:read_string()
            if mem:sub(1, 4) == "arr_" then
                skill_params[mem:sub(5, -1)] = Utils.simple_string_to_table(val)
            else
                skill_params[mem] = Utils.parse_string_to_value(val)
            end
        end
        if Net.is_host() then
            drop_skill(player.x, player.y, skill_params)
        else
            local skill = message:read_instance().value
            init_skillPickup(skill, skill_params, skill.x, skill.y)
        end
    end)
    drop_skill_send = function(skill_params)
        local sync_message = drop_skill_packet:message_begin()
        sync_message:write_int(skill_params.skill_id)
        sync_message:write_int(skill_params.slot_index)
        sync_message:write_int(Utils.table_get_length(skill_params) - 2)
        for k, v in pairs(skill_params) do
            if k ~= "skill_id" and k ~= "slot_index" then
                if type(v) == "table" then
                    sync_message:write_string("arr_" .. tostring(k))
                    sync_message:write_string(Utils.simple_table_to_string(v))
                else
                    sync_message:write_string(tostring(k))
                    sync_message:write_string(tostring(v))
                end
            end
        end
        return sync_message
    end
    HookSystem.post_script_hook(gm.constants.run_create, function(self, other, result, args)
        if Net.is_single() then
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params)
                end
                local skill = gm.instance_create(x - 20, y - 20, skillPickup.value)
                init_skillPickup(skill, skill_params, x - 20, y - 20)
            end
        elseif Net.is_host() then
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params)
                end
                drop_skill(x, y, skill_params)
            end
        else
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params)
                end
                local sync_message = drop_skill_send(skill_params)
                sync_message:send_to_host()
            end
        end
    end)
end
Initialize(init)
