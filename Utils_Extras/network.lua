local origin_types = {"string", "double", "short", "byte", "half", "int", "uint", "instance", "ushort", "float"}
Utils.param_type = {
    array = 0,
    table = 1,
    va_list = 2
}
local param_type_size = Utils.table_get_length(Utils.param_type)
for i = 1, #origin_types do
    local type = origin_types[i]
    Utils.param_type[type] = param_type_size
    param_type_size = param_type_size + 1
end
function Utils.get_data_type(data)
    local type_ = lua_type(data)
    if type_ == "number" then
        return Utils.param_type.double
    elseif type_ == "string" then
        return Utils.param_type.string
    elseif type_ == "table" then
        return Utils.param_type.table
    elseif type_ == "userdata" then
        local mt = getmetatable(data)
        if mt.__name == "sol.CInstance*" then
            return Utils.param_type.instance
        end
    end
    log.error("Can't get this data's type", data)
end
function Utils.message_write_table(message, table)
    message:write_byte(Utils.table_get_length(table))
    for key, value in pairs(table) do
        local type = Utils.get_data_type(value)
        message:write_byte(type)
        message:write_string(key)
        if type == Utils.param_type.instance then
            message:write_instance(value)
        elseif type == Utils.param_type.string then
            message:write_string(value)
        elseif type == Utils.param_type.double then
            message:write_double(value)
        elseif type == Utils.param_type.table then
            Utils.message_write_table(message, value)
        else
            log.error("Can't handle" .. type)
        end
    end
end
local message_map_write_table = {
    [Utils.param_type.table] = "Utils.message_write_table(message, __replaceit__)"
}
function Utils.message_read_table(message)
    local size = message:read_byte()
    local table = {}
    for _ = 1, size do
        local type = message:read_byte()
        local key = message:read_string()
        local value
        if type == Utils.param_type.instance then
            value = message:read_instance().value
            table[key] = value
        elseif type == Utils.param_type.string then
            value = message:read_string()
            table[key] = value
        elseif type == Utils.param_type.double then
            value = message:read_double()
            table[key] = value
        elseif type == Utils.param_type.table then
            table[key] = Utils.message_read_table(message)
        else
            log.error("Can't handle" .. type)
        end
    end
    return table
end
local message_map_read_table = {
    [Utils.param_type.table] = "Utils.message_read_table(message)"
}
for i = 1, #origin_types do
    local type = origin_types[i]
    local param_type_number = Utils.param_type[type]
    message_map_write_table[param_type_number] = "message:write_" .. type
    message_map_read_table[param_type_number] = "message:read_" .. type .. "()"
    if type == "instance" then
        message_map_read_table[param_type_number] = message_map_read_table[param_type_number] .. ".value"
    end
end

local function compile_write_str(type_table)
    local lines = {}
    for i, type in ipairs(type_table) do
        local param_name = "a" .. tostring(i)
        local str, count = message_map_write_table[type]:gsub("__replaceit__", param_name)
        lines[i] = count > 0 and str or (string.format("%s(%s)", str, param_name))
    end
    return table.concat(lines, "\n")
end
local function compile_read_str(type_table)
    local lines = {}
    for i, type in ipairs(type_table) do
        lines[i] = string.format("local a%d = %s", i, message_map_read_table[type])
    end
    return table.concat(lines, "\n")
end
local function gen_params_str(count)
    local t = {}
    for i = 1, count do t[i] = "a" .. tostring(i) end
    return table.concat(t, ", ")
end
Utils.create_sync_func = function(fn_str, type_table, env)
    local packet = Packet.new(Utils.get_debug_id(3))
    env = setmetatable(env or {}, {
        __index = envy.getfenv(2)
    })
    env.packet = packet
    local params_str = gen_params_str(#type_table)
    local write_str = compile_write_str(type_table)
    local send_func = load(string.format(
        [[return function(message, %s)
            %s
        end]], params_str, write_str), nil, "t", env)()
    
    local read_str = compile_read_str(type_table)
    local on_recived_func = load(string.format([[
        return function(message, player)
            %s
            if Net.online then
                if Net.host then
                    packet:send_exclude(player, %s)
                end
            end
            %s
        end
    ]], read_str, params_str, fn_str), nil, "t", env)()
    packet:set_serializers(send_func, on_recived_func)

    local sync_func_code = string.format([[
        return function(%s)
            if Net.online then
                if Net.host then
                    packet:send_to_all(%s)
                else
                    packet:send_to_host(%s)
                end
            end
            %s
        end
    ]], params_str, params_str, params_str, fn_str)

    return load(sync_func_code, nil, "t", env)()
end
