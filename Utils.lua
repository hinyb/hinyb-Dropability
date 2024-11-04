local lang_map = {}
local item_cache = {}
local skills_cache = {}
local function update_multiplayer(host)
    lang_map = gm.variable_global_get("_language_map")
    item_cache = gm.variable_global_get("class_item")
    skills_cache = gm.variable_global_get("class_skill")
end
gm.post_script_hook(gm.constants.update_multiplayer_globals, function(self, other, result, args)
    update_multiplayer(args[2].value)
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
    for i = 1,#skills do
        local v = skills[i]
        if (name == gm.ds_map_find_value(lang_map, skills_cache[v.active_skill.skill_id + 1][3])) then
            return {
                skill_id = v.active_skill.skill_id,
                slot_index = v.active_skill.slot_index,
                skill_sprite = skills_cache[v.active_skill.skill_id + 1][5],
                skill_subimage = skills_cache[v.active_skill.skill_id + 1][6],
                skill_translation_key = string.sub(skills_cache[v.active_skill.skill_id + 1][3], 1, -6)
            }
        end
    end
end
return Utils
