local random_skill_blacklist = {
    [0] = true, -- no skill
    [16] = true, -- enforcerZ2Reload Useless skills
    [70] = true, -- sniperZReload
    [71] = true, -- Spotter Recall   
    [178] = true, -- monsterWispBZ
    [179] = true, -- monsterBossZ    It seems like the Bosses' skills are different from normal skills
    [180] = true, -- monsterBossX
    [181] = true, -- monsterBossC
    [182] = true, -- monsterBossV
    [183] = true, -- monsterBossFinalZ
    [184] = true, -- monsterBossFinalX
    [185] = true, -- can't set
    [196] = true, -- monsterBrambleZ It need a head, and I don't think player can have a head.
    [205] = true, -- ImpfriendRecall
    [206] = true, -- can't set
    [207] = true -- can't set
}
local skill_id_to_slot = {
    [199] = 0, -- umbraWhip
    [200] = 0, -- umbraPunch
    [201] = 2, -- umbraExplode
    [202] = 2, -- umbraDash
    [203] = 2, -- umbraMissile
    [204] = 2 -- umbraSnipe
}
local net_type
local ResourceManager = gm.variable_global_get("ResourceManager_object")
math.randomseed(os.time())
Utils = {}
Utils.get_player_actual_position = function(player)
    if player.following_player ~= -4 then
        return player.following_player.x, player.following_player.y
    elseif player.player_drone ~= -4 then
        return player.player_drone.x, player.player_drone.y
    else
        return player.x, player.y
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
    log.error("Can't find instance" .. object_index .. "with m_id" .. m_id, 2)
end
Utils.get_empty_skill_num = function(inst)
    local result = 0
    local skill_arr = Array.wrap(inst.skills)
    for i = 1, skill_arr:size() do
        if skill_arr:get(i - 1).active_skill.skill_id == 0 then
            result = result + 1
        end
    end
    return result
end
Utils.check_asset_with_name = function(namespace, identifier)
    local lookup = ResourceManager.__namespacedAssetLookup
    if gm.variable_instance_exists(lookup, namespace) and gm.variable_instance_exists(lookup[namespace], identifier) then
        return lookup[namespace][identifier]
    else
        return false
    end
end
Utils.find_skill_id_with_name = function(name)
    for i = 0, Class.SKILL:size() - 1 do
        local skill = Class.SKILL:get(i)
        if type(skill) ~= "number" and skill:get(1) == name then
            return i
        end
    end
end
Utils.check_random_skill = function(skill_id)
    return not random_skill_blacklist[skill_id]
end
local need_scrap_bar_skill_id_list = {
    [129] = true,
    [133] = true,
    [131] = true,
    [132] = true,
    [135] = true,
    [136] = true
}
Utils.is_skill_need_scrap_bar = function(skill_id)
    return need_scrap_bar_skill_id_list[skill_id] or false
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
Utils.random_skill_id = function(random_seed)
    local random = Utils.LCG_random(random_seed)
    return function()
        while true do
            local rnd_skill_id = random(1, Class.SKILL:size()) - 1
            if Utils.check_random_skill(rnd_skill_id) then
                return rnd_skill_id
            end
        end
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
Utils.get_random = function(...)
    return math.random(...)
end
Utils.get_random_buff = function(is_timed, isdebuff)
    while true do
        local buff_id = Utils.get_random(0, Class.Buff:get_size())
        if is_timed == nil or Class.Buff:get(buff_id):get(13) == is_timed then
            if isdebuff == nil or Class.Buff:get(buff_id):get(14) == isdebuff then
                return buff_id
            end
        end
    end
end
Utils.get_slot_index_with_name = function(name)
    local type = string.match(name, ".*([ZXCV])")
    if type == "Z" then
        return 0
    elseif type == "X" then
        return 1
    elseif type == "C" then
        return 2
    elseif type == "V" then
        return 3
    end
    return nil
end
Utils.get_slot_index_with_skill_id = function(skill_id)
    local slot_index = skill_id_to_slot[skill_id] or Utils.get_slot_index_with_name(Class.SKILL:get(skill_id):get(1))
    if slot_index == nil then
        log.warning("Can't get the skill's slot_index " .. skill_id)
    end
    return slot_index
end
Utils.get_use_delay = function(skill_id)
    local skill = Class.SKILL:get(skill_id)
    return skill:get(14)
end
Utils.wrap_skill = function(skill_id)
    local skill = Class.SKILL:get(skill_id)
    if skill == nil or type(skill) == "number" then
        log.error("Can't get wrap skill with given skill_id" .. tostring(skill))
    end
    return {
        skill_id = skill_id,
        slot_index = Utils.get_slot_index_with_skill_id(skill_id),
        name = skill:get(2),
        description = skill:get(3),
        sprite_index = skill:get(4),
        image_index = skill:get(5),
        cooldown = skill:get(6),
        damage = skill:get(7),
        max_stock = skill:get(8)
    }
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
Utils.get_skill_diff_check_table = function()
    return {
        ["name"] = 2,
        ["description"] = 3,
        ["sprite"] = 4,
        ["subimage"] = 5,
        ["cooldown"] = 6,
        ["damage"] = 7,
        ["max_stock"] = 8,
        ["animation"] = 15
    }
end
Utils.get_active_skill_diff = function(skill)
    local result = {}
    result.skill_id = skill.skill_id
    result.slot_index = skill.slot_index
    result.stock = skill.stock
    --[[
    local default_skill = Class.SKILL:get(skill.skill_id)
    local diff_check_table = Utils.get_skill_diff_check_table()
    if skill.disable_stock_regen ~= not default_skill:get(10) then
        result["disable_stock_regen"] = skill.disable_stock_regen
    end
    for k, v in pairs(diff_check_table) do
        if skill[k] ~= default_skill:get(v) then
            result[k] = skill[k]
        end
    end]]
    if skill.ctm_sprite ~= nil then
        result.ctm_sprite = skill.ctm_sprite
    end
    if skill.ctm_arr_modifiers ~= nil then
        result.ctm_arr_modifiers = Utils.create_table_from_array(skill.ctm_arr_modifiers)
    end
    return result
end
Utils.find_skill_with_localized = function(name, player)
    local skills = Array.wrap(player.skills)
    for i = 0, skills:size() - 1 do
        local skill = skills:get(i).active_skill
        if (name == Language.translate_token(Class.SKILL:get(skill.skill_id):get(2))) then
            return skill
        end
    end
end
Utils.get_net_type = function()
    return net_type or Net.get_type()
end
Utils.sync_instance_send = function(inst, table_num, sync_table)
    log.error("sync_instance_send hasn't been initialized")
end
Utils.log_information = function(info, offset)
    if offset == nil then
        offset = 0
    end
    local prefix = ""
    for i = 1, offset do
        prefix = "      " .. prefix
    end
    log.info(prefix, info)
    if type(info) == "table" then
        for k, v in pairs(info) do
            log.info(prefix, k)
            Utils.log_information(v, offset + 1)
        end
    end
    if gm.is_struct(info) then
        local names = gm.struct_get_names(info)
        if #names ~= 0 then
            for j, name in ipairs(names) do
                Utils.log_information(name .. " = ", offset + 1)
                Utils.log_information(gm.variable_struct_get(info, name), offset + 1)
            end
        end
    end
    if gm.is_array(info) then
        local size = gm.array_length(info)
        for i = 0, size - 1 do
            local val = gm.array_get(info, i)
            Utils.log_information("[" .. i .. "]", offset + 1)
            Utils.log_information(val, offset + 1)
        end
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
    if #result > 1 then
        result = string.sub(result, 1, -2)
    end
    result = result .. "}"
    return result
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
Utils.set_and_sync_inst_from_table = function(inst, table)
    for mem, val in pairs(table) do
        inst[mem] = val
    end
    if Utils.get_net_type() ~= Net.TYPE.single then
        Utils.sync_instance_send(inst, Utils.table_get_length(table), table)
    end
end
Utils.parse_string_to_value = function(str)
    local ok, value = tobool(str)
    if ok then
        return value
    end
    return tonumber(str) or str
end
local handy_skill_list = {
    [39] = 0,
    [43] = 1,
    [44] = 2,
    [45] = 3
}
-- 44 is like some unused skill
Utils.get_handy_drone_type = function(skill_id)
    return handy_skill_list[skill_id]
end
Utils.table_get_length = function(table)
    local result = 0
    for k, v in pairs(table) do
        result = result + 1
    end
    return result
end
Utils.packet_type = {
    not_forward = 0,
    forward = 1
}
Utils.param_type = {
    Instance = 0,
    number = 1,
    array = 2,
    table = 3,
    int = 4,
    half = 5,
    string = 6
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
local function init()
    local skill_t = {
        [6] = 0,
        [7] = 1,
        [8] = 2,
        [9] = 3
    }
    for sur_index = 0, #Class.Survivor - 1 do
        local survivor = Class.Survivor:get(sur_index)
        for skill_family_index, skill_slot in pairs(skill_t) do
            local skill_family = survivor:get(skill_family_index).elements
            for skill_index = 0, #skill_family - 1 do
                local skill = gm.array_get(skill_family, skill_index)
                skill_id_to_slot[skill.skill_id] = skill_slot
            end
        end
    end
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
        if Utils.get_net_type() == Net.TYPE.host then
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
        if not gm.instance_exists(inst.id) then
            log.error("instance doesn't exist")
        end
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
        if Utils.get_net_type() == Net.TYPE.host then
            sync_message:send_to_all()
        else
            sync_message:send_to_host()
        end
    end
end
-- basically copy from Alarm
local alarms = {}
Utils.add_alarm = function(func, time, ...)
    local future_frame = gm.variable_global_get("_current_frame") + time
    if not alarms[future_frame] then
        alarms[future_frame] = {}
    end
    local alarms_num = #alarms[future_frame] + 1
    alarms[future_frame][alarms_num] = {
        fn = func,
        args = select(1, ...)
    }
    return function()
        if alarms[future_frame] ~= nil then
            alarms[future_frame][alarms_num] = nil
        end
    end
end
Utils.is_custom_object = function(object_index)
    local is_customobject = gm.variable_global_get("is_customobject")
    return gm.ds_map_find_value(is_customobject, object_index)
end
Utils.clear_alarms = function()
    alarms = {}
end
Initialize(init)
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    net_type = Net.get_type()
    ResourceManager = gm.variable_global_get("ResourceManager_object")
    alarms = {}
end)
gm.post_script_hook(gm.constants.__input_system_tick, function()
    local current_frame = gm.variable_global_get("_current_frame")
    if not alarms[current_frame] then
        return
    end
    for i = 1, #alarms[current_frame] do
        local status, err = pcall(alarms[current_frame][i].fn, alarms[current_frame][i].args)
        if not status then
            log.error("Alarm error from " .. alarms[current_frame][i] .. "\n" .. err)
        end
    end
    alarms[current_frame] = nil
end)
return Utils
