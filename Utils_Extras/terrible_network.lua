
Utils.packet_type = {
    not_forward = 0,
    forward = 1
}
-- May need use this to code cleanup
-- It seems like _mod_net_message_getUniqueID's unique id is only unique within each mod
-- Be careful this function should use in Initialize.
---@param onReceived function(player(Wrapped, host only), ...) The function will be called when packet receive.
---@param type_table table(Utils.param_type) The table of params' types.
---@return function(Utils.packet_type, ...)  
Utils.create_packet = function(onReceived, type_table)
    local sync_packet = Packet.new()
    sync_packet:onReceived(function(message, player)
        local num = message:read_byte()
        local type = message:read_byte()
        local sync_message
        if type == Utils.packet_type.forward then
            sync_message = sync_packet:message_begin()
            sync_message:write_byte(num)
            sync_message:write_byte(0)
        end
        local params_table = {}
        for i = 1, num do
            local value
            if type_table[i] == Utils.param_type.Instance then
                value = message:read_instance().value
                table.insert(params_table, value)
            elseif type_table[i] == Utils.param_type.table then
                value = message:read_string()
                table.insert(params_table, Utils.simple_string_to_table(value))
            elseif type_table[i] == Utils.param_type.array then
                value = message:read_string()
                table.insert(params_table, Utils.create_array_from_table(Utils.simple_string_to_table(value)))
            elseif type_table[i] == Utils.param_type.int then
                value = message:read_int()
                table.insert(params_table, value)
            elseif type_table[i] == Utils.param_type.half then
                value = message:read_half()
                table.insert(params_table, value)
            elseif type_table[i] == Utils.param_type.number then
                value = message:read_string()
                table.insert(params_table, Utils.parse_string_to_value(value))
            elseif type_table[i] == Utils.param_type.string then
                value = message:read_string()
                table.insert(params_table, value)
            elseif type_table[i] == Utils.param_type.va_list then
                local param_num = message:read_byte()
                for _ = 1, param_num do
                    table.insert(value, message:read_float())
                end
            else
                log.error("Can't handle" .. type_table[i])
            end
            if type == Utils.packet_type.forward then
                if type_table[i] == Utils.param_type.Instance then
                    sync_message:write_instance(value)
                elseif type_table[i] == Utils.param_type.int then
                    sync_message:write_int(value)
                elseif type_table[i] == Utils.param_type.half then
                    message:write_half(value)
                elseif type_table[i] == Utils.param_type.va_list then
                    sync_message:write_byte(#value)
                    for j = 1, #value do
                        sync_message:write_double(value[j])
                    end
                else
                    sync_message:write_string(value)
                end
            end
        end
        onReceived(player, table.unpack(params_table))
        if type == Utils.packet_type.forward then
            sync_message:send_exclude(player)
        end
    end)
    return function(type, ...)
        local sync_message = sync_packet:message_begin()
        sync_message:write_byte(select("#", ...))
        sync_message:write_byte(type)
        for i, v in ipairs({...}) do
            if type_table[i] == Utils.param_type.Instance then
                sync_message:write_instance(v)
            elseif type_table[i] == Utils.param_type.table then
                sync_message:write_string(Utils.simple_table_to_string(v))
            elseif type_table[i] == Utils.param_type.array then
                sync_message:write_string(Utils.simple_table_to_string(Utils.create_table_from_array(v)))
            elseif type_table[i] == Utils.param_type.int then
                sync_message:write_int(v)
            elseif type_table[i] == Utils.param_type.half then
                sync_message:write_half(v)
            elseif type_table[i] == Utils.param_type.number then
                sync_message:write_string(tostring(v))
            elseif type_table[i] == Utils.param_type.string then
                sync_message:write_string(v)
            else
                log.error("Can't handle" .. type_table[i])
            end
        end
        return sync_message
    end
end
Utils.sync_instance_send = function(inst, table_num, sync_table)
    log.error("sync_instance_send hasn't been initialized")
end
Utils.set_and_sync_inst_from_table = function(inst, table)
    for mem, val in pairs(table) do
        inst[mem] = val
    end
    if not Net.is_single() then
        Utils.sync_instance_send(inst, Utils.table_get_length(table), table)
    end
end
Initialize(function ()
    local sync_instance_packet = Packet.new()
    sync_instance_packet:onReceived(function(message, player)
        local inst = message:read_instance().value
        local num = message:read_int()
        local function parse_string(sync_message)
            for _ = 1, num do
                local mem = message:read_string()
                if mem == nil then
                    break
                end
                local val = message:read_string()
                if mem:sub(1, 4) == "arr_" then
                    local mem_ = mem:sub(5, -1)
                    local val_table = Utils.simple_string_to_table(val)
                    inst[mem_] = Utils.create_array_from_table(val_table)
                else
                    inst[mem] = Utils.parse_string_to_value(val)
                end
                if sync_message then
                    sync_message:write_string(mem)
                    sync_message:write_string(val)
                end
            end
        end
        if Net.is_host() then
            local sync_message = sync_instance_packet:message_begin()
            sync_message:write_instance(inst)
            sync_message:write_int(num)
            parse_string(sync_message)
            sync_message:send_exclude(player)
        else
            parse_string()
        end
    end)
    Utils.sync_instance_send = function(inst, table_num, sync_table)
        local sync_message = sync_instance_packet:message_begin()
        sync_message:write_instance(inst)
        sync_message:write_int(table_num)
        for k, v in pairs(sync_table) do
            if type(v) == "table" then
                k = "arr_" .. k
                v = Utils.simple_table_to_string(v)
            else
                v = tostring(v)
            end
            sync_message:write_string(k)
            sync_message:write_string(v)
        end
        if Net.is_host() then
            sync_message:send_to_all()
        else
            sync_message:send_to_host()
        end
    end
end)