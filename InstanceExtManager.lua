InstanceExtManager = {}
local callbacks = {}
local enable_callbacks = {}
InstanceExtManager.callbacks = callbacks
function InstanceExtManager.add_callback(instance, callback, name, fn)
    if not enable_callbacks[callback] then
        log.error("Can't add non-existed callback", 2)
    end
    local id = type(instance) == "number" and instance or instance.id
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
    if callbacks[name] then
        log.warning("Try to override callback:", callback, name)
    end
    callbacks[name] = fn
end
function InstanceExtManager.enable_callback(callback)
    enable_callbacks[callback] = true
end
function InstanceExtManager.remove_callback(instance, callback, name)
    local id = type(instance) == "number" and instance or instance.id
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
    local id = type(instance) == "number" and instance or instance.id
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
HookSystem.clean_hook()
HookSystem.post_script_hook(gm.constants.run_destroy, function(self, other, result, args)
    callbacks = {}
end)