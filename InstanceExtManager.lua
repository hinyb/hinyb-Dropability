InstanceExtManager = {}
local callbacks = {}
local enable_callbacks = {}
InstanceExtManager.callbacks = callbacks
function InstanceExtManager.add_callback(instance, callback, name, fn)
    if not enable_callbacks[callback] then
        log.error("Can't add non-existed callback", 2)
    end
    local id = lua_type(instance) == "number" and instance or instance.id
    local instance_callbacks = callbacks[id]
    if not instance_callbacks then
        instance_callbacks = {}
        callbacks[id] = instance_callbacks
    end
    local callbacks = instance_callbacks[callback]
    if not callbacks then
        callbacks = {}
        instance_callbacks[callback] = callbacks
    end
    -- if callbacks[name] then
    --     log.warning("Try to override callback:", callback, name)
    -- end
    callbacks[name] = fn
end
function InstanceExtManager.enable_callback(callback)
    if enable_callbacks[callback] then
        log.error("Trying to enable an already enabled callback", 2)
    else
        enable_callbacks[callback] = true
        return true
    end
end
function InstanceExtManager.remove_callback(instance, callback, name)
    local id = lua_type(instance) == "number" and instance or instance.id
    local instance_callbacks = callbacks[id]
    if not instance_callbacks then
        return
    end
    local callbacks = instance_callbacks[callback]
    if not callbacks then
        return
    end
    if not callbacks[name] then
        log.warning("Try to remove a non-existent callback")
    end
    callbacks[name] = nil
end
function InstanceExtManager.callback_exists(instance, callback, name)
    local id = lua_type(instance) == "number" and instance or instance.id
    local instance_callbacks = callbacks[id]
    if not instance_callbacks then
        return false
    end
    local callbacks = instance_callbacks[callback]
    if not callbacks then
        return false
    end
    return callbacks[name] ~= nil
end
