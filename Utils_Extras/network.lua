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
    local type_ = type(data)
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
    local size = #table
    message:write_byte(size)
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

local code_str = {nil, [[
if not Net.is_single() then
    if Net.is_host() then
        ]], nil, [[
    else
    ]], nil, [[
    end
end
]], nil}
local function compile_write_str(type_table)
    local write_str_table = {"local message = packet:message_begin()"}
    for i = 1, #type_table do
        local type = type_table[i]
        local param_name = "a" .. tostring(i)
        local str, count = message_map_write_table[type]:gsub("__replaceit__", param_name)
        if count == 0 then
            str = str .. "(" .. param_name .. ")"
        end
        table.insert(write_str_table, str)
    end
    return table.concat(write_str_table, "\n")
end
local function compile_read_str(type_table)
    local read_str_table = {}
    for i = 1, #type_table do
        local type = type_table[i]
        local str = message_map_read_table[type]
        local param_name = "a" .. tostring(i)
        table.insert(read_str_table, param_name .. " = " .. str)
    end
    return table.concat(read_str_table, "\n")
end
Utils.create_sync_func = function(fn_str, type_table, env)
    fn_str = fn_str .. "\n"
    local packet = Packet.new()
    env = env or {}
    env.packet = packet
    env = setmetatable(env, {
        __index = envy.getfenv(2)
    })
    local write_str = compile_write_str(type_table)
    local read_str = compile_read_str(type_table)
    code_str[1] = read_str .. "\n"
    code_str[3] = write_str .. "\n" .. "message:send_exclude(player)" .. "\n"
    code_str[5] = ""
    code_str[7] = fn_str .. "\n"
    local on_recived_str = "return function(message, player)\n" .. table.concat(code_str) .. "\nend"
    local on_recived_func = load(on_recived_str, nil, "t", env)()
    packet:onReceived(on_recived_func)
    code_str[1] = ""
    code_str[3] = write_str .. "\n" .. "message:send_to_all()" .. "\n"
    code_str[5] = write_str .. "\n" .. "message:send_to_host()" .. "\n"
    code_str[7] = fn_str
    local params_table = {}
    for i = 1, #type_table do
        table.insert(params_table, "a" .. tostring(i))
    end
    local sync_func_str = "return function(" .. table.concat(params_table, ", ") .. ")\n" .. table.concat(code_str) ..
                              "\nend"
    local sync_func = load(sync_func_str, nil, "t", env)()
    return sync_func
end
