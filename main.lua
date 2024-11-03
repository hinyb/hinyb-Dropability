mods["RoRRModdingToolkit-RoRR_Modding_Toolkit"].auto()

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
local skills_cache

local drifter_scarp_bar_list = {}
local miner_heat_bar_list = {}

local function setupSkill(target, skill_params)
    gm._mod_instance_set_sprite(target, skill_params.skill_sprite)
    target.image_index = skill_params.skill_subimage
    target.translation_key = skill_params.skill_translation_key
    target.skill_id = skill_params.skill_id
    target.slot_index = skill_params.slot_index
    target.text = gm.ds_map_find_value(lang_map, target.translation_key .. ".name")
end
local drop_item_send, drop_skill_send, activate_skill_send
local function init()
    skillPickup = Interactable.new("hinyb", "skillPickup")
    skillPickup.obj_sprite = 114
    skillPickup:add_callback("onActivate", function(Interactable, Player)
        if Interactable.value.skill_id ~= nil and Interactable.value.slot_index ~= nil then
            local skill = gm.variable_instance_get(Player.value.id, "skills")[Interactable.value.slot_index + 1]
                              .active_skill
            if skill.skill_id ~= 0 then
                drop_skill(Player.value, {
                    slot_index = skill.slot_index,
                    skill_id = skill.skill_id,
                    skill_sprite = skill.sprite,
                    skill_translation_key = string.sub(skill.name, 1, -6),
                    skill_subimage = skill.subimage
                })
            end
            activate_skill_send(Player.value, Interactable.value)
        end
    end)

    item_cache = gm.variable_global_get("class_item")
    skills_cache = gm.variable_global_get("class_skill")
    local drop_item_packet = Packet.new()
    drop_item_packet:onReceived(function(message, player)
        local item_id = message:read_int()
        local item_object_id = message:read_int()
        drop_item(player.value, item_id, item_object_id)
    end)
    drop_item_send = function(item_id, item_object_id)
        local sync_message = drop_item_packet:message_begin()
        sync_message:write_int(item_id)
        sync_message:write_int(item_object_id)
        sync_message:send_to_host()
    end
    local drop_skill_packet = Packet.new()
    drop_skill_packet:onReceived(function(message, player)
        local slot_index = message:read_int()
        local skill_id = message:read_int()
        local skill_sprite = message:read_int()
        local skill_translation_key = message:read_string()
        local skill_subimage = message:read_int()
        local skill_params = {
            slot_index = slot_index,
            skill_id = skill_id,
            skill_sprite = skill_sprite,
            skill_translation_key = skill_translation_key,
            skill_subimage = skill_subimage
        }
        if Net.get_type() == Net.TYPE.host then
            drop_skill(player.value, skill_params)
        else
            local skill = message:read_instance().value
            setupSkill(skill, skill_params)
        end
    end)
    drop_skill_send = function(skill_params, skill)
        local sync_message = drop_skill_packet:message_begin()
        sync_message:write_int(skill_params.slot_index)
        sync_message:write_int(skill_params.skill_id)
        sync_message:write_int(skill_params.skill_sprite)
        sync_message:write_string(skill_params.skill_translation_key)
        sync_message:write_int(skill_params.skill_subimage)
        if skill ~= nil then
            sync_message:write_instance(skill)
            sync_message:send_to_all()
        else
            sync_message:send_to_host()
        end
    end
    local active_skill_packet = Packet.new()
    active_skill_packet:onReceived(function(message, player)
        local Player = message:read_instance().value
        local Interactable = message:read_instance().value
        if Net.get_type() == Net.TYPE.host then
            local sync_message = active_skill_packet:message_begin()
            sync_message:write_instance(Player)
            sync_message:write_instance(Interactable)
            sync_message:send_exclude(player)
        end
        gm.actor_skill_set(Player, Interactable.slot_index, Interactable.skill_id)
        gm.instance_destroy(Interactable.id)
    end)
    activate_skill_send = function(Player, Interactable)
        local sync_message = active_skill_packet:message_begin()
        sync_message:write_instance(Player)
        sync_message:write_instance(Interactable)
        if Net.get_type() == Net.TYPE.host then
            sync_message:send_to_all()
        else
            sync_message:send_to_host()
        end
        gm.actor_skill_set(Player, Interactable.slot_index, Interactable.skill_id)
        gm.instance_destroy(Interactable.id)
    end
end
local function update_multiplayer(host)
    lang_map = gm.variable_global_get("_language_map")
    if host then
        drop_item = function(player, item_id, item_object_id)
            if gm.item_count(player, item_id, 0) >= 1 then
                gm.item_take(player, item_id, 1, 0)
                local item = gm.instance_create_depth(player.x, player.y, 0, item_object_id)
                table.insert(drop_item_id_list, item.id)
            end
        end

        drop_skill = function(player, skill_params)
            local skill = gm.instance_create(player.x - 10, player.y - 20, skillPickup.value)
            gm.call("gml_Script_interactable_sync", skill, skill)
            setupSkill(skill, skill_params)
            gm.actor_skill_set(player, skill_params.slot_index, 0) -- DummySkill
            drop_skill_send(skill_params, skill)
        end
    else
        drop_item = drop_item_send

        drop_skill = function(player, skill_params)
            gm.actor_skill_set(player, skill_params.slot_index, 0)
            drop_skill_send(skill_params)
        end
    end
end
gm.post_script_hook(gm.constants.ui_hover_tooltip, function(self, other, result, args)
    tooltip = args[3].value
end)
gm.post_script_hook(gm.constants.update_multiplayer_globals, function(self, other, result, args)
    update_multiplayer(args[2].value)
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
    drifter_scarp_bar_list = {}
    miner_heat_bar_list = {}
end)
local miner_heat_bar_flag = false
gm.post_script_hook(gm.constants._survivor_miner_find_heat_bar, function(self, other, result, args)
    if not miner_heat_bar_flag then
        if result.value == -4 or result.value == 0 then
            if Instance.exists(self) and self.dead ~= 1 then
                miner_heat_bar_flag = true
                gm.call("gml_Script__survivor_miner_create_heat_bar", self, other)
                result = gm.call("gml_Script__survivor_miner_find_heat_bar", self, other, self.id)
                miner_heat_bar_flag = false
            end
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_miner_create_heat_bar, function(self, other, result, args)
    if self.class ~= 6 then
        miner_heat_bar_list[self.m_id] = true
    end
    miner_heat_bar_flag = true
end)
gm.post_code_execute("gml_Object_oP_Step_2", function(self, other)
    if miner_heat_bar_list[self.m_id] and self.activity_type ~= 4.0 then
        local cache_class = self.class
        self.class = 6.0
        gm.call("gml_Script__survivor_miner_update_sprites", self, self, self.id)
        gm.call(gm.constants_type_sorted["gml_script"][102162], self, self, self.id)
        self.class = cache_class
    end
end)
local drifter_scrap_bar_flag = false
gm.post_script_hook(gm.constants._survivor_drifter_find_scrap_bar, function(self, other, result, args)
    if not drifter_scrap_bar_flag then
        if result.value == -4 or result.value == 0 then
            drifter_scrap_bar_flag = true
            gm.call("gml_Script__survivor_drifter_create_scrap_bar", self, other)
            result = gm.call("gml_Script__survivor_drifter_find_scrap_bar", self, other, self.id)
        end
    end
end)
gm.pre_script_hook(gm.constants._survivor_drifter_create_scrap_bar, function(self, other, result, args)
    if self.class ~= 14 then
        drifter_scarp_bar_list[self.m_id] = true
    end
    drifter_scrap_bar_flag = true
end)
local drifter_flag = false
local cache_drifter = 0
gm.pre_code_execute("gml_Object_oDrifterRec_Collision_oP", function(self, other)
    if drifter_scarp_bar_list[other.m_id] then
        drifter_flag = true
        cache_drifter = other.class
        other.class = 14
    end
end)
gm.post_code_execute("gml_Object_oDrifterRec_Collision_oP", function(self, other)
    if drifter_flag then
        drifter_flag = false
        other.class = cache_drifter
    end
end)
local function defalut_nil(target, member, value)
    if target[member] == nil then
        target[member] = value or false
    end
end
local function nilcreate(target, member, num)
    if target[member .. "_half"] == nil or gm.array_length(target[member .. "_half"]) == 0 then
        target[member .. "_half"] = gm.array_create(num, 0.0)
        gm.array_set(target[member .. "_half"], 0, target[member])
        gm.array_set(target[member .. "_half"], 1, target[member])
    end
end
gm.post_script_hook(gm.constants.init_class, function(self, other, result, args)
    drifter_scrap_bar_flag = false
    miner_heat_bar_flag = false
    defalut_nil(self, "charged")
    defalut_nil(self, "_miner_charged_elder_kill_count")
    defalut_nil(self, "sniper_bonus")
    defalut_nil(self, "dash_timer")
    defalut_nil(self, "ydisp")
    defalut_nil(self, "dive")
    defalut_nil(self, "_hand_sawmerang_kill_count")
    defalut_nil(self, "ydisp")
    defalut_nil(self, "dash_again")
    defalut_nil(self, "above_50_health", true)
    defalut_nil(self, "above_60_health", true)
    self.sprite_walk_last = self.sprite_walk -- I don't know what this is for, but it may cause bug when replacing skills. So i change its value to sprite_walk. 
    nilcreate(self, "sprite_idle", 3)
    nilcreate(self, "sprite_fall", 3)
    nilcreate(self, "sprite_jump_peak", 3)
    nilcreate(self, "sprite_jump", 3)
    nilcreate(self, "sprite_walk", 4)
end)
local function find_item_with_localized(name, player)
    local inventory = gm.variable_instance_get(player.id, "inventory_item_order")
    local size = gm.array_length(inventory)
    for i = 0, size - 1 do
        local val = gm.array_get(inventory, i)
        if (name == gm.ds_map_find_value(lang_map, item_cache[val + 1][3])) then
            return item_cache[val + 1][9], val
        end
    end
end
local function find_skill_with_localized(name, player)
    local skills = gm.variable_instance_get(player.id, "skills")
    for k, v in pairs(skills) do
        if (name == gm.ds_map_find_value(lang_map, skills_cache[v.active_skill.skill_id + 1][3])) then
            return v.active_skill.skill_id, v.active_skill.slot_index, skills_cache[v.active_skill.skill_id + 1][5],
                skills_cache[v.active_skill.skill_id + 1][6],
                string.sub(skills_cache[v.active_skill.skill_id + 1][3], 1, -6)
        end
    end
end
local handy_skill_list = {
    [39] = true,
    [43] = true,
    [44] = true,
    [45] = true
} -- 44 is like some unused skill
local function check_handy(player)
    local skills = gm.variable_instance_get(player.id, "skills")
    for i = 1, #skills do
        if handy_skill_list[skills[i].active_skill.skill_id] then
            return true
        end
    end
    return false
end
local ptr = memory.scan_pattern("8B 15 ? ? ? ? 48 8B 8D ? ? ? ? E8 ? ? ? ? BA 06 00 00 00 48 8B C8 E8 ? ? ? ? 84 C0 0F 84 ? ? ? ? C7 44 24 ? ? ? ? ? 8B 4C 24"):add(272)
gm.pre_script_hook(gm.constants.actor_death, function(self, other, result, args)
    if self.object_index == gm.constants.oP then
        if check_handy(self) then
            ptr:add(1):patch_byte(self.class):apply()
        else
            ptr:add(1):patch_byte(4):apply() -- terrible solution, need to find a better way
        end
    end
end)
gui.add_always_draw_imgui(function()
    if ImGui.IsKeyPressed(params['drop_item_key'], false) then
        local player = Player.get_client().value
        if Instance.exists(player) then
            if gm.variable_global_get("_ui_hover_tooltip_state") ~= nil then
                if tooltip ~= nil then
                    local item_object_id, item_id = find_item_with_localized(tooltip, player)
                    if item_object_id ~= nil and item_id ~= nil then
                        if drop_item ~= nil then
                            drop_item(player, item_id, item_object_id)
                        end
                    else
                        local skill_id, slot_index, skill_sprite, skill_subimage, skill_translation_key =
                            find_skill_with_localized(tooltip, player)
                        if skill_id ~= nil and slot_index ~= nil and skill_id ~= 0 then
                            if drop_skill ~= nil then
                                drop_skill(player, {
                                    slot_index = slot_index,
                                    skill_id = skill_id,
                                    skill_sprite = skill_sprite,
                                    skill_translation_key = skill_translation_key,
                                    skill_subimage = skill_subimage
                                })
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

Initialize(init)
