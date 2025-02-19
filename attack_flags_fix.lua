--[[
-- init_multiplayer_globals
HookSystem.clean_hook()
Utils.multiplayer_buffer = nil
HookSystem.post_script_hook(gm.constants.init_multiplayer_globals, function (self, other, result, args)
    Utils.multiplayer_buffer = gm.variable_global_get("multiplayer_buffer")
end)
-- but lua use double, so it is useless
Utils.write_uint64_t = function (buffer, number)
    local low = number & 0xFFFFFFFF
    local high = number >> 32
    gm.writeuint_direct(buffer, low)
    gm.writeuint_direct(buffer, high)
end
]]
-- just simple replace the uint_packed to double
local write_attackinfo = gm.get_script_function_address(gm.constants.write_attackinfo):add(7742)
write_attackinfo:add(1):patch_byte(0x2D):apply()
write_attackinfo:add(2):patch_byte(0xD8):apply()
write_attackinfo:add(3):patch_byte(0x9C):apply()
local read_attackinfo = gm.get_script_function_address(gm.constants.read_attackinfo):add(4239)
read_attackinfo:add(1):patch_byte(0xFC):apply()
read_attackinfo:add(2):patch_byte(0xBD):apply()
read_attackinfo:add(3):patch_byte(0x9C):apply()