HookSystem.clean_hook()
local drop_item_send
local drop_item_id_list = {}
drop_item = function(player, item_id, item_object_id)
    log.error("drop_item hasn't been initialized")
end
local function init()
    local drop_item_packet = Packet.new("drop_item_packet")
    drop_item_packet:set_serializers(function(buffer, item_id, item_object_id)
        buffer:write_int(item_id)
        buffer:write_int(item_object_id)
    end, function(buffer, player)
        local item_id = buffer:read_int()
        local item_object_id = buffer:read_int()
        drop_item(player.value, item_id, item_object_id)
    end)

    drop_item_send = function(player, item_id, item_object_id)
        drop_item_packet:send_to_host(item_id, item_object_id)
    end
end

HookSystem.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    if not Net.client then
        drop_item = function(player, item_id, item_object_id)
            if gm.item_count(player, item_id, 0) >= 1 then
                gm.item_take(player, item_id, 1, 0)
                local x, y = Utils.get_actual_position(player)
                local item = gm.instance_create(x, y, item_object_id)
                table.insert(drop_item_id_list, item.id)
            end
        end
    else
        drop_item = drop_item_send
    end
end)

local cached_dup_num
local pickup_is_dropped = false
HookSystem.pre_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    if (cached_dup_num ~= nil) then
        gm.array_set(args[1].value.inventory_item_stack, 95, cached_dup_num)
    end
end)
HookSystem.pre_script_hook(gm.constants.item_give, function(self, other, result, args)
    local actor = args[1].value
    for index, item_id in pairs(drop_item_id_list) do
        if (item_id == actor.id) then
            cached_dup_num = gm.array_get(actor.inventory_item_stack, 95)
            gm.array_set(actor.inventory_item_stack, 95, 0)
            table.remove(drop_item_id_list, index)
            pickup_is_dropped = true
        end
    end
end)
HookSystem.post_script_hook(gm.constants.item_give, function(self, other, result, args)
    if pickup_is_dropped then
        cached_dup_num = nil
        pickup_is_dropped = false
    end
end)
HookSystem.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drop_item_id_list = {}
end)
Initialize.add_hotloadable(init)
