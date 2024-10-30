mods.on_all_mods_loaded(function()
    for _, m in pairs(mods) do
        if type(m) == "table" and m.RoRR_Modding_Toolkit then
            for _, c in ipairs(m.Classes) do
                if m[c] then
                    _G[c] = m[c]
                end
            end
        end
    end
end)

mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        drop_item_key = 522
    }
    params = Toml.config_update(_ENV["!guid"], params)
end)

local drop_item_id_list = {}
local drop_item
local tooltip, lang_map, item_cache
local cached_dup_num
local pickup_is_dropped = false

local drop_skill
local activate_skill
local skills_cache
local bugged_skills = {} -- Thanks for https://github.com/SmoothSpatula/SmoothSpatula-RoRRRandomizer
local function skill_check(skill_id)
    for _, v in pairs(bugged_skills) do
        if skill_id == v then
            return false
        end
    end
    return true
end
local function get_instance_with_m_id(id, m_id)
    for k, v in pairs(Instance.find_all(id)) do
        if v.value.m_id == m_id then
            return v
        end
    end
end
local need_to_update = {}
local function setupSkill(target, params)
    gm._mod_instance_set_sprite(target, params.skill_sprite)
    target.image_index = params.skill_subimage
    target.translation_key = params.skill_translation_key
    target.skill_id = params.skill_id
    target.slot_index = params.slot_index
    target.text = gm.ds_map_find_value(lang_map, target.translation_key .. ".name")
end
local function setupUpdateSkill(slot_index, skill_params)
    need_to_update.slot_index = slot_index
    need_to_update.skill_id = skill_params[1]
    need_to_update.skill_sprite = skill_params[2]
    need_to_update.skill_translation_key = skill_params[3]
    need_to_update.skill_subimage = skill_params[4]
end
local function initialize(host)
    local activate_skill_handler = function(player_m_id, inst_object_index, inst_m_id)
        local Player = get_instance_with_m_id(gm.constants.oP, player_m_id)
        local Interactable = get_instance_with_m_id(inst_object_index, inst_m_id)
        gm.actor_skill_set(Player.value, Interactable.value.slot_index, Interactable.value.skill_id)
        gm.instance_destroy(Interactable.value.id)
    end
    Net.register("activate_skill_handler", activate_skill_handler)
    activate_skill = function(player, skillPickup)
        gm.actor_skill_set(player.value, skillPickup.value.slot_index, skillPickup.value.skill_id)
        gm.instance_destroy(skillPickup.value.id)
        Net.send("activate_skill_handler", Net.TARGET.all, nil, player.m_id, skillPickup.object_index, skillPickup.m_id)
    end
    item_cache = gm.variable_global_get("class_item")
    lang_map = gm.variable_global_get("_language_map")
    skills_cache = gm.variable_global_get("class_skill")
    if host then
        drop_item = function(player, item_id, item_object_id)
            if gm.item_count(player, item_id, 0) >= 1 then
                gm.item_take(player, item_id, 1, 0)
                local item = gm.instance_create_depth(player.x, player.y, 0, item_object_id)
                table.insert(drop_item_id_list, item.id)
            end
        end
        local drop_item_handler = function(player_m_id, item_id, item_object_id)
            drop_item(get_instance_with_m_id(gm.constants.oP, player_m_id).value, item_id, item_object_id)
        end
        Net.register("drop_item_handler", drop_item_handler)

        drop_skill = function(player, slot_index, skill_params)
            Net.send("drop_skill_client_handler", Net.TARGET.all, nil, slot_index, table.unpack(skill_params))
            setupUpdateSkill(slot_index, skill_params)
            gm.instance_create(player.x - 10, player.y - 20, skillPickup.value)
            gm.actor_skill_set(player, slot_index, 0) -- DummySkill
        end
        local drop_skill_host_handler = function(player_m_id, slot_index, skill_params)
            drop_skill(get_instance_with_m_id(gm.constants.oP, player_m_id).value, slot_index, skill_params)
        end
        Net.register("drop_skill_host_handler", drop_skill_host_handler)
    else
        drop_item = function(player, item_id, item_object_id)
            Net.send("drop_item_handler", 1, Player.get_host().value.user_name, player.m_id, item_id, item_object_id)
        end

        drop_skill = function(player, slot_index, skill_params)
            gm.actor_skill_set(player, slot_index, 0)
            Net.send("drop_skill_host_handler", 1, Player.get_host().value.user_name, player.m_id, slot_index,
                skill_params)
        end
        local drop_skill_client_handler = function(slot_index, ...)
            setupUpdateSkill(slot_index, {...})
        end
        Net.register("drop_skill_client_handler", drop_skill_client_handler)
    end
end

gm.post_script_hook(gm.constants.ui_hover_tooltip, function(self, other, result, args)
    tooltip = args[3].value
end)
gm.post_script_hook(gm.constants.update_multiplayer_globals, function(self, other, result, args)
    initialize(args[2].value)
end)
gm.pre_script_hook(gm.constants.item_give_internal, function(self, other, result, args)
    if (cached_dup_num ~= nil) then
        gm.array_set(other.inventory_item_stack, 95, cached_dup_num)
    end
end)
gm.pre_script_hook(gm.constants.item_give, function(self, other, result, args)
    for index, item_id in pairs(drop_item_id_list) do
        if (item_id == self.id) then
            cached_dup_num = gm.array_get(other.inventory_item_stack, 95)
            gm.array_set(other.inventory_item_stack, 95, 0)
            table.remove(drop_item_id_list, index)
            pickup_is_dropped = true
        end
    end
end)
gm.post_script_hook(gm.constants.item_give, function(self, other, result, args)
    if pickup_is_dropped then
        cached_dup_num = nil
        pickup_is_dropped = false
    end
end)
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drop_item_id_list = {}
end)
gm.post_script_hook(gm.constants.instance_create, function(self, other, result, args)
    if result.value.__object_index == skillPickup.value then
        if need_to_update.slot_index ~= nil then
            setupSkill(result.value, need_to_update)
            need_to_update = {}
        end
    end
end)
local miner_heat_bar_flag = false
gm.post_script_hook(gm.constants._survivor_miner_find_heat_bar, function(self, other, result, args)
    if not miner_heat_bar_flag then
        if result.value == -4 or result.value == 0 then
            miner_heat_bar_flag = true
            gm.call("gml_Script__survivor_miner_create_heat_bar", self, other)
            result = gm.call("gml_Script__survivor_miner_find_heat_bar", self, other, self)
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_miner_create_heat_bar, function(self, other, result, args)
    miner_heat_bar_flag = true
end)
local drifter_scrap_bar_flag = false
gm.post_script_hook(gm.constants._survivor_drifter_find_scrap_bar, function(self, other, result, args)
    if not drifter_scrap_bar_flag then
        if result.value == -4 or result.value == 0 then
            drifter_scrap_bar_flag = true
            gm.call("gml_Script__survivor_drifter_create_scrap_bar", self, other)
            result = gm.call("gml_Script__survivor_drifter_find_scrap_bar", self, other, self)
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    drifter_scrap_bar_flag = true
end)
local function set_default_value(target, member, value)
    if target[member] == nil then
        target[member] = false or value
    end
end
local function set_default_value_sprite(target, member, num)
    if target[member .. "_half"] == nil or gm.array_length(target[member .. "_half"]) == 0 then
        target[member .. "_half"] = gm.array_create(num, 0.0)
        gm.array_set(target[member .. "_half"], 0, target[member])
        gm.array_set(target[member .. "_half"], 1, target[member])
    end
end
gm.post_script_hook(gm.constants.init_class, function(self, other, result, args)
    drifter_scrap_bar_flag = false
    miner_heat_bar_flag = false
    set_default_value(self, "charged")
    set_default_value(self, "_miner_charged_elder_kill_count")
    set_default_value(self, "sniper_bonus")
    set_default_value(self, "dash_timer")
    set_default_value(self, "ydisp")
    set_default_value(self, "above_50_health", true)

    self.sprite_walk_last = self.sprite_walk -- I don't know what this is for, but it may cause bug when replacing skills. So i change its value to sprite_walk. 
    set_default_value_sprite(self, "sprite_idle", 3)
    set_default_value_sprite(self, "sprite_fall", 3)
    set_default_value_sprite(self, "sprite_jump_peak", 3)
    set_default_value_sprite(self, "sprite_jump", 3)
    set_default_value_sprite(self, "sprite_walk", 4)
end)
local function find_item_with_localized(name, player)
    local inventory = gm.variable_instance_get(player.value.id, "inventory_item_order")
    local size = gm.array_length(inventory)
    for i = 0, size - 1 do
        local val = gm.array_get(inventory, i)
        if (name == gm.ds_map_find_value(lang_map, item_cache[val + 1][3])) then
            return item_cache[val + 1][9], val
        end
    end
end
function __initialize()
    skillPickup = Interactable.new("hinyb", "skillPickup")
    skillPickup.obj_sprite = 114
    skillPickup:add_callback("onActivate", function(Interactable, Player)
        if Interactable.value.skill_id ~= nil and Interactable.value.slot_index ~= nil then
            local skill = gm.variable_instance_get(Player.value.id, "skills")[Interactable.value.slot_index + 1]
                              .active_skill
            if skill.skill_id ~= 0 then
                if not skill_check(skill.skill_id) then
                    return
                end
                drop_skill(Player.value, skill.slot_index,
                    {skill.skill_id, skill.sprite, string.sub(skill.name, 1, -6), skill.subimage})
            end
            activate_skill(Player, Interactable)
        else
            log.error("Can't get skillPickup's skill_id or slot_index") -- sometimes happened. maybe is my terrible network code.
        end
    end)
end
local function find_skill_with_localized(name, player)
    local skills = gm.variable_instance_get(player.value.id, "skills")
    for k, v in pairs(skills) do
        if (name == gm.ds_map_find_value(lang_map, skills_cache[v.active_skill.skill_id + 1][3])) then
            return v.active_skill.skill_id, v.active_skill.slot_index, skills_cache[v.active_skill.skill_id + 1][5],
                skills_cache[v.active_skill.skill_id + 1][6],
                string.sub(skills_cache[v.active_skill.skill_id + 1][3], 1, -6)
        end
    end
end
gui.add_always_draw_imgui(function()
    if ImGui.IsKeyPressed(params['drop_item_key'], false) then
        local player = Player.get_client()
        if Instance.exists(player) then
            if gm.variable_global_get("_ui_hover_tooltip_state") ~= nil then
                if tooltip ~= nil then
                    local item_object_id, item_id = find_item_with_localized(tooltip, player)
                    if item_object_id ~= nil and item_id ~= nil then
                        if drop_item ~= nil then
                            drop_item(player.value, item_id, item_object_id)
                        end
                    else
                        local skill_id, slot_index, skill_sprite, skill_subimage, skill_translation_key =
                            find_skill_with_localized(tooltip, player)
                        if skill_id ~= nil and slot_index ~= nil and skill_id ~= 0 and skill_check(skill_id) then
                            if drop_skill ~= nil then
                                drop_skill(player.value, slot_index,
                                    {skill_id, skill_sprite, skill_translation_key, skill_subimage})
                            end
                        end
                    end
                end
            end
        end
    end
end)

gui.add_to_menu_bar(function()
    local isChanged, keybind_value = ImGui.Hotkey("Drop Item Key", params['drop_item_key'])
    if isChanged then
        params['drop_item_key'] = keybind_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)
