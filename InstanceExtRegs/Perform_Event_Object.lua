HookSystem.clean_hook()
--[[
-- ev_create 0
-- ev_destroy 1
-- ev_alarm 2
-- ev_step 3
-- ev_step 4 -- I think it is for others
-- ev_keyboard 5
-- ev_mouse 6
-- ev_other or ev_async 7
-- ev_draw 8
-- ev_key_press 9
-- ev_key_release 10
-- ev_pre_create 14

-- ev_cleanup 12
]] --

-- Maybe it should rename to event
--- pre part ---
local callbacks = InstanceExtManager.callbacks
local pre_event_type_map = {
    [3] = "pre_step",
    [8] = "pre_draw",
    [1] = "pre_destroy",
    [4] = "pre_collision"
}
for _, name in pairs(pre_event_type_map) do
    InstanceExtManager.enable_callback(name)
end
HookSystem.add_special_hook("pre_Perform_Event_Object",
    function(ret_val, self, other, object_index, event_type, event_number)
        local callback_name = pre_event_type_map[event_type]

        if not callback_name then
            return
        end

        local instance_callbacks = callbacks[self.id]
        if not instance_callbacks then
            return
        end

        local callbacks_ = instance_callbacks[callback_name]
        if not callbacks_ then
            return
        end
        local need_to_interrupt = false
        -- to delete elements during iteration, I have to do this.
        local key, func = next(callbacks_)
        while key do
            local current_key = key
            local flags = func(self, event_number, other)
            key, func = next(callbacks_, current_key)
            if flags then
                if flags & 1 ~= 0 then
                    callbacks_[current_key] = nil
                end
                need_to_interrupt = need_to_interrupt or flags & 2 ~= 0
                if flags & 4 ~= 0 then
                    return not need_to_interrupt
                end
            end
        end
        return not need_to_interrupt
    end)

-- post part ---
local post_event_type_map = {
    [3] = "post_step",
    [8] = "post_draw",
    [4] = "post_collision"
}
for _, name in pairs(post_event_type_map) do
    InstanceExtManager.enable_callback(name)
end
HookSystem.add_special_hook("post_Perform_Event_Object",
    function(ret_val, self, other, object_index, event_type, event_number)
        -- destroy instance callbacks ---
        local callback_name = post_event_type_map[event_type]

        if not callback_name then
            return
        end

        local instance_callbacks = callbacks[self.id]
        if not instance_callbacks then
            return
        end

        local callbacks_ = instance_callbacks[callback_name]
        if not callbacks_ then
            return
        end
        local key, func = next(callbacks_)
        while key do
            local current_key = key
            local flags = func(self, event_number, other)
            key, func = next(callbacks_, current_key)
            if flags then
                if flags & 1 ~= 0 then
                    callbacks_[current_key] = nil
                end
                if flags & 4 ~= 0 then
                    return
                end
            end
        end
    end)
