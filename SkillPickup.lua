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
    local default_skill = Class.Skill:get(skill.skill_id)
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
---@param fn function (skill_params, x, y)
SkillPickup.add_pre_create_func = function(fn)
    pre_create_funcs[#pre_create_funcs + 1] = fn
end
local post_create_funcs = {}
---@param fn function (skillPickup, skill_params, x, y)
SkillPickup.add_post_create_func = function(fn)
    post_create_funcs[#post_create_funcs + 1] = fn
end
local function init_skillPickup(target, skill_params, x, y)
    local default_skill = Class.Skill:get(skill_params.skill_id)
    target.sprite_index = default_skill:get(4)
    target.image_index = default_skill:get(5)
    target.text = gm.translate(default_skill:get(2))
    for k, v in pairs(skill_params) do
        if lua_type(v) == "table" then
            target[k] = Utils.create_array_from_table(v)
        else
            target[k] = v
            if k == "subimage" then
                target.image_index = v
            elseif k == "name" then
                target.text = gm.translate(v)
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
    local oSkillPickup = Object.new("oSkillPickup", Object.Parent.INTERACTABLE)
    gm.constants.oSkillPickup = oSkillPickup.value
    oSkillPickup:set_sprite(114)
    oSkillPickup:set_depth(-290)
    local pickup_skill_message_create
    HookSystem.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        local inst = args[1].value
        if inst.__object_index == oSkillPickup.value then
            local actor = args[2].value
            setup_skill(inst, actor)
            if Net.online then
                if Net.host then
                    pickup_skill_message_create(inst, actor):send_to_all()
                elseif Net.client then
                    pickup_skill_message_create(inst, actor):send_to_host()
                end
            end
            gm.instance_destroy(inst.id)
            return false
        end
    end)
    local pickup_skill_packet = Packet.new("pickup_skill_packet")
    pickup_skill_packet:set_serializers(function(buffer, interactable, activator)
        buffer:write_instance(interactable)
        buffer:write_instance(activator)
    end, function(buffer, player)
        local interactable = buffer:read_instance().value
        local activator = buffer:read_instance().value

        setup_skill(interactable, activator)

        if Net.host then
            pickup_skill_packet:send_exclude(player, interactable, activator)
        end

        gm.instance_destroy(interactable.id)
    end)
    pickup_skill_message_create = function(interactable, activator)
        pickup_skill_packet:send_to_host(interactable, activator)
    end
    local function drop_skill(x, y, skill_params)
        local skill = gm.instance_create(x - 15, y - 15, gm.constants.oSkillPickup)
        init_skillPickup(skill, skill_params, x - 15, y - 15)
        skill:interactable_sync()
        drop_skill_packet:send_to_all(skill_params, skill)
    end
    local drop_skill_packet = Packet.new("drop_skill_packet")
    drop_skill_packet:set_serializers(function(buffer, skill_params, skill_instance)
        buffer:write_int(skill_params.skill_id)
        buffer:write_int(skill_params.slot_index)

        local ext_count = Utils.table_get_length(skill_params) - 2
        buffer:write_int(ext_count)

        for k, v in pairs(skill_params) do
            if k ~= "skill_id" and k ~= "slot_index" then
                if lua_type(v) == "table" then
                    buffer:write_string("arr_" .. tostring(k))
                    buffer:write_string(Utils.simple_table_to_string(v))
                else
                    buffer:write_string(tostring(k))
                    buffer:write_string(tostring(v))
                end
            end
        end

        if skill_instance then
            buffer:write_instance(skill_instance)
        end
    end, function(buffer, player)
        local skill_id = buffer:read_int()
        local slot_index = buffer:read_int()
        local ext_num = buffer:read_int()

        local skill_params = {}
        skill_params.skill_id = skill_id
        skill_params.slot_index = slot_index

        for _ = 1, ext_num do
            local mem = buffer:read_string()
            local val = buffer:read_string()
            if mem:sub(1, 4) == "arr_" then
                skill_params[mem:sub(5, -1)] = Utils.simple_string_to_table(val)
            else
                skill_params[mem] = Utils.parse_string_to_value(val)
            end
        end

        if Net.host then
            drop_skill(player.x, player.y, skill_params)
        else
            local skill = buffer:read_instance().value
            init_skillPickup(skill, skill_params, skill.x, skill.y)
        end
    end)
    HookSystem.post_script_hook(gm.constants.run_create, function(self, other, result, args)
        if not Net.online then
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params, x, y)
                end
                local skill = gm.instance_create(x - 15, y - 15, gm.constants.oSkillPickup)
                init_skillPickup(skill, skill_params, x - 15, y - 15)
            end
        elseif Net.host then
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params, x, y)
                end
                drop_skill(x, y, skill_params)
            end
        else
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params, x, y)
                end
                drop_skill_packet:send_to_host(skill_params)
            end
        end
    end)
    local set_skill_sync_internal = Utils.create_sync_func([[
        local params = Utils.table_deep_copy(a4)
        params.slot_index = a2
        params.skill_id = a3
        SkillPickup.set_skill(a1, params, a5)
    ]], { Utils.param_type.instance, Utils.param_type.byte, Utils.param_type.ushort, Utils.param_type.table,
        Utils.param_type.byte })
    SkillPickup.set_skill_sync = function(actor, params, is_override)
        if is_override == nil then
            is_override = false
        end
        local copy_params = Utils.table_deep_copy(params)
        copy_params.slot_index = nil
        copy_params.skill_id = nil
        set_skill_sync_internal(actor, params.slot_index, params.skill_id, copy_params, is_override)
    end
end
Initialize.add_hotloadable(init)
