--[[
{ name = 'attack_info' },
{ name = 'hit_list' },
{ name = 'max_index' },
{ name = 'is_attack_authority' },
{ name = 'handle_only_local_collisions', value = [=[false]=] },
]]--
HookSystem.clean_hook()
InstanceExtManager.enable_callback("pre_be_damager_attack_process")
local callbacks = InstanceExtManager.callbacks
-- args may be empty, but I think it shouldn't appear.
-- So I decided not to handle it.
HookSystem.pre_script_hook(gm.constants.damager_attack_process, function(self, other, result, args)
    local hit_list = args[2].value
    local max_index = args[3].value
    local need_to_interrupt = false
    for i = 0, max_index - 1, 3 do
        local hit_target = gm.ds_list_find_value(hit_list, i)
        if type(hit_target) ~= "number" then
            local id = hit_target.id
            local inst_callbacks = callbacks[id]
            if inst_callbacks then
                local pre_be_damager_attack_process_callbacks = inst_callbacks.pre_be_damager_attack_process
                if pre_be_damager_attack_process_callbacks then
                    for _, callback in pairs(pre_be_damager_attack_process_callbacks) do
                        --- actor ---
                        local flag, result_ = callback(hit_target, args[1].value, hit_list, max_index, args[4].value, args[5].value)
                        need_to_interrupt = need_to_interrupt or flag == false
                        if result_ then
                            result.value = result_
                        end
                    end
                end
            end
        end
    end
    return not need_to_interrupt
end)
