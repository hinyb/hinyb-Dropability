Initialize(function()
    Utils.miner_heat_add_sync = Utils.create_sync_func([[
        gm.call("gml_Script__survivor_miner_heat_add", a1, a1, a1, a2)
    ]], {Utils.param_type.instance, Utils.param_type.double})
    Utils.set_and_sync_inst_from_table = Utils.create_sync_func([[
        for k,v in pairs(a2) do
            a1[k] = v
        end
    ]], {Utils.param_type.instance, Utils.param_type.table})
    --- I think it only should use by oCustomObject.
    Utils.instance_create_sync = Utils.create_sync_func([[
        return gm.instance_create(a1,a2,a3)
    ]], {Utils.param_type.double, Utils.param_type.double, Utils.param_type.ushort})
end)
