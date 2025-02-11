local callbacks = InstanceExtManager.callbacks
InstanceExtManager.enable_callback("post_local_drop")
SkillPickup.add_post_local_drop_func(function(inst, skill)
    local id = inst.id
    local actor_callbacks = callbacks[id]
    if not actor_callbacks then
        return
    end
    local callbacks = actor_callbacks.post_local_drop
    if not callbacks then
        return
    end
    for _, callback in pairs(callbacks) do
        callback(inst, skill)
    end
end)
InstanceExtManager.enable_callback("post_pickup")
SkillPickup.add_post_pickup_func(function(inst, skill)
    local id = inst.id
    local actor_callbacks = callbacks[id]
    if not actor_callbacks then
        return
    end
    local callbacks = actor_callbacks.post_pickup
    if not callbacks then
        return
    end
    for _, callback in pairs(callbacks) do
        callback(inst, skill)
    end
end)
