Initialize(function()
    local create_money = function(x, y, amount)
        local money = gm.instance_create(x, y, gm.constants.oMoneyPickup)
        Utils.set_and_sync_inst_from_table(money, {
            value = amount
        })
    end
    local create_money_packet = Packet.new()
    create_money_packet:onReceived(function(message, player)
        local x = message:read_double()
        local y = message:read_double()
        local amount = message:read_double()
        create_money(x, y, amount)
    end)
    local create_money_send = function(x, y, amount)
        local sync_message = create_money_packet:message_begin()
        sync_message:write_double(x)
        sync_message:write_double(y)
        sync_message:write_double(amount)
        sync_message:send_to_host()
    end

    local oMoneyPickup = Object.new("hinyb", "oMoneyPickup", Object.PARENT.interactable)
    gm.constants.oMoneyPickup = oMoneyPickup.value
    oMoneyPickup.obj_sprite = 114
    oMoneyPickup.obj_depth = 5.0
    local on_money_pickup = Utils.create_sync_func([[
        if gm.bool(a2.is_local) then
            local ohud = gm._mod_game_getHUD()
            gm.call(ohud.add_gold.script_name, ohud, ohud, a1.value)
        end
        gm.instance_destroy(a1)
    ]], {Utils.param_type.instance, Utils.param_type.instance})
    drop_gold = Utils.create_sync_func([[
        if gm.bool(a1.is_local) then
            local ohud = gm._mod_game_getHUD()
            if ohud.gold >= a2 then
                gm.call(ohud.add_gold.script_name, ohud, ohud, -a2)
                local x, y = Utils.get_actual_position(a1)
                if not Net.is_client() then
                    create_money(x, y, a2)
                else
                    create_money_send(x, y, a2)
                end
            end
        end
    ]], {Utils.param_type.instance, Utils.param_type.double}, {
        create_money = create_money,
        create_money_send = create_money_send
    })
    HookSystem.pre_script_hook(gm.constants.interactable_set_active, function(self, other, result, args)
        local inst = args[1].value
        if inst.__object_index == oMoneyPickup.value then
            local actor = args[2].value
            on_money_pickup(inst, actor)
            return false
        end
    end)
end)
