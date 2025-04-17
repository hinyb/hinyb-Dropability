HookSystem.clean_hook()
math.randomseed(os.time())
Utils = {}
Utils.to_string_with_floor = function(number)
    return tostring(math.floor(number))
end
Utils.simple_shuffle_table = function(t)
    local n = #t
    for i = n, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end
Utils.get_actual_position = function(actor)
    if actor.following_player and actor.following_player ~= -4 then
        return actor.following_player.x, actor.following_player.y
    elseif actor.player_drone and actor.player_drone ~= -4 then
        return actor.player_drone.x, actor.player_drone.y
    else
        return actor.x, actor.y
    end
end
Utils.find_instance_with_m_id = function(object_index, m_id)
    local insts = Instance.find_all(object_index)
    for i = 1, #insts do
        local inst = insts[i].value
        if inst.m_id == m_id then
            return inst
        end
    end
    log.error("Can't find instance", object_index, "with m_id", m_id, 2)
end
Utils.LCG_random = function(seed)
    local state = seed or os.time()
    return function(min, max)
        state = (state * 214013 + 2531011) % 2 ^ 32
        if min and max then
            return min + (state % (max - min + 1))
        end
    end
end
Utils.round = function(num)
    if num >= 0 then
        return math.floor(num + 0.5)
    else
        return math.ceil(num - 0.5)
    end
end
Utils.get_gaussian_random_within = function(min, max, mu, sigma)
    local random = Utils.get_gaussian_random(mu, sigma)
    if (min == nil or random >= min) and (max == nil or random <= max) then
        return random
    else
        return Utils.get_gaussian_random(mu, sigma)
    end
end
Utils.get_gaussian_random = function(mu, sigma)
    if sigma == nil then
        sigma = 1
    end
    local u1 = math.random()
    local u2 = math.random()
    local z0 = math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2)
    return mu + sigma * z0
end
Utils.get_random_buff = function(is_timed, isdebuff)
    while true do
        local buff_id = math.random(0, Class.Buff:get_size())
        if is_timed == nil or Class.Buff:get(buff_id):get(13) == is_timed then
            if isdebuff == nil or Class.Buff:get(buff_id):get(14) == isdebuff then
                return buff_id
            end
        end
    end
end
Utils.get_random_seed = function()
    return gm.array_get(gm.rng_create(), 0)
end
Utils.clamp = function(value, min_value, max_value)
    return math.max(min_value, math.min(value, max_value))
end
Utils.lerp = function(a, b, t)
    return a + (b - a) * t
end
Utils.degtorad = function(degrees)
    return degrees * (math.pi / 180)
end
Utils.find_item_with_localized = function(name, player)
    local inventory = Array.wrap(player.inventory_item_order)
    for i = 0, inventory:size() - 1 do
        local val = inventory:get(i)
        local item = Class.ITEM:get(val)
        if (name == Language.translate_token(item:get(2))) then
            return item:get(8), val
        end
    end
end
Utils.log_information = function(info, offset)
    if offset == nil then
        offset = 0
    end
    local prefix = ""
    for i = 1, offset do
        prefix = "      " .. prefix
    end
    local str = info
    if type(info) == "userdata" then
        local mt = getmetatable(info)
        if mt.__name == "sol.CScriptRef*" then
            str = info.script_name
        end
    end
    log.info(prefix, str)
    if type(info) == "table" then
        for k, v in pairs(info) do
            log.info(prefix, k)
            Utils.log_information(v, offset + 1)
        end
        return
    end
    if gm.is_struct(info) then
        local names = gm.struct_get_names(info)
        if #names ~= 0 then
            for j, name in ipairs(names) do
                Utils.log_information(name .. " = ", offset + 1)
                Utils.log_information(gm.variable_struct_get(info, name), offset + 1)
            end
        end
        return
    end
    if gm.is_array(info) then
        local size = gm.array_length(info)
        for i = 0, size - 1 do
            local val = gm.array_get(info, i)
            Utils.log_information("[" .. i .. "]", offset + 1)
            Utils.log_information(val, offset + 1)
        end
        return
    end
end
Utils.check_table_is_array = function(table)
    local index = 1
    for k, _ in pairs(table) do
        if k ~= index then
            return false
        end
        index = index + 1
    end
    return true
end
Utils.simple_table_to_string = function(table)
    if type(table) ~= "table" then
        log.error("param must be table", 2)
        return "{}"
    end
    local result = "{"
    local is_array = Utils.check_table_is_array(table)
    for k, v in pairs(table) do
        if not is_array then
            result = result .. "[" .. '"' .. tostring(k) .. '"' .. "]="
        end
        if type(v) == "table" then
            result = result .. Utils.simple_table_to_string(v) .. ","
        else
            if type(v) == "string" then
                result = result .. '"' .. tostring(v) .. '"' .. ","
            else
                result = result .. tostring(v) .. ","
            end
        end
    end
    if Utils.table_get_length(table) > 1 then
        result = string.sub(result, 1, -2)
    end
    result = result .. "}"
    return result
end
Utils.point_distance = function(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end
Utils.remove_value = function(t, v)
    for i = 1, #t do
        if t[i] == v then
            table.remove(t, i)
            return
        end
    end
end
Utils.simple_string_to_table = function(string)
    if type(string) ~= "string" then
        log.error("param must be string", 2)
        return {}
    end
    local f, err = load("return " .. string)
    if not f then
        log.error("Can't convert" .. string .. " to table " .. err)
        return {}
    else
        return f()
    end
end
local function tobool(str)
    if str == "true" then
        return true, true
    elseif str == "false" then
        return true, false
    end
    return false, false
end
Utils.create_array_from_table = function(table)
    if not Utils.check_table_is_array(table) then
        log.error("Can't create an array from table", 2)
    end
    local res = gm.array_create(#table, 0)
    for i = 1, #table do
        local val_ = table[i]
        if type(val_) == "table" then
            gm.array_set(res, i - 1, Utils.create_array_from_table(val_))
        else
            gm.array_set(res, i - 1, val_)
        end
    end
    return res
end
Utils.create_table_from_array = function(arr)
    local res = {}
    for i = 0, gm.array_length(arr) - 1 do
        local val = gm.array_get(arr, i)
        if gm.is_array(val) then
            val = Utils.create_table_from_array(val)
        end
        table.insert(res, val)
    end
    return res
end
Utils.parse_string_to_value = function(str)
    local ok, value = tobool(str)
    if ok then
        return value
    end
    return tonumber(str) or str
end
Utils.table_get_length = function(table)
    local result = 0
    for k, v in pairs(table) do
        result = result + 1
    end
    return result
end
function Utils.table_deep_copy(t)
    if type(t) ~= "table" then
        return t
    end
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = Utils.table_deep_copy(v)
    end
    return copy
end
Utils.get_inst_safe = function(inst)
    return type(inst) == "number" and gm.CInstance.instance_id_to_CInstance[inst] or inst
end
local instance_list = {}
local instance_create_flag = false
local instance_filter = {}
Utils.hook_instance_create = function(filter)
    instance_filter = filter or {}
    instance_create_flag = true
    instance_list = {}
end
Utils.get_tracked_instances = function()
    return instance_list
end
Utils.unhook_instance_create = function()
    instance_create_flag = false
end
HookSystem.post_script_hook(gm.constants.instance_create_depth, function(self, other, result, args)
    if instance_create_flag and not Helper.table_has(instance_filter, result.value:get_object_index_self()) then
        table.insert(instance_list, result.value)
    end
end)

local names = path.get_files(_ENV["!plugins_mod_folder_path"] .. "/Utils_Extras")
for _, name in ipairs(names) do
    require(name)
end

return Utils
