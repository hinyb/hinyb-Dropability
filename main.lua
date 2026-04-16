mods["ReturnsAPI-ReturnsAPI"].auto({mp = true})
mods["LuaENVY-ENVY"].auto()
envy = mods["LuaENVY-ENVY"]

mods.on_all_mods_loaded(function()
    for k, v in pairs(mods) do
        if lua_type(v) == "table" and v.tomlfuncs then
            Toml = v
        end
    end
    params = {
        drop_key = 522
    }
    params = Toml.config_update(_ENV["!guid"], params)
end)

require("Dynamic")
require("HookSystem")
require("InstanceExtManager")
require("Utils")
require("SkillPickup")
require("drop_item")
require("drop_gold")
require("CompatibilityPatch")
require("Callback_ext")
require("Callable_call")

local names = path.get_files(_ENV["!plugins_mod_folder_path"] .. "/InstanceExtRegs")
for _, name in ipairs(names) do
    require(name)
end

public_things = {
    ["drop_item"] = function(player, item_id, item_object_id)
        return drop_item(player, item_id, item_object_id)
    end,
    ["drop_gold"] = function(player, item_id, item_object_id)
        return drop_gold(player, item_id, item_object_id)
    end,
    ["Utils"] = Utils,
    ["SkillPickup"] = SkillPickup,
    ["Dynamic"] = Dynamic,
    ["Callback_ext"] = Callback_ext,
    ["Callable_call"] = Callable_call,
    ["CompatibilityPatch"] = CompatibilityPatch,
    ["HookFlags"] = HookFlags,
    ["HookSystem"] = HookSystem,
    ["InstanceExtManager"] = InstanceExtManager

} -- Maybe using a wrong way
require("./envy_setup")

local tooltip

HookSystem.clean_hook()
HookSystem.post_script_hook(gm.constants.ui_hover_tooltip, function(self, other, result, args)
    tooltip = args[3].value
end)

HookSystem.post_script_hook(gm.constants.hud_draw_skill_info, function(self, other, result, args)
    if not ImGui.IsKeyPressed(params['drop_key'], false) then
        return
    end
    local player = args[1].value
    local slot_index = args[2].value
    local skill = player:actor_get_skill_active(slot_index)
    if skill.skill_id ~= 0 then
        SkillPickup.drop_skill(player, skill)
    end

end)
-- gml_Object_oHUDTabMenu_Draw_73 can get item_id directly, but draw_items can't
-- So I decided to retain this code.
gui.add_always_draw_imgui(function()
    if not ImGui.IsKeyPressed(params['drop_key'], false) then
        return
    end
    local player = Player.get_local().value
    if not Instance.exists(player) then
        return
    end
    if gm.variable_global_get("_ui_hover_tooltip_state") == nil then
        return
    end
    if tooltip == nil then
        return
    end
    local item_object_id, item_id = Utils.find_item_with_localized(tooltip, player)
    if item_object_id ~= nil and item_id ~= nil then
        drop_item(player, item_id, item_object_id)
    end
end)
gui.add_to_menu_bar(function()
    local isChanged, keybind_value = ImGui.Hotkey("Drop Key", params['drop_key'])
    if isChanged then
        params['drop_key'] = keybind_value
        Toml.save_cfg(_ENV["!guid"], params)
    end
end)