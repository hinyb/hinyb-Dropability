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
local drop_item, drop_item_handler
local item_tooltip, lang_map, item_cache
local cached_dup_num
local doit = false
local function get_player_with_m_id(m_id)
    local players = Instance.find_all(gm.constants.oP)
    for _, p in ipairs(players) do
        if p.m_id == m_id then
            return p
        end
    end
end

local function initialize(host)
    if host then
        drop_item = function(player, item_id, item_object_id)
            if gm.item_count(player, item_id, 0) >= 1 then
                gm.item_take(player, item_id, 1, 0)
                local item = gm.instance_create_depth(player.x, player.y, 0, item_object_id)
                table.insert(drop_item_id_list, item.id)
            end
        end
        drop_item_handler = function(player_m_id, item_id, item_object_id)
            drop_item(get_player_with_m_id(player_m_id).value, item_id, item_object_id)
        end
        Net.register("drop_item_handler", drop_item_handler)
    else
        drop_item = function(player, item_id, item_object_id)
            Net.send("drop_item_handler", 1, Player.get_host().value.user_name, player.m_id, item_id, item_object_id)
        end
    end
    item_cache = gm.variable_global_get("class_item")
    lang_map = gm.variable_global_get("_language_map")
end

gm.post_script_hook(gm.constants.ui_hover_tooltip, function(self, other, result, args)
    item_tooltip = args[3].value
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
            doit = true
        end
    end
end)
gm.post_script_hook(gm.constants.item_give, function(self, other, result, args)
    if doit then
        cached_dup_num = nil
        doit = false
    end
end)
gm.post_script_hook(gm.constants.run_create, function(self, other, result, args)
    drop_item_id_list = {}
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

gui.add_always_draw_imgui(function()
    if ImGui.IsKeyPressed(params['drop_item_key'], false) then
        local player = Player.get_client()
        if Instance.exists(player) then
            if item_tooltip ~= nil then
                local item_object_id, item_id = find_item_with_localized(item_tooltip, player)
                if item_object_id ~= nil and item_id ~= nil then
                    if drop_item ~= nil then
                        drop_item(player.value, item_id, item_object_id)
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
