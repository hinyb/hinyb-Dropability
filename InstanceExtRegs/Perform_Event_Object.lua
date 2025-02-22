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
HookSystem.add_special_hook("pre_Perform_Event_Object", function (ret_val, self, other, object_index, event_type, event_number)
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
    for _, fn in pairs(callbacks_) do
        local flag = fn(self, event_number, other)
        if flag == -1 then
            return
        end
        need_to_interrupt = need_to_interrupt or flag == false
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
HookSystem.add_special_hook("post_Perform_Event_Object", function (ret_val, self, other, object_index, event_type, event_number)
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
    for _, fn in pairs(callbacks_) do
        if fn(self, event_number, other) == -1 then
            return
        end
    end
end)