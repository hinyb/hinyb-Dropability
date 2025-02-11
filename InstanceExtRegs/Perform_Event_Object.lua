HookSystem.clean_hook()
--[[
-- ev_destroy 1
-- ev_cleanup 12
-- ev_step 3
-- ev_draw 8
]]

--- pre part ---
local callbacks = InstanceExtManager.callbacks
local pre_event_type_map = {
    [3] = "pre_step",
    [8] = "pre_draw",
    [1] = "pre_destroy"
}
for _, name in pairs(pre_event_type_map) do
    InstanceExtManager.enable_callback(name)
end
HookSystem.add_special_hook("pre_Perform_Event_Object", function (ret_val, target, result, object_index, event_type, event_number)
    local event_type = event_type:get()
    local callback_name = pre_event_type_map[event_type]

    if not callback_name then
        return
    end

    local instance_callbacks = callbacks[target.id]
    if not instance_callbacks then
        return
    end

    local callbacks_ = instance_callbacks[callback_name]
    if not callbacks_ then
        return
    end
    local need_to_interrupt = false
    for _, fn in pairs(callbacks_) do
        need_to_interrupt = need_to_interrupt or fn(target) == false
    end
    return not need_to_interrupt
end)

-- post part ---
local post_event_type_map = {
    [3] = "post_step",
    [8] = "post_draw"
}
for _, name in pairs(post_event_type_map) do
    InstanceExtManager.enable_callback(name)
end
HookSystem.add_special_hook("post_Perform_Event_Object", function (ret_val, target, result, object_index, event_type, event_number)
    local event_type = event_type:get()

    -- destroy instance callbacks ---
    if event_type == 1 then
        callbacks[target.id] = nil
        return
    end

    local callback_name = post_event_type_map[event_type]

    if not callback_name then
        return
    end

    local instance_callbacks = callbacks[target.id]
    if not instance_callbacks then
        return
    end

    local callbacks_ = instance_callbacks[callback_name]
    if not callbacks_ then
        return
    end
    for _, fn in pairs(callbacks_) do
        fn(target)
    end
end)