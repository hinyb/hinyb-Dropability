SkillPickup = {}
-- May need to refactor
SkillPickup.skill_create = function(x, y, skill_params)
    log.error("skill_create hasn't been initialized")
end
local pre_local_drop_funcs = {}
---@param fn function (actor, skill)
SkillPickup.add_pre_local_drop_func = function(fn)
    pre_local_drop_funcs[#pre_local_drop_funcs + 1] = fn
end
local post_local_drop_funcs = {}
---@param fn function (actor, skill_params)
SkillPickup.add_post_local_drop_func = function(fn)
    post_local_drop_funcs[#post_local_drop_funcs + 1] = fn
end
local post_local_pickup_funcs = {}
---@param fn function (actor, slot_index)
SkillPickup.add_post_local_pickup_func = function(fn)
    post_local_pickup_funcs[#post_local_pickup_funcs + 1] = fn
end
local skill_check_funcs = {}
---@param fn function (actor, skill) this function used to check if the skill can be dropped or picked up.
SkillPickup.add_skill_check_func = function(fn)
    skill_check_funcs[#skill_check_funcs + 1] = fn
end
local skill_override_check_funcs = {}
---@param fn function (actor, skill) this function used to check if the skill can be overridden.
SkillPickup.add_skill_override_check_func = function(fn)
    skill_override_check_funcs[#skill_override_check_funcs + 1] = fn
end
SkillPickup.add_skill_override_check_func(function(actor, skill)
    return skill.skill_id == 0
end)
local function can_skill_override(actor, skill)
    for i = 1, #skill_override_check_funcs do
        if skill_override_check_funcs[i](actor, skill) then
            return true
        end
    end
end
SkillPickup.add_skill_check_func(function(actor, skill)
    if skill.skill_id == 16 or skill.skill_id == 70 or skill.skill_id == 71 then
        return false
    end
end)
SkillPickup.drop_skill = function(player, skill)
    for i = 1, #skill_check_funcs do
        if skill_check_funcs[i](player, skill) == false then
            return false
        end
    end
    for i = 1, #pre_local_drop_funcs do
        pre_local_drop_funcs[i](player, skill)
    end
    local skill_params = Utils.get_active_skill_diff(skill)
    if skill.ctm_arr_modifiers then
        local ctm_arr_modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for i = 0, ctm_arr_modifiers:size() - 1 do
            SkillModifierManager.remove_modifier(skill, ctm_arr_modifiers:get(i):get(0), i)
        end
    end
    gm.actor_skill_set(player, skill.slot_index, 0)
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
---@param fn function (skillPickup)
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
            if k == "ctm_arr_modifiers" then
                for modifier_index, modifier_table in pairs(v) do
                    local modifier = SkillModifierManager.get_modifier(modifier_table[1])
                    if modifier.add_inst_func then
                        local params = {}
                        for i = 2, #modifier_table do
                            params[#params + 1] = modifier_table[i]
                        end
                        modifier.add_inst_func(target, skill_params, x, y, modifier_index, table.unpack(params))
                    end
                end
            end
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
        post_create_funcs[i](target)
    end
end
local activate_skill
local set_skill = function(player, interactable)
    gm.actor_skill_set(player, interactable.slot_index, interactable.skill_id)
    local skill = gm.array_get(player.skills, interactable.slot_index).active_skill
    if interactable.stock then
        skill.stock = interactable.stock
        gm._mod_ActorSkill_recalculateStats(skill)
    end
    if interactable.ctm_sprite ~= nil then
        skill.ctm_sprite = interactable.ctm_sprite
    end
    if interactable.ctm_arr_modifiers ~= nil then
        local modifiers = Array.wrap(interactable.ctm_arr_modifiers)
        for i = 0, modifiers:size() - 1 do
            local modifier = modifiers:get(i)
            local modifier_args = {}
            for j = 1, modifier:size() - 1 do
                table.insert(modifier_args, modifier:get(j))
            end
            SkillModifierManager.add_modifier(skill, modifier:get(0), table.unpack(modifier_args))
        end
    end
    gm.instance_destroy(interactable.id)
end
local function init()
    local skillPickup = Object.new("hinyb", "skillPickup", Object.PARENT.interactable)
    SkillPickup.skillPickup_object_index = skillPickup.value
    skillPickup.obj_sprite = 114
    skillPickup.obj_depth = 5.0
    gm.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        local inst = args[1].value
        if inst.__object_index == skillPickup.value then
            local actor = args[2].value
            if actor.object_index == gm.constants.oP and actor.is_local or actor.object_index ~= gm.constants.oP and
                not Net.is_client() then
                if inst.skill_id ~= nil and inst.slot_index ~= nil then
                    local skill = gm.array_get(actor.skills, inst.slot_index).active_skill
                    if not can_skill_override(actor, skill) then
                        if SkillPickup.drop_skill(actor, skill) == false then
                            return false
                        end
                    end
                    activate_skill(actor, inst)
                    for i = 1, #post_local_pickup_funcs do
                        post_local_pickup_funcs[i](actor, inst.slot_index)
                    end
                end
            end
            inst.activator = actor
            return false
        end
    end)
    local active_skill_packet = Packet.new()
    active_skill_packet:onReceived(function(message, player)
        local Player = message:read_instance().value
        local Interactable = message:read_instance().value
        if Net.is_host() then
            local sync_message = active_skill_packet:message_begin()
            sync_message:write_instance(Player)
            sync_message:write_instance(Interactable)
            sync_message:send_exclude(player)
        end
        set_skill(Player, Interactable)
    end)
    local function activate_skill_send(Player, Interactable)
        local sync_message = active_skill_packet:message_begin()
        sync_message:write_instance(Player)
        sync_message:write_instance(Interactable)
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
            init_skillPickup(skill, skill_params)
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
    gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
        if Net.is_single() then
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params)
                end
                local skill = gm.instance_create(x - 20, y - 20, skillPickup.value)
                init_skillPickup(skill, skill_params, x - 20, y - 20)
            end
            activate_skill = function(Player, Interactable)
                set_skill(Player, Interactable)
            end
        elseif Net.is_host() then
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params)
                end
                drop_skill(x, y, skill_params)
            end
            activate_skill = function(Player, Interactable)
                local sync_message = activate_skill_send(Player, Interactable)
                sync_message:send_to_all()
                set_skill(Player, Interactable)
            end
        else
            SkillPickup.skill_create = function(x, y, skill_params)
                for i = 1, #pre_create_funcs do
                    pre_create_funcs[i](skill_params)
                end
                local sync_message = drop_skill_send(skill_params)
                sync_message:send_to_host()
            end
            activate_skill = function(Player, Interactable)
                local sync_message = activate_skill_send(Player, Interactable)
                sync_message:send_to_host()
                set_skill(Player, Interactable)
            end
        end
    end)
end
Initialize(init)
return SkillPickup
