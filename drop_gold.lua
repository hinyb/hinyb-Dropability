Initialize.add_hotloadable(function()
    local error = Sound.new("error",
        path.combine(_ENV["!plugins_mod_folder_path"], "audio", "error.ogg")).value
    local on_value_sync = Utils.create_sync_func([[
        a1.value = a2
        a1.text = tostring(a2) .. " $"
    ]], {Utils.param_type.instance, Utils.param_type.double})
    local create_money = function(x, y, amount)
        local money = gm.instance_create(x, y, gm.constants.oMoneyPickup)
        money:interactable_sync()
        on_value_sync(money, amount)
    end
    local create_money_packet = Packet.new("create_money_packet")
    create_money_packet:set_serializers(function (buffer, x, y, amount)
        buffer:write_double(x)
        buffer:write_double(y)
        buffer:write_double(amount)
    end, function (buffer, player)
        local x = buffer:read_double()
        local y = buffer:read_double()
        local amount = buffer:read_double()
        create_money(x, y, amount)
    end)
    local create_money_send = function(x, y, amount)
        create_money_packet:send_to_host(x, y, amount)
    end
    local money_sprite = Sprite.new("money",
        path.combine(_ENV["!plugins_mod_folder_path"], "sprites", "money.png"), 1, 12, 12)
    local oMoneyPickup = Object.new("oMoneyPickup", Object.Parent.INTERACTABLE)
    gm.constants.oMoneyPickup = oMoneyPickup.value
    oMoneyPickup:set_sprite(money_sprite)
    oMoneyPickup:set_depth(-5)
    local on_money_pickup = Utils.create_sync_func([[
        if gm.bool(a2.is_local) then
            local ohud = gm._mod_game_getHUD()
            ohud.gold = ohud.gold + a1.value
        end
        gm.instance_destroy(a1)
    ]], {Utils.param_type.instance, Utils.param_type.instance})
    local drop_gold_internal = Utils.create_sync_func([[
        if gm.bool(a1.is_local) then
            local ohud = gm._mod_game_getHUD()
            local gold = ohud.gold
            if gold >= a2 then
                ohud.gold = gold - a2
                local x, y = Utils.get_actual_position(a1)
                if not Net.client then
                    create_money(x, y, a2)
                else
                    create_money_send(x, y, a2)
                end
            else
                a1:sound_play(error, 1, 1)
            end
        end
    ]], {Utils.param_type.instance, Utils.param_type.double}, {
        create_money = create_money,
        create_money_send = create_money_send,
        error = error
    })
    drop_gold = function(player, amount)
        if amount ~= 0 then
            drop_gold_internal(player, amount)
        end
    end
    HookSystem.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        local inst = args[1].value
        if inst.__object_index == oMoneyPickup.value then
            local actor = args[2].value
            on_money_pickup(inst, actor)
            return false
        end
    end)
end)
local amount = 24
gui.add_imgui(function()
    if ImGui.Begin("Dropability", ImGuiWindowFlags.AlwaysAutoResize) then
        ImGui.TextColored(1, 0.5, 1, 1, "Drop Gold")
        amount = ImGui.InputInt("amount", amount, 0, 0)
        ImGui.SameLine()
        if ImGui.Button("Drop") then
            local player = Player.get_local().value
            if Instance.exists(player) then
                drop_gold(player, amount)
            end
        end
    end
    ImGui.End()
end)