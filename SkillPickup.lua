SkillPickup = {}
SkillPickup.skill_create = function(x, y, skill_params)
    log.error("skill_create hasn't been initialized")
end
local drop_funcs = {}
SkillPickup.add_local_drop_callback = function(skill, fn)
    if drop_funcs[skill.parent.id] == nil then
        drop_funcs[skill.parent.id] = {}
        if drop_funcs[skill.parent.id][skill.slot_index] == nil then
            drop_funcs[skill.parent.id][skill.slot_index] = {}
        end
    end
    table.insert(drop_funcs[skill.parent.id][skill.slot_index], fn)
end
SkillPickup.remove_local_drop_callback = function(skill)
    drop_funcs[skill.parent.id][skill.slot_index] = nil
end
local pick_funcs = {}
SkillPickup.add_local_pick_callback = function(skill, fn)
    if pick_funcs[skill.parent.id] == nil then
        pick_funcs[skill.parent.id] = {}
        if pick_funcs[skill.parent.id][skill.slot_index] == nil then
            pick_funcs[skill.parent.id][skill.slot_index] = {}
        end
    end
    table.insert(pick_funcs[skill.parent.id][skill.slot_index], fn)
end
SkillPickup.remove_local_pick_callback = function(skill)
    pick_funcs[skill.parent.id][skill.slot_index] = nil
end
SkillPickup.drop_skill = function(player, skill)
    for _,funcs in pairs(drop_funcs) do
        for _,funcs_ in pairs(funcs) do
            for k = 1, #funcs_ do
                funcs_[k](skill)
            end
        end
    end
    Utils.empty_skill_num = Utils.empty_skill_num + 1
    local skill_params = Utils.get_active_skill_diff(skill)
    if skill.ctm_arr_modifiers then
        local ctm_arr_modifiers = Array.wrap(skill.ctm_arr_modifiers)
        for i = 0, ctm_arr_modifiers:size() - 1 do
            SkillModifier.remove_modifier(skill, ctm_arr_modifiers:get(i):get(0))
        end
    end
    gm.actor_skill_set(player, skill.slot_index, 0)
    SkillPickup.skill_create(player.x, player.y, skill_params)
end
local function setupSkill(target, skill_params)
    local default_skill = Class.SKILL:get(skill_params.skill_id)
    target.sprite_index = default_skill:get(4)
    target.image_index = default_skill:get(5)
    target.text = gm.ds_map_find_value(Utils.get_lang_map(), default_skill:get(2))
    for k, v in pairs(skill_params) do
        if type(v) == "table" then
            target[k] = Utils.create_array_from_table(v)
        else
            target[k] = v
            if k == "subimage" then
                target.image_index = v
            elseif k == "name" then
                target.text = gm.ds_map_find_value(Utils.get_lang_map(), v)
            end
        end
    end
end
local activate_skill
local set_skill = function(player, interactable)
    gm.actor_skill_set(player, interactable.slot_index, interactable.skill_id)
    local skill = gm.array_get(player.skills, interactable.slot_index).active_skill
    local diff_check_table = Utils.get_skill_diff_check_table()
    for k, v in pairs(diff_check_table) do
        if interactable[k] ~= nil then
            skill[k] = interactable[k]
        end
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
            SkillModifier.add_modifier(skill, modifier:get(0), table.unpack(modifier_args))
        end
    end
    gm.instance_destroy(interactable.id)
end
local function init()
    local skillPickup = Interactable.new("hinyb", "skillPickup")
    skillPickup.obj_sprite = 114
    skillPickup:add_callback("onActivate", function(Interactable, Player)
        if Player.value.is_local then
            if Interactable.value.skill_id ~= nil and Interactable.value.slot_index ~= nil then
                local skill = gm.array_get(Player.value.skills, Interactable.value.slot_index).active_skill
                if skill.skill_id ~= 0 then
                    SkillPickup.drop_skill(Player.value, skill)
                end
                for _,funcs in pairs(pick_funcs) do
                    for _,funcs_ in pairs(funcs) do
                        for k = 1, #funcs_ do
                            funcs_[k](skill)
                        end
                    end
                end
                Utils.empty_skill_num = Utils.empty_skill_num - 1
                activate_skill(Player.value, Interactable.value)
            end
        end
    end)

    local active_skill_packet = Packet.new()
    active_skill_packet:onReceived(function(message, player)
        local Player = message:read_instance().value
        local Interactable = message:read_instance().value
        if Utils.get_net_type() == Net.TYPE.host then
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
        setupSkill(skill, skill_params)
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
        for i = 1, ext_num do
            local mem = message:read_string()
            local val = message:read_string()
            if mem:sub(1, 4) == "arr_" then
                skill_params[mem:sub(5, -1)] = Utils.simple_string_to_table(val)
            else
                skill_params[mem] = Utils.parse_string_to_value(val)
            end
        end
        if Utils.get_net_type() == Net.TYPE.host then
            drop_skill(player.x, player.y, skill_params)
        else
            local skill = message:read_instance().value
            setupSkill(skill, skill_params)
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
        drop_funcs = {}
        pick_funcs = {}
        if Utils.get_net_type() == Net.TYPE.single then
            SkillPickup.skill_create = function(x, y, skill_params)
                local skill = gm.instance_create(x - 20, y - 20, skillPickup.value)
                setupSkill(skill, skill_params)
            end
            activate_skill = function(Player, Interactable)
                set_skill(Player, Interactable)
            end
        elseif Utils.get_net_type() == Net.TYPE.host then
            SkillPickup.skill_create = function(x, y, skill_params)
                drop_skill(x, y, skill_params)
            end
            activate_skill = function(Player, Interactable)
                local sync_message = activate_skill_send(Player, Interactable)
                sync_message:send_to_all()
                set_skill(Player, Interactable)
            end
        else
            SkillPickup.skill_create = function(x, y, skill_params)
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
