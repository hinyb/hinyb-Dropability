local origin_types = {"string", "double", "short", "byte", "half", "half", "uint", "instance", "ushort", "float"}
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
--[[
local t = Message.wrap(1)
for name, _ in pairs(t.keys_locked) do
    if name:find("write_") then
        local type = name:sub(7)
        Utils.param_type[type] = Utils.table_get_length(Utils.param_type)
    end
end
Utils.log_information(Utils.param_type)
]]
Utils.packet_type = {
    not_forward = 0,
    forward = 1
}
local message_map_write_table = {}
local message_map_read_table = {}
for i = 1, #origin_types do
    local type = origin_types[i]
    local param_type_number = Utils.param_type[type]
    message_map_write_table[param_type_number] = "message:write_" .. type
    message_map_read_table[param_type_number] = "message:read_" .. type .. "()"
    if type == "instance" then
        message_map_read_table[param_type_number] = message_map_read_table[param_type_number] .. ".value"
    end
end

-- gm.actor_skill_set(a1, a2, a3)
--[[
if Net.is_single() then
return
if Net.is_host() then
    
else

end
]]
local code_str = {nil, [[
if Net.is_single() then
    return
end
if Net.is_host() then
    ]], nil, [[
else
]], nil, [[
end]]}
local function compile_write_str(type_table)
    local write_str_table = {"local message = packet:message_begin()"}
    for i = 1, #type_table do
        local type = type_table[i]
        local str = message_map_write_table[type]
        table.insert(write_str_table, str .. "(a" .. tostring(i) .. ")")
    end
    return table.concat(write_str_table, "\n")
end
local function compile_read_str(type_table)
    local read_str_table = {}
    for i = 1, #type_table do
        local type = type_table[i]
        local str = message_map_read_table[type]
        table.insert(read_str_table, "a" .. tostring(i) .. " = " .. str)
    end
    return table.concat(read_str_table, "\n")
end
Utils.create_sync_func = function(fn_str, type_table)
    fn_str = fn_str .. "\n"
    local packet = Packet.new()
    local env = setmetatable({packet = packet}, {__index = envy.getfenv()})
    local write_str = compile_write_str(type_table)
    local read_str = compile_read_str(type_table)

    code_str[1] = read_str .. "\n" .. fn_str .. "\n"
    code_str[3] = write_str .. "\n" .. "message:send_exclude(player)" .. "\n"
    code_str[5] = ""
    local on_recived_str = "return function(message, player)\n" .. table.concat(code_str) .. "\nend"
    local on_recived_func = load(on_recived_str, nil, "t", env)()
    packet:onReceived(on_recived_func)
    code_str[1] = fn_str
    code_str[3] = write_str .. "\n" .. "message:send_to_all()" .. "\n"
    code_str[5] = write_str .. "\n" .. "message:send_to_host()" .. "\n"
    local params_table = {}
    for i = 1, #type_table do
        table.insert(params_table, "a" .. tostring(i))
    end
    local sync_func_str = "return function(" .. table.concat(params_table, ", ") .. ")\n" .. table.concat(code_str) ..
                              "\nend"
    local sync_func = load(sync_func_str, nil, "t", env)()
    return sync_func
end
