local lang_map = {}
local item_cache = {}
local skills_cache = {}
local skill_blacklist = {
    [0] = true,
    [204] = true
} -- 204 umbraMissile
local net_type
math.randomseed(os.time())
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    lang_map = gm.variable_global_get("_language_map")
    item_cache = gm.variable_global_get("class_item")
    skills_cache = gm.variable_global_get("class_skill")
    net_type = Net.get_type()
end)
Utils = {}
Utils.get_lang_map = function()
    return lang_map
end
Utils.get_item_cache = function()
    return item_cache
end
Utils.get_skills_cache = function()
    return skills_cache
end
Utils.find_skill_id_with_name = function(name)
    for i = 1, #skills_cache do
        if type(skills_cache[i]) ~= "number" and skills_cache[i][2] == name then
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
            local rnd_skill_id = random(1, #skills_cache) - 1
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
    log.warning("Can't get the skill's slot_index " .. name .. " " .. Utils.find_skill_id_with_name(name))
end
Utils.warp_skill = function(skill_id, slot_index)
    local skill = skills_cache[skill_id + 1]
    if skill == nil or type(skill) == "number" then
        log.error("Can't get warp skill with given skill_id" .. tostring(skill))
    end
    return {
        skill_id = skill_id,
        slot_index = slot_index or Utils.get_slot_index_with_name(skill[2]) or 0.0,
        sprite_index = skill[5],
        image_index = skill[6],
        translation_key = string.sub(skill[3], 1, -6)
    }
end
Utils.find_item_with_localized = function(name, player)
    local inventory = gm.variable_instance_get(player.id, "inventory_item_order")
    local size = gm.array_length(inventory)
    for i = 0, size - 1 do
        local val = gm.array_get(inventory, i)
        if (name == gm.ds_map_find_value(lang_map, item_cache[val + 1][3])) then
            return item_cache[val + 1][9], val
        end
    end
end
Utils.find_skill_with_localized = function(name, player)
    local skills = gm.variable_instance_get(player.id, "skills")
    for i = 1, #skills do
        local v = skills[i]
        if (name == gm.ds_map_find_value(lang_map, skills_cache[v.active_skill.skill_id + 1][3])) then
            return Utils.warp_skill(v.active_skill.skill_id, v.active_skill.slot_index)
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
