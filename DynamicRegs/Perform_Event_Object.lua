-- I am not sure if this hook will affect the performance.
--[[
-- ev_destroy 1
-- ev_cleanup 12
-- ev_step 3
-- ev_draw 8
]]
local pre_callbacks = {}
local post_callbacks = {}
memory.dynamic_hook("event_perform_internal", "int64_t", {"CInstance*", "RValue*", "int", "int", "int"},
    Dynamic.Perform_Event_Object_ptr, function(ret_val, target, result, object_index, event_type, event_number)
        local need_to_interrupt = false
        for _, funcs in pairs(pre_callbacks) do
            for i = 1, #funcs do
                need_to_interrupt = need_to_interrupt or
                                        funcs[i](ret_val, target, result, object_index, event_type, event_number) ==
                                        false
            end
        end
        return not need_to_interrupt
    end, function(ret_val, target, result, object_index, event_type, event_number)
        for _, funcs in pairs(post_callbacks) do
            for i = 1, #funcs do
                funcs[i](ret_val, target, result, object_index, event_type, event_number)
            end
        end
    end)
HookSystem.register_special_hook("pre_Perform_Event_Object", pre_callbacks)
HookSystem.register_special_hook("post_Perform_Event_Object", post_callbacks)