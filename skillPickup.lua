require("Utils")
local function setupSkill(target, skill_params)
    gm._mod_instance_set_sprite(target, skill_params.skill_sprite)
    target.image_index = skill_params.skill_subimage
    target.translation_key = skill_params.skill_translation_key
    target.skill_id = skill_params.skill_id
    target.slot_index = skill_params.slot_index
    target.text = gm.ds_map_find_value(Utils.get_lang_map(), target.translation_key .. ".name")
end
local drop_skill_send, activate_skill_send, drop_skill
skill_create = function(player, skill_params)
    log.error("skill_create hasn't been initialized")
end
local function init()
    local active_skill_packet = Packet.new()
    active_skill_packet:onReceived(function(message, player)
        local Player = message:read_instance().value
        local Interactable = message:read_instance().value
        if Net.get_type() == Net.TYPE.host then
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
        if Net.get_type() == Net.TYPE.host then
            sync_message:send_to_all()
        else
            sync_message:send_to_host()
        end
        gm.actor_skill_set(Player, Interactable.slot_index, Interactable.skill_id)
        gm.instance_destroy(Interactable.id)
    end

    local skillPickup = Interactable.new("hinyb", "skillPickup")
    skillPickup.obj_sprite = 114
    skillPickup:add_callback("onActivate", function(Interactable, Player)
        if Interactable.value.skill_id ~= nil and Interactable.value.slot_index ~= nil then
            local skill = gm.variable_instance_get(Player.value.id, "skills")[Interactable.value.slot_index + 1]
                              .active_skill
            if skill.skill_id ~= 0 then
                gm.actor_skill_set(Player.value, skill.slot_index, 0)
                skill_create(Player.value, {
                    slot_index = skill.slot_index,
                    skill_id = skill.skill_id,
                    skill_sprite = skill.sprite,
                    skill_translation_key = string.sub(skill.name, 1, -6),
                    skill_subimage = skill.subimage
                })
            end
            activate_skill_send(Player.value, Interactable.value)
        end
    end)

    local drop_skill_packet = Packet.new()
    drop_skill_packet:onReceived(function(message, player)
        local slot_index = message:read_int()
        local skill_id = message:read_int()
        local skill_sprite = message:read_int()
        local skill_translation_key = message:read_string()
        local skill_subimage = message:read_int()
        local skill_params = {
            slot_index = slot_index,
            skill_id = skill_id,
            skill_sprite = skill_sprite,
            skill_translation_key = skill_translation_key,
            skill_subimage = skill_subimage
        }
        if Net.get_type() == Net.TYPE.host then
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
        sync_message:write_int(skill_params.skill_sprite)
        sync_message:write_string(skill_params.skill_translation_key)
        sync_message:write_int(skill_params.skill_subimage)
        if skill ~= nil then
            sync_message:write_instance(skill)
            sync_message:send_to_all()
        else
            sync_message:send_to_host()
        end
    end
    drop_skill = function(x, y, skill_params)
        local skill = gm.instance_create(x, y, skillPickup.value)
        gm.call("gml_Script_interactable_sync", skill, skill)
        setupSkill(skill, skill_params)
        drop_skill_send(skill_params, skill)
    end
end
local function update_multiplayer(host)
    if host then
        skill_create = function(player, skill_params)
            drop_skill(player.x, player.y, skill_params)
        end
    else
        skill_create = function(player, skill_params)
            drop_skill_send(skill_params)
        end
    end
end
gm.post_script_hook(gm.constants.update_multiplayer_globals, function(self, other, result, args)
    update_multiplayer(args[2].value)
end)
Initialize(init)
