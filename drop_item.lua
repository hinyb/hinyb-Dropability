local drop_item_send
local drop_item_id_list = {}
drop_item = function(player, item_id, item_object_id)
    log.error("drop_item hasn't been initialized")
end
local function init()
    local drop_item_packet = Packet.new()
    drop_item_packet:onReceived(function(message, player)
        local item_id = message:read_int()
        local item_object_id = message:read_int()
        drop_item(player.value, item_id, item_object_id)
    end)
    drop_item_send = function(player, item_id, item_object_id)
        local sync_message = drop_item_packet:message_begin()
        sync_message:write_int(item_id)
        sync_message:write_int(item_object_id)
        sync_message:send_to_host()
    end
end

gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    if Utils.get_net_type() == Net.TYPE.host or Utils.get_net_type() == Net.TYPE.single then
        drop_item = function(player, item_id, item_object_id)
            if gm.item_count(player, item_id, 0) >= 1 then
                gm.item_take(player, item_id, 1, 0)
                local x, y = Utils.get_player_actual_position(player)
                local item = gm.instance_create_depth(x, y, 0, item_object_id)
                table.insert(drop_item_id_list, item.id)
            end
        end
    else
        drop_item = drop_item_send
    end
end)

local cached_dup_num
local pickup_is_dropped = false
gm.pre_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    if (cached_dup_num ~= nil) then
        gm.array_set(other.inventory_item_stack, 95, cached_dup_num)
    end
end)
gm.pre_script_hook(gm.constants.item_give, function(self, other, result, args)
    for index, item_id in pairs(drop_item_id_list) do
        if (item_id == self.id) then
            cached_dup_num = gm.array_get(other.inventory_item_stack, 95)
            gm.array_set(other.inventory_item_stack, 95, 0)
            table.remove(drop_item_id_list, index)
            pickup_is_dropped = true
        end
    end
end)
gm.post_script_hook(gm.constants.item_give, function(self, other, result, args)
    if pickup_is_dropped then
        cached_dup_num = nil
        pickup_is_dropped = false
    end
end)
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drop_item_id_list = {}
end)
Initialize(init)
