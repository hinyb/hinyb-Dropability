InstanceExtManager = {}
InstanceExtManager.callback_types = {}
local resolve_pre_script_callbacks = function(result, callbacks, ...)
    local flag = false
    for _, callback in pairs(callbacks) do
        local flag_, result_ = callback(...)
        flag = flag or flag_ == false
        if result_ then
            result.value = result_
        end
    end
    return not flag
end
local resolve_post_script_callbacks = function(result, callbacks, ...)
    for _, callback in pairs(callbacks) do
        local result_ = callback(...)
        if result_ then
            result.value = result_
        end
    end
end
local pre_script_callbacks = {}
local post_script_callbacks = {}
local script_callbacks_table = {}
function InstanceExtManager.register_script_callback(script_index, callback_name, deal_func)
    local script_callbacks = script_callbacks_table[script_index]
    if not script_callbacks then
        script_callbacks = {}
        script_callbacks_table[script_index] = script_callbacks
        gm.pre_script_hook(script_index, function(self, other, result, args)
            for callback_name, deal_func in pairs(script_callbacks) do
                local id, params_table = deal_func(self, other, result, args)
                local actor_callbacks = pre_script_callbacks[id]
                local actor_script_callbacks = actor_callbacks and actor_callbacks[script_index]
                if actor_script_callbacks then
                    return resolve_pre_script_callbacks(result, actor_script_callbacks[callback_name], params_table)
                end
            end
        end)
        gm.post_script_hook(script_index, function(self, other, result, args)
            for callback_name, deal_func in pairs(script_callbacks) do
                local id, params_table = deal_func(self, other, result, args)
                local actor_callbacks = post_script_callbacks[id]
                local actor_script_callbacks = actor_callbacks and actor_callbacks[script_index]
                if actor_script_callbacks then
                    resolve_post_script_callbacks(result, actor_script_callbacks[callback_name], params_table)
                end
            end
        end)
    end
    script_callbacks[callback_name] = deal_func
end
local resolve_pre_code_callbacks = function(callbacks, ...)
    local flag = false
    for _, callback in pairs(callbacks) do
        local flag_ = callback(...)
        flag = flag or flag_ == false
    end
    return not flag
end
local resolve_post_code_callbacks = function(callbacks, ...)
    for _, callback in pairs(callbacks) do
        callback(...)
    end
end
local pre_code_callbacks = {}
local post_code_callbacks = {}
local code_callbacks_table = {}
function InstanceExtManager.register_code_callback(code_name, callback_name, deal_func)
    local code_callbacks = code_callbacks_table[code_name]
    if not code_callbacks then
        code_callbacks = {}
        code_callbacks_table[code_name] = code_callbacks
        gm.pre_code_execute(code_name, function(self, other)
            for callback_name, deal_func in pairs(code_callbacks) do
                local id, params_table = deal_func(self, other)
                local actor_callbacks = pre_code_callbacks[id]
                local actor_code_callbacks = actor_callbacks and actor_callbacks[code_name]
                if actor_code_callbacks then
                    return resolve_pre_code_callbacks(actor_code_callbacks[callback_name], params_table)
                end
            end
        end)
        gm.post_code_execute(code_name, function(self, other)
            for callback_name, deal_func in pairs(code_callbacks) do
                local id, params_table = deal_func(self, other)
                local actor_callbacks = post_code_callbacks[id]
                local actor_code_callbacks = actor_callbacks and actor_callbacks[code_name]
                if actor_code_callbacks then
                    resolve_post_code_callbacks(actor_code_callbacks[callback_name], params_table)
                end
            end
        end)
    end
    code_callbacks[callback_name] = deal_func
end
local function add_callback_internal(check_callbacks, callbacks, instance, callback_id, callback_name, name, fn)
    if not check_callbacks[callback_id] and not check_callbacks[callback_id][callback_name] then
        log.error("Can't add Instance_ext callback", 2)
    end
    local id = instance.id
    if callbacks[id] == nil then
        callbacks[id] = {}
    end
    if callbacks[id][callback_id] == nil then
        callbacks[id][callback_id] = {}
    end
    if callbacks[id][callback_id][callback_name] == nil then
        callbacks[id][callback_id][callback_name] = {}
    end
    if callbacks[id][callback_id][callback_name][name] then
        log.warning("try to override", callback_id, callback_name, name)
    end
    callbacks[id][callback_id][callback_name][name] = fn
end
local function remove_callback_internal(callbacks, instance, callback_id, callback_name, name)
    local id = instance.id
    if callbacks[id] and callbacks[id][callback_id] and callbacks[id][callback_id][callback_name] and
        callbacks[id][callback_id][callback_name][name] then
        callbacks[id][callback_id][callback_name][name] = nil
    end
end
function InstanceExtManager.add_pre_script_callback(instance, callback_id, callback_name, name, fn)
    add_callback_internal(script_callbacks_table, pre_script_callbacks, instance, callback_id, callback_name, name, fn)
end
function InstanceExtManager.add_post_script_callback(instance, callback_id, callback_name, name, fn)
    add_callback_internal(script_callbacks_table, post_script_callbacks, instance, callback_id, callback_name, name, fn)
end
function InstanceExtManager.remove_pre_script_callback(instance, callback_id, callback_name, name)
    remove_callback_internal(pre_script_callbacks, instance, callback_id, callback_name, name)
end
function InstanceExtManager.remove_post_script_callback(instance, callback_id, callback_name, name)
    remove_callback_internal(post_script_callbacks, instance, callback_id, callback_name, name)
end
function InstanceExtManager.add_pre_code_callback(instance, callback_id, callback_name, name, fn)
    add_callback_internal(code_callbacks_table, pre_code_callbacks, instance, callback_id, callback_name, name, fn)
end
function InstanceExtManager.add_post_code_callback(instance, callback_id, callback_name, name, fn)
    add_callback_internal(code_callbacks_table, post_code_callbacks, instance, callback_id, callback_name, name, fn)
end
function InstanceExtManager.remove_pre_code_callback(instance, callback_id, callback_name, name)
    remove_callback_internal(pre_code_callbacks, instance, callback_id, callback_name, name)
end
function InstanceExtManager.remove_post_code_callback(instance, callback_id, callback_name, name)
    remove_callback_internal(post_code_callbacks, instance, callback_id, callback_name, name)
end
