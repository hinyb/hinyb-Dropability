-- this hook will affect the performance.
--[[
-- ev_create 0
-- ev_destroy 1
-- ev_alarm 2
-- ev_step 3
-- ev_step 4 -- I think it is for others, seems like it is collision
-- ev_keyboard 5
-- ev_mouse 6
-- ev_other or ev_async 7
-- ev_draw 8
-- ev_key_press 9
-- ev_key_release 10
-- ev_pre_create 14
-- ev_cleanup 12

-- can get from
https://github.com/nkrapivin/modshovel/blob/master/LibModShovel/LibModShovel_GMConstants.cpp

maybe use 
https://github.com/nkrapivin/modshovel/blob/14f6c791d295d11146cb79cc2844206c9640e419/LibModShovel/LibModShovel_Lua.cpp#L2090
is better
]] --
local cache_event_type
local pre_callbacks = {}
local post_callbacks = {}
-- object_index controls which object's events are executed.
memory.dynamic_hook("event_perform_internal", "int64_t", {"CInstance*", "CInstance*", "int", "int", "int"},
    Dynamic.Perform_Event_Object_ptr, function(ret_val, self, other, object_index, event_type, event_number)
        local event_type = event_type:get()
        cache_event_type = event_type
        local need_to_interrupt = false
        for i = 1, #pre_callbacks do
            need_to_interrupt = need_to_interrupt or
                                    pre_callbacks[i].fn(ret_val, self, other, object_index, event_type, event_number) ==
                                    false
        end
        return not need_to_interrupt
    end, function(ret_val, self, other, object_index, event_type, event_number)
        for i = 1, #post_callbacks do
            post_callbacks[i].fn(ret_val, self, other, object_index, cache_event_type, event_number)
        end
    end)
HookSystem.register_special_hook("pre_Perform_Event_Object", pre_callbacks)
HookSystem.register_special_hook("post_Perform_Event_Object", post_callbacks)
