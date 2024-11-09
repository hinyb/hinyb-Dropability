local lang_map = {}
local skill_blacklist = {
    [0] = true,
    [204] = true
} -- 204 umbraMissile
local skill_name_to_slot = {
    banditUnload = 1,
    huntressStealth = 3,
    huntressStealthBoosted = 3,
    sniperBlast = 3,
    sniperBlastBoosted = 3
} -- Need to find a better way.
local net_type
math.randomseed(os.time())
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    lang_map = gm.variable_global_get("_language_map")
    net_type = Net.get_type()
end)
Utils = {}
Utils.get_lang_map = function()
    return lang_map
end
Utils.find_skill_id_with_name = function(name)
    for i = 0,Class.SKILL:size() -1 do
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
Utils.get_random = function (min,max)
    return math.random(min,max)
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
    if skill_name_to_slot[name] then
        return skill_name_to_slot[name]
    end
    log.warning("Can't get the skill's slot_index " .. name .. " " .. Utils.find_skill_id_with_name(name))
end
Utils.warp_skill = function(skill_id, slot_index)
    local skill = Class.SKILL:get(skill_id)
    if skill == nil or type(skill) == "number" then
        log.error("Can't get warp skill with given skill_id" .. tostring(skill))
    end
    return {
        skill_id = skill_id,
        slot_index = slot_index or Utils.get_slot_index_with_name(skill:get(1)) or 0.0,
        sprite_index = skill:get(4),
        image_index = skill:get(5),
        translation_key = string.sub(skill:get(2), 1, -6)
    }
end
Utils.find_item_with_localized = function(name, player)
    local inventory = Array.wrap(gm.variable_instance_get(player.id, "inventory_item_order"))
    for i = 0, inventory:size()-1 do
        local val = inventory:get(i)
        local item = Class.ITEM:get(val)
        if (name == gm.ds_map_find_value(lang_map, item:get(2))) then
            return item:get(8), val
        end
    end
end
Utils.find_skill_with_localized = function(name, player)
    local skills = Array.wrap(gm.variable_instance_get(player.id, "skills"))
    for i = 0, skills:size() - 1 do
        local v = skills:get(i).active_skill
        if (name == gm.ds_map_find_value(lang_map, Class.SKILL:get(v.skill_id):get(2))) then
            return Utils.warp_skill(v.skill_id, v.slot_index)
        end
    end
end
Utils.get_net_type = function()
    return net_type or Net.get_type()
end
Utils.sync_instance_send = function(inst, sync_table)
    log.error("sync_instance_send hasn't been initialized")
end
local function tobool(str)
    if str == "true" then
        return true
    elseif str == "false" then
        return false
    end
end
local function init()
    local sync_instance_packet = Packet.new()
    sync_instance_packet:onReceived(function(message, player)
        local inst = message:read_instance().value
        local num = message:read_int()
        if Utils.get_net_type() == Net.TYPE.host then
            local sync_message = sync_instance_packet:message_begin()
            sync_message:write_instance(inst)
            sync_message:write_int(num)
            for _ = 1, num do
                local mem = message:read_string()
                if mem == nil then
                    break
                end
                local val = message:read_string()
                inst[mem] = tonumber(val) or tobool(val) or val
                sync_message:write_string(mem)
                sync_message:write_string(val)
            end
            sync_message:send_exclude(player)
        else
            for _ = 1, num do
                local mem = message:read_string()
                if mem == nil then
                    break
                end
                local val = message:read_string()
                val = tonumber(val) or tobool(val) or val
                inst[mem] = val
            end
        end
    end)
    Utils.sync_instance_send = function(inst, sync_table, table_num)
        local sync_message = sync_instance_packet:message_begin()
        if not gm.instance_exists(inst.id) then
            log.error("instance doesn't exist")
        end
        sync_message:write_instance(inst)
        sync_message:write_int(table_num)
        for k, v in pairs(sync_table) do
            sync_message:write_string(tostring(k))
            sync_message:write_string(tostring(v))
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
