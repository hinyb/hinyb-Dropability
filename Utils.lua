local lang_map = gm.variable_global_get("_language_map")
local skill_blacklist = {
    [0] = true,
    [204] = true
} -- 204 umbraMissile
local skill_id_to_slot = {}
local net_type
local ResourceManager = gm.variable_global_get("ResourceManager_object")
math.randomseed(os.time())
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    lang_map = gm.variable_global_get("_language_map")
    net_type = Net.get_type()
    ResourceManager = gm.variable_global_get("ResourceManager_object")
end)
Utils = {}
Utils.check_asset_with_name = function(namespace, identifier)
    local lookup = ResourceManager.__namespacedAssetLookup
    if gm.variable_instance_exists(lookup, namespace) and gm.variable_instance_exists(lookup[namespace], identifier) then
        return lookup[namespace][identifier]
    else
        return false
    end
end
Utils.get_lang_map = function()
    return lang_map
end
Utils.find_skill_id_with_name = function(name)
    for i = 0, Class.SKILL:size() - 1 do
        local skill = Class.SKILL:get(i)
        if type(skill) ~= "number" and skill:get(1) == name then
            return i
        end
    end
end
Utils.check_skill = function(skill_id)
    return not skill_blacklist[skill_id]
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
Utils.random_skill_id = function(random_seed)
    local random = Utils.LCG_random(random_seed)
    return function()
        while true do
            local rnd_skill_id = random(1, Class.SKILL:size()) - 1
            if Utils.check_skill(rnd_skill_id) then
                return rnd_skill_id
            end
        end
    end
end
Utils.get_random = function(min, max)
    return math.random(min, max)
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
Utils.warp_skill = function(skill_id, slot_index, sprite_index, image_index, translation_key)
    local skill = Class.SKILL:get(skill_id)
    if skill == nil or type(skill) == "number" then
        log.error("Can't get warp skill with given skill_id" .. tostring(skill))
    end
    return {
        skill_id = skill_id,
        slot_index = slot_index or Utils.get_slot_index_with_skill_id(skill_id) or 0.0,
        sprite_index = sprite_index or skill:get(4),
        image_index = image_index or skill:get(5),
        translation_key = translation_key or string.sub(skill:get(2), 1, -6)
    }
end
Utils.find_item_with_localized = function(name, player)
    local inventory = Array.wrap(player.inventory_item_order)
    for i = 0, inventory:size() - 1 do
        local val = inventory:get(i)
        local item = Class.ITEM:get(val)
        if (name == gm.ds_map_find_value(lang_map, item:get(2))) then
            return item:get(8), val
        end
    end
end
Utils.get_skill_diff_check_table = function ()
    return{
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
    local default_skill = Class.SKILL:get(skill.skill_id)
    local diff_check_table = Utils.get_skill_diff_check_table()
    local result = {}
    result.skill_id = skill.skill_id
    result.slot_index = skill.slot_index
    if skill.disable_stock_regen ~= not default_skill:get(10) then
        result["disable_stock_regen"] = skill.disable_stock_regen
    end
    for k, v in pairs(diff_check_table) do
        if skill[k] ~= default_skill:get(v) then
            log.info("diff ",k,skill[k])
            result[k] = skill[k]
        end
    end
    if skill.ctm_sprite ~= nil then
        result.ctm_sprite = skill.ctm_sprite
    end
    if skill.ctm_arr_activate ~= nil then
        result.ctm_arr_activate = Utils.create_table_from_array(skill.ctm_arr_activate)
    end
    return result
end
Utils.find_skill_with_localized = function(name, player)
    local skills = Array.wrap(player.skills)
    for i = 0, skills:size() - 1 do
        local skill = skills:get(i).active_skill
        if (name == gm.ds_map_find_value(lang_map, Class.SKILL:get(skill.skill_id):get(2))) then
            return Utils.get_active_skill_diff(skill)
        end
    end
end
Utils.get_net_type = function()
    return net_type or Net.get_type()
end
Utils.sync_instance_send = function(inst, table_num, sync_table)
    log.error("sync_instance_send hasn't been initialized")
end
Utils.simple_table_to_string = function(table)
    if type(table) ~= "table" then
        log.error("param must be table")
        return "{}"
    end
    local result = "{"
    for k, v in pairs(table) do
        if type(v) == "table" then
            result = result .. Utils.simple_table_to_string(v)
        else
            result = result .. tostring(v) .. ","
        end
    end
    if #result > 1 then
        result = string.sub(result, 1, -2)
    end
    result = result .. "}"
    return result
end
Utils.simple_string_to_table = function(string)
    if type(table) ~= "string" then
        log.error("param must be string")
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
    for i = 0, gm.array_length(arr) do
        table.insert(res, gm.array_get(arr, i))
    end
    return res
end
Utils.set_and_sync_inst_from_table = function(inst, table)
    local change_table = {}
    for mem, val in pairs(table) do
        if type(val) == "table" then
            inst[mem] = Utils.create_array_from_table(val)
            change_table[mem] = val
        else
            inst[mem] = val
        end
    end
    if Utils.get_net_type() == Net.TYPE.host then
        for mem, val in pairs(change_table) do
            table[mem] = nil
            table["arr_" .. mem] = Utils.simple_table_to_string(val)
        end
        Utils.sync_instance_send(inst, #table, table)
        for mem, val in pairs(change_table) do
            table["arr_" .. mem] = nil
            table[mem] = val
        end
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
            local function parse_string_to_value(str)
                local ok, value = tobool(str)
                if ok then
                    return value
                end
                return tonumber(str) or str
            end
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
                    inst[mem] = parse_string_to_value(val)
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
Initialize(init)
return Utils
