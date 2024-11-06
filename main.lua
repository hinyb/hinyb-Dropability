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

require("Utils")
require("skillPickup")
require("drop_item")
require("compat_patch")

mods["MGReturns-ENVY"].auto()
envy = mods["MGReturns-ENVY"]
public_things = {
    ["drop_item"] = function(player, item_id, item_object_id)
        return drop_item(player, item_id, item_object_id)
    end,
    ["Utils"] = Utils,
    ["skill_create"] = function(x, y, skill_params)
        return skill_create(x, y, skill_params)
    end
} -- Maybe using a wrong way
require("./envy_setup")

local tooltip

gm.post_script_hook(gm.constants.ui_hover_tooltip, function(self, other, result, args)
    tooltip = args[3].value
end)

gui.add_always_draw_imgui(function()
    if ImGui.IsKeyPressed(params['drop_item_key'], false) then
        local player = Player.get_client().value
        if Instance.exists(player) then
            if gm.variable_global_get("_ui_hover_tooltip_state") ~= nil then
                if tooltip ~= nil then
                    local item_object_id, item_id = Utils.find_item_with_localized(tooltip, player)
                    if item_object_id ~= nil and item_id ~= nil then
                        if drop_item ~= nil then
                            drop_item(player, item_id, item_object_id)
                        end
                    else
                        local skill = Utils.find_skill_with_localized(tooltip, player)
                        if skill.skill_id ~= nil and skill.slot_index ~= nil and skill.skill_id ~= 0 then
                            if skill_create ~= nil then
                                gm.actor_skill_set(player, skill.slot_index, 0)
                                skill_create(player.x, player.y, skill)
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
