-- I am not sure if this hook will affect the performance.
--[[
-- ev_destroy 1
-- ev_cleanup 12
-- ev_step 3
-- ev_draw 8
-- ev_create 0
-- ev_other 7
-- ev_alarm 2
]] --
local pre_callbacks = {}
local post_callbacks = {}
-- object_index controls which object's events are executed.
memory.dynamic_hook("event_perform_internal", "int64_t", {"CInstance*", "RValue*", "int", "int", "int"},
    Dynamic.Perform_Event_Object_ptr, function(ret_val, target, result, object_index, event_type, event_number)
        local need_to_interrupt = false
        for i = 1, #pre_callbacks do
            need_to_interrupt = need_to_interrupt or
                                    pre_callbacks[i].fn(ret_val, target, result, object_index, event_type, event_number) ==
                                    false
        end
        return not need_to_interrupt
    end, function(ret_val, target, result, object_index, event_type, event_number)
        for i = 1, #post_callbacks do
            post_callbacks[i].fn(ret_val, target, result, object_index, event_type, event_number)
        end
    end)
HookSystem.register_special_hook("pre_Perform_Event_Object", pre_callbacks)
HookSystem.register_special_hook("post_Perform_Event_Object", post_callbacks)
