local function setupSkill(target, skill_params)
    for k,v in pairs(skill_params) do
        target[k] = v
    end
    target.text = gm.ds_map_find_value(Utils.get_lang_map(), target.translation_key .. ".name")
end
local drop_skill_send, activate_skill_send, drop_skill, activate_skill
skill_create = function(x, y, skill_params)
    log.error("skill_create hasn't been initialized")
end
local function init()
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
        gm.actor_skill_set(Player, Interactable.slot_index, Interactable.skill_id)
        gm.instance_destroy(Interactable.id)
    end)
    activate_skill_send = function(Player, Interactable)
        local sync_message = active_skill_packet:message_begin()
        sync_message:write_instance(Player)
        sync_message:write_instance(Interactable)
        return sync_message
    end

    local skillPickup = Interactable.new("hinyb", "skillPickup")
    skillPickup.obj_sprite = 114
    skillPickup:add_callback("onActivate", function(Interactable, Player)
        if Interactable.value.skill_id ~= nil and Interactable.value.slot_index ~= nil then
            local skill = gm.variable_instance_get(Player.value.id, "skills")[Interactable.value.slot_index + 1]
                              .active_skill
            if skill.skill_id ~= 0 then
                gm.actor_skill_set(Player.value, skill.slot_index, 0)
                skill_create(Player.value.x, Player.value.y, {
                    slot_index = skill.slot_index,
                    skill_id = skill.skill_id,
                    sprite_index = skill.sprite,
                    translation_key = string.sub(skill.name, 1, -6),
                    image_index = skill.subimage
                })
            end
            activate_skill (Player, Interactable)
            gm.actor_skill_set(Player.value, Interactable.value.slot_index, Interactable.value.skill_id)
            Interactable:destroy()
        end
    end)

    local drop_skill_packet = Packet.new()
    drop_skill_packet:onReceived(function(message, player)
        local slot_index = message:read_int()
        local skill_id = message:read_int()
        local sprite_index = message:read_int()
        local translation_key = message:read_string()
        local image_index = message:read_int()
        local skill_params = {
            slot_index = slot_index,
            skill_id = skill_id,
            sprite_index = sprite_index,
            translation_key = translation_key,
            image_index = image_index
        }
        if Utils.get_net_type() == Net.TYPE.host then
            drop_skill(player.x, player.y, skill_params)
        else
            local skill = message:read_instance().value
            setupSkill(skill, skill_params)
        end
    end)
    drop_skill_send = function(skill_params, skill)
        local sync_message = drop_skill_packet:message_begin()
        sync_message:write_int(skill_params.slot_index)
        sync_message:write_int(skill_params.skill_id)
        sync_message:write_int(skill_params.sprite_index)
        sync_message:write_string(skill_params.translation_key)
        sync_message:write_int(skill_params.image_index)
        return sync_message
    end
    drop_skill = function(x, y, skill_params)
        local skill = gm.instance_create(x - 20, y - 20, skillPickup.value)
        setupSkill(skill, skill_params)
        gm.call("gml_Script_interactable_sync", skill, skill)
        local sync_message = drop_skill_send(skill_params, skill)
        sync_message:write_instance(skill)
        sync_message:send_to_all()
    end
    gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    if Utils.get_net_type() == Net.TYPE.single then
        skill_create = function(x, y, skill_params)
            local skill = gm.instance_create(x - 20, y - 20, skillPickup.value)
            setupSkill(skill, skill_params)
        end
        activate_skill = function (Player, Interactable) end
    elseif Utils.get_net_type() == Net.TYPE.host then
        skill_create = function(x, y, skill_params)
            drop_skill(x, y, skill_params)
        end
        activate_skill = function (Player, Interactable)
            local sync_message = activate_skill_send(Player, Interactable)
            sync_message:send_to_all()
        end
    else
        skill_create = function(x, y, skill_params)
            local sync_message = drop_skill_send(skill_params)
            sync_message:send_to_host()
        end
        activate_skill = function (Player, Interactable)
            local sync_message = activate_skill_send(Player, Interactable)
            sync_message:send_to_host()
        end
    end
end)
end
Initialize(init)
