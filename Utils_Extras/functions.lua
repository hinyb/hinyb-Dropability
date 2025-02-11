Initialize(function()
    local heat_add_packet = Packet.new()
    heat_add_packet:onReceived(function(message, player)
        local actor = message:read_instance().value
        local number = message:read_double()
        gm.call("gml_Script__survivor_miner_heat_add", actor, actor, actor, number)
        if Net.is_host() then
            local message = heat_add_packet:message_begin()
            message:write_instance(actor)
            message:write_double(number)
            message:send_exclude(player)
        end
    end)
    Utils.miner_heat_add_sync = function(actor, number)
        gm.call("gml_Script__survivor_miner_heat_add", actor, actor, actor, number)
        if Net.is_single() then
            return
        end
        local message = heat_add_packet:message_begin()
        message:write_instance(actor)
        message:write_double(number)
        if Net.is_host() then
            message:send_to_all()
        elseif Net.is_client() then
            message:send_to_host()
        end
    end
end)
