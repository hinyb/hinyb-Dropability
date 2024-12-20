--[[
GameStyleManager = {}
local new_styles = {}
function GameStyleManager.add(name)
    -- byte_1421CCA44
    gm.get_script_function_address(gm.constants.LobbyGameStyle).new(5404150340):set_byte(0)
    table.insert(new_styles, name)
    log.info("add",name, #new_styles)
end
memory.dynamic_hook_mid("gml_Script_LobbyGameStyle", {"rax"}, {"RValue*"}, 0,
    gm.get_script_function_address(gm.constants.LobbyGameStyle):add(440), function(args)
        log.info("new create", #new_styles)
        Utils.log_information(new_styles)
        for k,v in pairs(new_styles) do
            gm.array_push(args[1].value, v)
        end
        Utils.log_information(args[1],0)
    end)
gm.post_script_hook(gm.constants.LobbyGameStyle, function(self, other, result, args)
    local inst = memory.resolve_pointer_to_type(memory.get_usertype_pointer(self), "YYObjectBase*")
    for i = 1, #new_styles do
        inst[new_styles[i] ] = true
        log.info(new_styles[i])
        inst.test = true
    end
    inst.new_items = 1.0
    inst.new_stages = 1.0
    Utils.log_information(inst)
end)
]]